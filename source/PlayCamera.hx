package;

import CameraTilemap;

import flixel.FlxG;
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.math.FlxPoint;
import flixel.tile.FlxTilemap;

class PlayCamera extends FlxCamera
{
	
	/**
	 * Too high and it can be disorienting,
	 * too low and the player won't see ahead of their path
	 */
	inline static var CAMERA_LERP = 0.2;
	
	inline static var PAN_DOWN_DELAY = 0.25;
	inline static var PAN_DOWN_END_DELAY = 0.75;
	inline static var PAN_DOWN_DISTANCE = 4;//tiles
	inline static var PAN_DOWN_TIME = 0.5;
	/** Used to pan down the camera smoothly */
	var panDownTimer = 0.0;
	/** Offset for when the player is looking down */
	var camYPanOffset = 0.0;
	
	inline static var PAN_LEAD_SHIFT_TIME = 0.5;
	inline static var PAN_LEAD_TILES = 1;
	/** TODO: The default offset of a given area, should point up normally, and down in areas that lead downwards*/
	var camYLeadOffset = 0.0;
	var camYLeadAmount = 0.0;
	inline static var FALL_LEAD_DELAY = 0.15;
	var camTargetFallTimer = 0.0;
	
	/** Time it takes to snap to the new platforms height */
	inline static var PAN_SNAP_TIME = 0.3;
	/** Used to snap the camera to a new ground height when landing */
	var camYSnapOffset = 0.0;
	var camYSnapTimer = 0.0;
	var camYSnapAmount = 0.0;
	var lastCameraPos = new FlxPoint();
	
	#if debug
	var debugDeadZone:FlxObject;
	#end
	
	public var tileSize = 1.0;
	public var cameraTilemap:CameraTilemap;
	
	var player(get, never):Player;
	inline function get_player():Player return cast target;
	
	public function new (x = 0, y = 0, width = 0, height = 0, zoom = 0):Void
	{
		super(x, y, width, height, zoom);
	}
	
	public function init(player:Player):Void
	{
		follow(player, FlxCameraFollowStyle.PLATFORMER, CAMERA_LERP);
		focusOn(player.getPosition());
		var w = (width / 8);
		var h = (height * 2 / 3);
		deadzone.set((width - w) / 2, (height - h) / 2, w, h);
		camYLeadOffset = camYLeadAmount = tileSize * -PAN_LEAD_TILES;
	}
	
	override function update(elapsed:Float)
	{
		// Deadzone: taller when jumping, but snap to center when on the ground
		if (!player.gettingHurt && player.onGround != player.wasOnGround)
		{
			if (player.onGround)
			{
				deadzone.height = player.height;
				deadzone.y = (height - deadzone.height) / 2 - (tileSize * 1);
			}
			else
			{
				deadzone.height = height * 2 / 3;
				deadzone.y = (height - deadzone.height) / 2 - (tileSize * 2);
			}
			
			// Snap to new ground height
			if (player.onGround)
			{
				// Compute the amount of y dis to move the camera
				targetOffset.y = camYLeadOffset + camYPanOffset;
				var oldCam = FlxPoint.get().copyFrom(scroll);
				snapToTarget();
				camYSnapTimer = 0;
				camYSnapAmount = -(scroll.y - oldCam.y);
				scroll.copyFrom(oldCam);
				oldCam.put();
			}
		}
		
		// actual snapping
		if (camYSnapAmount != 0)
		{
			camYSnapTimer += elapsed;
			if (camYSnapTimer > PAN_SNAP_TIME)
				camYSnapOffset = camYSnapAmount = 0;
			else
				camYSnapOffset = camYSnapAmount * /*FlxEase.smootherStepInOut*/(1.0 - (camYSnapTimer / PAN_SNAP_TIME));
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
				camYPanOffset
					= tileSize * PAN_DOWN_DISTANCE
					* /*FlxEase.smoothStepInOut*/(Math.min(panDownTimer - PAN_DOWN_DELAY, PAN_DOWN_TIME) / PAN_DOWN_TIME);
		}
		
		// Tilemap leading bias, Look up unless it's a downward section of the level (indicated in ogmo)
		var leading = cameraTilemap.getTileTypeAt(player.x, player.y);
		if (leading != Down)
		{
			if (player.velocity.y > 0 && scroll.y > lastCameraPos.y)
			{
				// Lead down when falling for some time
				camTargetFallTimer += elapsed;
				trace(camTargetFallTimer);
				if (camTargetFallTimer > FALL_LEAD_DELAY)
					leading = CameraTileType.Down;
			}
			else
				camTargetFallTimer = 0;
		}
		
		switch (leading)
		{
			case Up  : camYLeadAmount = tileSize * -PAN_LEAD_TILES;
			case Down: camYLeadAmount = tileSize *  PAN_LEAD_TILES;
		}
		
		// linear shift because I'm lazy and this can get weird if player keeps going back and forth
		if (camYLeadOffset != camYLeadAmount)
		{
			var leadSpeed = 2 * PAN_LEAD_TILES * tileSize / PAN_LEAD_SHIFT_TIME * elapsed;
			if (camYLeadOffset < camYLeadAmount)
			{
				camYLeadOffset += leadSpeed;
				if (camYLeadOffset > camYLeadAmount)// bound
					camYLeadOffset = camYLeadAmount;
			}
			else
			{
				camYLeadOffset -= leadSpeed;
				if (camYLeadOffset < camYLeadAmount)// bound
					camYLeadOffset = camYLeadAmount;
			}
		}
		
		// Combine all the camera offsets
		targetOffset.y = camYSnapOffset + camYPanOffset + camYLeadOffset;
		lastCameraPos.copyFrom(scroll);
		
		#if debug
		if (FlxG.keys.justPressed.C)
			FlxG.debugger.drawDebug = !FlxG.debugger.drawDebug;
		
		if (FlxG.debugger.drawDebug)
		{
			if (debugDeadZone == null)
			{
				debugDeadZone = new FlxObject();
				debugDeadZone.scrollFactor.set();
				
				FlxG.state.forEach((child)->
				{
					if (Std.is(child, FlxObject))
						(cast child:FlxObject).ignoreDrawDebug = true;
				}, true);
				
				FlxG.state.add(debugDeadZone);
			}
			
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