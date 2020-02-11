package;

import OgmoTilemap;

import flixel.FlxG;
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.math.FlxPoint;
import flixel.tile.FlxTilemap;
import flixel.tweens.FlxEase;

class PlayCamera extends FlxCamera
{
	
	/**
	 * Too high and it can be disorienting,
	 * too low and the player won't see ahead of their path
	 */
	inline static var LERP = 0.75;
	
	inline static var PAN_DOWN_DELAY = 0.25;
	inline static var PAN_DOWN_END_DELAY = 0.75;
	inline static var PAN_DOWN_DISTANCE = 4;//tiles
	inline static var PAN_DOWN_TIME = 0.5;
	/** Used to pan down the camera smoothly */
	var panDownTimer = 0.0;
	/** Offset for when the player is looking down */
	var panOffset = 0.0;
	
	inline static var PAN_LEAD_SHIFT_TIME = 0.5;
	/** TODO: The default offset of a given area, should point up normally, and down in areas that lead downwards*/
	var leadOffset = 0.0;
	var camYLeadAmount = 0.0;
	inline static var FALL_LEAD_DELAY = 0.25;
	var fallTimer = 0.0;
	
	/** Time it takes to snap to the new platforms height */
	inline static var PAN_SNAP_TIME = 0.3;
	/** Used to snap the camera to a new ground height when landing */
	var snapOffset = 0.0;
	var snapTimer = 0.0;
	var snapAmount = 0.0;
	var snapEase:Null<(Float)->Float> = null;
	var lastPos = new FlxPoint();
	
	#if debug
	var debugDeadZone:FlxObject;
	#end
	
	var tileSize = 1.0;
	var cameraTilemap:CameraTilemap;
	
	var player(get, never):Player;
	inline function get_player():Player return cast target;
	
	public function new (x = 0, y = 0, width = 0, height = 0, zoom = 0):Void
	{
		super(x, y, width, height, zoom);
	}
	
	public function init(player:Player, tileSize:Float, cameraTilemap:CameraTilemap):PlayCamera
	{
		this.tileSize = tileSize;
		this.cameraTilemap = cameraTilemap;
		follow(player, FlxCameraFollowStyle.PLATFORMER, LERP);
		focusOn(player.getPosition());
		var w = (width / 8);
		var h = (height * 2 / 3);
		deadzone.set((width - w) / 2, (height - h) / 2, w, h);
		leadOffset = camYLeadAmount = -tileSize;
		return this;
	}
	
	override function update(elapsed:Float)
	{
		// Deadzone: taller when jumping, but snap to center when on the ground
		if (!player.gettingHurt && player.onGround != player.wasOnGround)
		{
			if (player.onGround)
			{
				deadzone.height = player.height;
				deadzone.y = (height - deadzone.height) / 2 - (tileSize * 1 * zoom);
			}
			else
			{
				deadzone.height = height * 2 / 3 / zoom;
				deadzone.y = (height - deadzone.height) / 2 - (tileSize * 2 * zoom);
			}
			
			// Snap to new ground height
			if (player.onGround)
			{
				// Compute the amount of y dis to move the camera
				targetOffset.y = leadOffset + panOffset;
				var oldCam = FlxPoint.get().copyFrom(scroll);
				snapToTarget();
				snapTimer = 0;
				snapAmount = scroll.y - oldCam.y;
				scroll.copyFrom(oldCam);
				oldCam.put();
				if (snapAmount + scroll.y + height > maxScrollY)
					snapAmount = maxScrollY - (scroll.y + height);
				
				snapEase = null;
				if (fallTimer > FALL_LEAD_DELAY)
					snapEase = FlxEase.smootherStepOut;
			}
		}
		
		// actual snapping
		if (snapAmount != 0)
		{
			snapTimer += elapsed;
			if (snapTimer > PAN_SNAP_TIME)
				snapOffset = snapAmount = 0;
			else if (snapEase == null)
				snapOffset = -snapAmount * (1.0 - (snapTimer / PAN_SNAP_TIME));
			else
				snapOffset = -snapAmount * snapEase(1.0 - (snapTimer / PAN_SNAP_TIME));
		}
		
		// Look down while pressing down
		var downPress = FlxG.keys.anyPressed([S, DOWN]);
		var gamepad = FlxG.gamepads.lastActive;
		if (!downPress && gamepad != null)
			downPress = gamepad.anyPressed([DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN, RIGHT_STICK_DIGITAL_DOWN]);
		
		if (downPress)
		{
			panDownTimer += elapsed;
			if (panDownTimer > PAN_DOWN_DELAY + PAN_DOWN_TIME)
				// stay down after releasing the button for a bit
				panDownTimer = PAN_DOWN_DELAY + PAN_DOWN_TIME + PAN_DOWN_END_DELAY;
		}
		else if (panDownTimer < PAN_DOWN_DELAY)
			panDownTimer = 0;
		else
			panDownTimer -= elapsed;
		
		if (panDownTimer > 0)
		{
			if (panDownTimer > PAN_DOWN_DELAY)
				panOffset
					= tileSize * PAN_DOWN_DISTANCE
					* /*FlxEase.smoothStepInOut*/(Math.min(panDownTimer - PAN_DOWN_DELAY, PAN_DOWN_TIME) / PAN_DOWN_TIME);
		}
		
		// Tilemap leading bias, Look up unless it's a downward section of the level (indicated in ogmo)
		var leading = cameraTilemap.getTileTypeAt(player.x, player.y);
		if (leading != Down && leading != MoreDown)
		{
			if (player.velocity.y > 0 && scroll.y > lastPos.y)
			{
				// Lead down when falling for some time
				fallTimer += elapsed;
				if (fallTimer > FALL_LEAD_DELAY)
					leading = CameraTileType.Down;
			}
			else
				fallTimer = 0;
		}
		
		switch (leading)
		{
			case None    : camYLeadAmount = tileSize * -1;
			case Up      : camYLeadAmount = tileSize * -4;
			case Down    : camYLeadAmount = tileSize *  1;
			case MoreDown: camYLeadAmount = tileSize *  4;
		}
		
		// linear shift because I'm lazy and this can get weird if player keeps going back and forth
		if (leadOffset != camYLeadAmount)
		{
			var leadSpeed = 2 * tileSize / PAN_LEAD_SHIFT_TIME * elapsed;
			if (leadOffset < camYLeadAmount)
			{
				leadOffset += leadSpeed;
				if (leadOffset > camYLeadAmount)// bound
					leadOffset = camYLeadAmount;
			}
			else
			{
				leadOffset -= leadSpeed;
				if (leadOffset < camYLeadAmount)// bound
					leadOffset = camYLeadAmount;
			}
		}
		
		// Combine all the camera offsets
		targetOffset.y = snapOffset + panOffset + leadOffset;
		lastPos.copyFrom(scroll);
		
		#if debug
		if (FlxG.keys.justPressed.C)
		{
			if (debugDeadZone == null)
			{
				FlxG.debugger.drawDebug = true;
				debugDeadZone = new FlxObject();
				debugDeadZone.scrollFactor.set();
				FlxG.state.add(debugDeadZone);
			}
			else
				debugDeadZone.visible = !debugDeadZone.visible;
		}
		
		if (FlxG.debugger.drawDebug && debugDeadZone != null && debugDeadZone.visible)
		{
			debugDeadZone.x = deadzone.x - targetOffset.x;
			debugDeadZone.y = deadzone.y - targetOffset.y;
			debugDeadZone.width = deadzone.width;
			debugDeadZone.height = deadzone.height;
		}
		#end
		
		super.update(elapsed);
	}
	
	static public function replaceCurrentCamera():PlayCamera
	{
		var camera = new PlayCamera();
		camera.copyFrom(FlxG.camera);
		FlxG.cameras.remove(FlxG.camera);
		FlxG.cameras.add(camera);
		FlxG.camera = camera;
		return camera;
	}
}