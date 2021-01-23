package states;

import beat.BeatGame;
import data.Section;
import data.OgmoTilemap;
import data.PlayerSettings;
import props.*;
import props.Cheese;
import props.Lock;
import props.Platform;

import ui.BitmapText;
import ui.Controls;
import ui.DialogueSubstate;
import ui.DeviceManager;
import ui.pause.PauseSubstate;

import io.newgrounds.NG;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.effects.FlxFlicker;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;

import flixel.addons.display.FlxBackdrop;

using zero.utilities.OgmoUtils;
using zero.flixel.utilities.FlxOgmoUtils;

class PlayState extends flixel.FlxState
{
	inline static var USE_NEW_CAMERA = true;
	inline static var FIRST_CHEESE_MSG = "Thanks for the cheese, buddy! ";
	
	var sections = new FlxTypedGroup<Section>();
	var players = new FlxTypedGroup<Player>();
	
	var bg:FlxBackdrop;
	
	var musicName:String;

	var gaveCheese = false;
	var cheeseCountText:BitmapText;
	public var dialogueBubble:FlxSprite;
	var cheeseCount = 0;
	var cheeseNeeded = 0;
	var totalCheese = 0;
	public var curCheckpoint:Checkpoint;
	var cheeseNeededText:LockAmountText;
	
	override public function create():Void
	{
		playMusic("pillow");
		
		bg = new FlxBackdrop("assets/images/bg_loop.png");
		bg.scrollFactor.set(0.75, 0.75);
		bg.alpha = 0.75;
		#if debug bg.ignoreDrawDebug = true; #end
		
		dialogueBubble = new FlxSprite().loadGraphic("assets/images/dialogue.png", true, 32, 32);
		dialogueBubble.animation.add('play', [0, 1, 2, 3], 6);
		dialogueBubble.animation.play('play');
		dialogueBubble.visible = false;
		
		FlxG.worldBounds.set(0, 0, 0, 0);
		FlxG.cameras.remove(FlxG.camera);
		FlxG.camera = null;
		FlxCamera.defaultCameras = [];// Added to in createPlayer
		createInitialLevel();
		
		add(bg);
		add(sections);
		add(players);
		add(dialogueBubble);
		createUI();
		
		var firstAvatar = PlayerSettings.player1.avatar;
		if (curCheckpoint == null)
			curCheckpoint = new Checkpoint(firstAvatar.x, firstAvatar.y, "");
		
		players.add(firstAvatar);
		if (PlayerSettings.numAvatars == 2)
			players.add(PlayerSettings.player2.avatar);
		
		var worldBounds = FlxG.worldBounds;
		players.forEach(function(player)
			{
				player.playCamera.minScrollX = worldBounds.left;
				player.playCamera.maxScrollX = worldBounds.right;
				player.playCamera.minScrollY = worldBounds.top;
				player.playCamera.maxScrollY = worldBounds.bottom;
			}
		);
	}
	
	
	function createInitialLevel()
	{
	}
	
	function createUI()
	{
		var uiGroup = new FlxGroup();
		var bigCheese = new DisplayCheese(10, 10);
		bigCheese.scrollFactor.set();
		#if debug bigCheese.ignoreDrawDebug = true; #end
		uiGroup.add(bigCheese);
		
		cheeseCountText = new BitmapText(40, 12, "");
		cheeseCountText.scrollFactor.set();
		#if debug cheeseCountText.ignoreDrawDebug = true; #end
		uiGroup.add(cheeseCountText);
		uiGroup.camera = FlxG.camera;
		add(uiGroup);
	}
	
	function createSection(path:String, ?pos:FlxPoint):Section
	{
		var section = new Section(path, pos);
		totalCheese += section.grpCheese.length;
		sections.add(section);
		section.extendWorldBounds();
		return section;
	}
	
	@:allow(ui.pause.MainPage)
	@:allow(ui.DeviceManager)
	function createSecondPlayer()
	{
		if (PlayerSettings.player1 == null || PlayerSettings.player1.avatar == null)
			throw "Creating second player before first";
		if (PlayerSettings.player2 != null && PlayerSettings.player2.avatar != null)
			throw "Only 2 players allowed right now";
		
		final firstPlayer = PlayerSettings.player1.avatar;
		firstPlayer.currentSection.createAvatar(firstPlayer.x, firstPlayer.y);
	}
	
	@:allow(ui.pause.MainPage)
	function removeSecondPlayer(avatar:Player)
	{
		avatar.currentSection.grpPlayers.remove(avatar);
		avatar.destroy();
	}
	
	override function update(elapsed)
	{
		super.update(elapsed);
		
		if (DeviceManager.alertPending())
		{
			openSubState(new DeviceManager());
			return;
		}
		
		var pauseSubstate:PauseSubstate = null;
		players.forEach
		(
			player->
			{
				if (pauseSubstate == null && player.controls.PAUSE)
				{
					if (PlayerSettings.numPlayers == 1)
						pauseSubstate = new PauseSubstate(PlayerSettings.player1);
					else
						pauseSubstate = new PauseSubstate(PlayerSettings.player1, PlayerSettings.player2);
				}
				
				if (pauseSubstate == null)
					checkAvatarState(player);
			}
		);
		
		if (pauseSubstate != null)
			openSubState(pauseSubstate);
		
		cheeseCountText.text = cheeseCount + (cheeseNeeded > 0 ? "/" + cheeseNeeded : "");
		
		#if debug updateDebugFeatures(); #end
	}
	
	function checkAvatarState(avatar:Player)
	{
		switch (avatar.state)
		{
			case Alive:
				var oldSection = avatar.currentSection;
				// check exits
				sections.forEach((section)->
					{
						if (!section.overlaps(avatar) && section.hasAvatar(avatar))
						{
							section.avatarExit(avatar);
							if (section == avatar.currentSection)
								avatar.currentSection = null;
						}
					}
				);
				// check entrances
				sections.forEach((section)->
					{
						if (section.overlaps(avatar))
						{
							if (avatar.currentSection == null)
								avatar.currentSection = section;
							
							if (!section.hasAvatar(avatar))
								section.avatarEnter(avatar);
						}
					}
				);
				
				if (avatar.currentSection == null)
				{
					if (oldSection.y > avatar.y + avatar.height)
						avatar.currentSection = oldSection;
					else if (oldSection.y + oldSection.height < avatar.y)
						avatar.state = Dying;
					else
					{
						var edge = avatar.x > oldSection.x + oldSection.width ? "right" : "left";
						throw 'Missing level to the $edge of ${oldSection.path}';
					}
				}
			case Dying:
				avatar.dieAndRespawn(curCheckpoint.x, curCheckpoint.y - 16);
			case Won:
				FlxG.camera.fade(FlxColor.BLACK, 2, false, FlxG.switchState.bind(new EndState()));
			default:
		}
	}
	
	function warpTo(x:Float, y:Float):Void
	{
		players.forEach(player->player.dieAndRespawn(x,y));
	}
	
	public function checkDoor (lock:Lock, player:Player)
	{
		if (cheeseNeededText == null)
		{
			if (cheeseCount >= lock.amountNeeded)
			{
				// Open door
				add(cheeseNeededText = lock.createText());
				cheeseNeededText.showLockAmount(()->
				{
					lock.open();
					cheeseNeededText.kill();
					cheeseNeededText = null;
					if (cheeseNeeded <= lock.amountNeeded)
						cheeseNeeded = 0;
				});
				// FlxG.sound.music.volume = 0;
			}
			else if (cheeseNeeded != lock.amountNeeded)
			{
				// replace current goal with door's goal
				add(cheeseNeededText = lock.createText());
				cheeseNeededText.animateTo
					( cheeseCountText.x + cheeseCountText.width
					, cheeseCountText.y + cheeseCountText.height / 2
					,   ()->
						{
							cheeseNeeded = lock.amountNeeded;
							cheeseNeededText.kill();
							cheeseNeededText = null;
							FlxFlicker.flicker(cheeseCountText, 1, 0.12);
						}
					);
			}
		}
	}
	
	public function handleCheckpoint(checkpoint:Checkpoint, player:Player)
	{
		var autoTalk = checkpoint.autoTalk;
		var dialogue = checkpoint.dialogue;
		if (!gaveCheese && player.cheese.length > 0)
		{
			gaveCheese = true;
			autoTalk = true;
			dialogue = FIRST_CHEESE_MSG + dialogue;
		}
		
		dialogueBubble.visible = true;
		dialogueBubble.setPosition(checkpoint.x + 20, checkpoint.y - 10);
		
		if (player.controls.TALK || autoTalk)
		{
			checkpoint.onTalk();
			player.state = Talking;
			var focalPoint = checkpoint.getGraphicMidpoint(FlxPoint.weak());
			focalPoint.x += checkpoint.cameraOffsetX;
			add(new ZoomDialogueSubstate
				( dialogue
				, focalPoint
				, player.settings
				, ()->player.state = Alive
				)
			);
		}
		
		if (checkpoint != curCheckpoint)
		{
			curCheckpoint.deactivate();
			checkpoint.activate();
			curCheckpoint = checkpoint;
			FlxG.sound.play('assets/sounds/checkpoint' + BootState.soundEXT, 0.8);
		}
		
		if (!player.cheese.isEmpty())
		{
			player.cheese.first().sendToCheckpoint(checkpoint, onFeedCheese);
			player.cheese.clear();
		}
	}
	
	public function onFeedCheese(cheese:Cheese)
	{
		cheeseCount++;
	}
	
	public function playerCollectCheese(player:Player, cheese:Cheese)
	{
		FlxG.sound.play('assets/sounds/collectCheese' + BootState.soundEXT, 0.6);
		cheese.startFollow(player);
		player.cheese.add(cheese);
		// NGio.unlockMedal(58879);
	}
	
	inline function updateDebugFeatures()
	{
		if (FlxG.keys.justPressed.B)
			FlxG.debugger.drawDebug = !FlxG.debugger.drawDebug;
		
		if (FlxG.keys.justPressed.ONE)
			cheeseCount++;
		
		if (FlxG.keys.justPressed.T)
		{
			disableAllDebugDraw();
			players.forEach((player)->player.tail.ignoreDrawDebug = false);
			FlxG.debugger.drawDebug = true;
		}
		
		// if (FlxG.keys.justPressed.SEVEN)
		// 	PlayerSettings.player1.rebindKeys();

		// if (FlxG.keys.justPressed.EIGHT)
		// 	PlayerSettings.player2.rebindKeys();
	}
	
	public function disableAllDebugDraw()
	{
		players.forEach((player)->
		{
			player.ignoreDrawDebug = true;
			player.tail.ignoreDrawDebug = true;
		});
		
		sections.forEach((section)->section.disableAllDebugDraw());
	}
	
	private function playMusic(name:String):Void
	{
		FlxG.sound.playMusic('assets/music/' + name + BootState.soundEXT, 0.7);
		switch (name)
		{
			case "pillow":
				FlxG.sound.music.loopTime = 4450;
				BeatGame.beatsPerMinute = 110;
			case "ritz":
				FlxG.sound.music.loopTime = 0;
				BeatGame.beatsPerMinute = 60;//not needed
		}
		musicName = name;
	}
}