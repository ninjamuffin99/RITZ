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
	
	var bg:FlxBackdrop;
	var sections = new FlxTypedGroup<Section>();
	var avatars = new FlxTypedGroup<Player>();
	
	var cameraMode = CameraMode.SingleSection;
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
		createInitialLevel();
		
		add(bg);
		add(sections);
		add(avatars);
		add(dialogueBubble);
		createUI();
		
		var avatar1 = PlayerSettings.player1.avatar;
		if (curCheckpoint == null)
			curCheckpoint = new Checkpoint(avatar1.x, avatar1.y, "");
		
		avatars.add(avatar1);
		avatar1.currentSection.setFocus(avatar1.camera);
		if (PlayerSettings.numAvatars == 2)
		{
			var avatar2 = PlayerSettings.player2.avatar;
			avatars.add(avatar2);
			if (cameraMode == AllSections)
				avatar2.currentSection.extendRect(FlxG.worldBounds);
			else if (avatar2.currentSection != avatar1.currentSection)
				throw "Players cannot be in separate rooms with CameraMode.SingleSection";
		}
		
		switch (cameraMode)
		{
			case AllSections:
			{
				var bounds:FlxRect = null;
				for (section in sections.members)
				{
					if (section != null)
						bounds = section.extendRect(bounds);
				}
				
				for (player in avatars.members)
				{
					player.playCamera.minScrollX = bounds.left  ;
					player.playCamera.maxScrollX = bounds.right ;
					player.playCamera.minScrollY = bounds.top   ;
					player.playCamera.maxScrollY = bounds.bottom;
				}
			}
			case SingleSection:
			{
				for (section in sections.members)
				{
					if (section != avatar1.currentSection)
						section.exists = false;
				}
				avatar1.currentSection.setFocus(avatar1.playCamera);
			}
		}
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
	
	function createSection(path:String, ?pos:FlxPoint, removeSpawns = false):Section
	{
		var section = new Section(path, pos, removeSpawns);
		totalCheese += section.totalCheese;
		sections.add(section);
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
		
		final avatar1 = PlayerSettings.player1.avatar;
		var avatar2 = avatar1.currentSection.createAvatar(avatar1.x, avatar1.y);
		if (cameraMode == AllSections)
		{
			avatar2.camera.minScrollX = avatar1.camera.minScrollX;
			avatar2.camera.maxScrollX = avatar1.camera.maxScrollX;
			avatar2.camera.minScrollY = avatar1.camera.minScrollY;
			avatar2.camera.maxScrollY = avatar1.camera.maxScrollY;
		}
		avatars.add(avatar2);
	}
	
	@:allow(ui.pause.MainPage)
	function removeSecondPlayer(avatar:Player)
	{
		avatars.remove(avatar);
		if (avatars.members.length > 1)
			avatars.members.pop();//remove null
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
		avatars.forEach
		(
			avatar->
			{
				if (pauseSubstate == null && avatar.controls.PAUSE)
				{
					if (PlayerSettings.numPlayers == 1)
						pauseSubstate = new PauseSubstate(PlayerSettings.player1);
					else
						pauseSubstate = new PauseSubstate(PlayerSettings.player1, PlayerSettings.player2);
				}
				
				if (pauseSubstate == null)
					checkAvatarState(avatar);
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
			case Alive | Respawning:
				updateSections(avatar);
			case Dead:
				avatar.respawn(curCheckpoint.x, curCheckpoint.y - 16);
			case Won:
				FlxG.camera.fade(FlxColor.BLACK, 2, false, FlxG.switchState.bind(new EndState()));
			default:
		}
	}
	
	function updateSections(avatar:Player)
	{
		if (cameraMode == AllSections)
			checkVisibleSections();
		
		var oldSection = avatar.currentSection;
		for (section in sections.iterator(section->!section.overlaps(avatar)))
		{
			if (section == avatar.currentSection)
				avatar.currentSection = null;
			
			if (section.hasAvatar(avatar))
				section.avatarExit(avatar);
		}
		
		for (section in sections.iterator(section->section.overlaps(avatar)))
		{
			// dont check !hasAvatar here becuase it may have already entered
			if (avatar.currentSection == null)
				avatar.currentSection = section;
			
			if (!section.hasAvatar(avatar))
				section.avatarEnter(avatar);
		}
		
		if (avatar.currentSection == null)
		{
			avatar.currentSection = oldSection;
			if (oldSection.bottom < avatar.y)
				avatar.state = Hurt;
			else if (oldSection.y <= avatar.y)
			{
				var edge = avatar.x > oldSection.x + oldSection.width ? "right" : "left";
				throw 'Missing level to the $edge of ${oldSection.path}';
			}
		}
		else if (avatar.currentSection != oldSection)
		{
			if (cameraMode == SingleSection && avatar.state == Alive)
				switchSection(avatar.currentSection, oldSection);
			else if (cameraMode == SingleSection && avatar.state == Respawning)
				switchSection(avatar.currentSection, oldSection, false);
		}
	}
	
	function checkVisibleSections()
	{
		var changeBounds = false;
		for (section in sections.members)
		{
			final onScreen = section.isOnScreen();
			if (section.exists != onScreen)
			{
				section.exists = onScreen;
				changeBounds = true;
			}
		}
		
		if (changeBounds)
		{
			FlxG.worldBounds.set(Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY, Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY);
			for (section in sections.members)
			{
				if (section != null)
					section.extendRect(FlxG.worldBounds);
			}
		}
	}
	
	function switchSection(to:Section, from:Section, animate = true)
	{
		// if (animate)
		// {
		// }
		// else
		{
			var camera = PlayerSettings.player1.camera;
			to.exists = true;
			to.setFocus(camera);
			
			// from can be null when players are added
			if (from != null)
				from.exists = false;
			
		}
	}
	
	function warpToCheckpoint(checkpoint:Checkpoint):Void
	{
		curCheckpoint = checkpoint;
		avatars.forEach(avatar->avatar.die());
	}
	
	function warpToCheckpointAt(x:Float, y:Float):Void
	{
		var p = FlxPoint.get(x, y);
		var toCheckpoint:Checkpoint = null;
		for (section in sections.members)
		{
			if (section.containsPoint(p))
			{
				for (checkpoint in section.grpCheckpoint.members)
				{
					if (checkpoint.overlapsPoint(p))
					{
						toCheckpoint = checkpoint;
						break;
					}
				}
				break;
			}
		}
		p.put();
		
		if (toCheckpoint == null)
			throw "No checkpoint found at x, y";
		
		warpToCheckpoint(toCheckpoint);
	}
	
	public function checkDoor (lock:Lock, avatar:Player)
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
		if (!gaveCheese && player.followCheese.isNotEmpty()) 
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
		
		player.feedAllCheese(checkpoint, onFeedCheese);
	}
	
	public function onFeedCheese(cheese:Cheese)
	{
		cheeseCount++;
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
			avatars.forEach((avatar)->avatar.tail.ignoreDrawDebug = false);
			FlxG.debugger.drawDebug = true;
		}
		
		// if (FlxG.keys.justPressed.SEVEN)
		// 	PlayerSettings.player1.rebindKeys();

		// if (FlxG.keys.justPressed.EIGHT)
		// 	PlayerSettings.player2.rebindKeys();
	}
	
	public function disableAllDebugDraw()
	{
		avatars.forEach((avatar)->
		{
			avatar.ignoreDrawDebug = true;
			avatar.tail.ignoreDrawDebug = true;
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

enum CameraMode
{
	AllSections;
	SingleSection;
}