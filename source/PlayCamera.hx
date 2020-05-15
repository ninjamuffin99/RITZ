package;

import data.OgmoTilemap;
import ui.Inputs;

import flixel.FlxG;
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
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
	
	inline static var AIR_PAN_LEAD_SHIFT_SPEED = 6 / 0.5;//6 tiles in 0.25 seconds
	inline static var GROUND_PAN_LEAD_SHIFT_SPEED = 2 / 0.5;//6 tiles in 0.25 seconds
	/** TODO: The default offset of a given area, should point up normally, and down in areas that lead downwards*/
	var leadOffset = 0.0;
	var camYLeadAmount = 0.0;
	inline static var FALL_LEAD_DELAY = 0.05;
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
	
	var groundRect = new FlxRect();
	var airRect = new FlxRect();
	
	var player(get, never):Player;
	inline function get_player():Player return cast target;
	
	public var leading = CameraTileType.None;
	
	public function new (x = 0, y = 0, width = 0, height = 0, zoom = 0):Void
	{
		super(x, y, width, height, zoom);
		bgColor = FlxG.stage.color;
	}
	
	public function init(player:Player, tileSize:Float):PlayCamera
	{
		var w = (width / 8);
		var h = (height * 2 / 3);
		groundRect.x = (width - w) / 2;
		groundRect.width = w;
		groundRect.height = player.height;
		groundRect.y = (height - groundRect.height) / 2 - (tileSize * 1 * zoom);
		airRect.copyFrom(groundRect);
		airRect.y -= Player.MAX_JUMP;
		airRect.height += Player.MAX_JUMP + 3 * tileSize;
		
		this.tileSize = tileSize;
		follow(player, FlxCameraFollowStyle.PLATFORMER, LERP);
		focusOn(player.getPosition());
		deadzone.copyFrom(airRect);
		leadOffset = camYLeadAmount = -tileSize;
		return this;
	}
	
	override function update(elapsed:Float)
	{
		// Deadzone: taller when jumping, but snap to center when on the ground
		if (player.state == Alive && player.onGround != player.wasOnGround)
		{
			deadzone.copyFrom(player.onGround ? groundRect : airRect);
			
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
				// The following messes up at lthe bottom of the level, and only helps with visual debugging
				// if (snapAmount + scroll.y + height + targetOffset.y > maxScrollY)
				// 	snapAmount = maxScrollY - (scroll.y + height + targetOffset.y);
				
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
		
		// Look around
		if (Inputs.pressed.DOWN && player.onGround)
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
		if (leading != MoreDown)
		{
			if (!player.onCoyoteGround && player.velocity.y > 0 && scroll.y > lastPos.y + 1)
			{
				// Lead down when falling for some time
				fallTimer += elapsed;
				if (fallTimer > FALL_LEAD_DELAY)
					leading = CameraTileType.MoreDown;
			}
			else
				fallTimer = 0;
		}
		
		camYLeadAmount = tileSize * leading.getOffset();
		
		// linear shift because I'm lazy and this can get weird if player keeps going back and forth
		if (leadOffset != camYLeadAmount)
		{
			final speed = tileSize * (player.onGround ? GROUND_PAN_LEAD_SHIFT_SPEED : AIR_PAN_LEAD_SHIFT_SPEED);
			if (leadOffset < camYLeadAmount)
			{
				leadOffset += speed * elapsed;
				if (leadOffset > camYLeadAmount)// bound
					leadOffset = camYLeadAmount;
			}
			else
			{
				if (!player.onGround && leadOffset > tileSize * CameraTileType.Down.getOffset())
					leadOffset = camYLeadAmount
				else
					leadOffset -= speed * elapsed;
				
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