package;

import Dust;
import ui.Inputs;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.math.FlxVelocity;
import flixel.util.FlxTimer;

class Player extends FlxSprite
{
    static inline var USE_NEW_SETTINGS = true;
    
    static inline var TILE_SIZE = 32;
    public static inline var MAX_APEX_TIME = USE_NEW_SETTINGS ? 0.40 : 0.35;
    public static inline var MIN_JUMP  = TILE_SIZE * (USE_NEW_SETTINGS ? 1.5 : 2.5);
    public static inline var MAX_JUMP  = TILE_SIZE * (USE_NEW_SETTINGS ? 3.75 : 4.5);
    public static inline var AIR_JUMP  = TILE_SIZE * (USE_NEW_SETTINGS ? 2.0 : 2.0);
    
    static inline var MIN_APEX_TIME = 2 * MAX_APEX_TIME * MIN_JUMP / (MIN_JUMP + MAX_JUMP);
    static inline var GRAVITY = 2 * MIN_JUMP / MIN_APEX_TIME / MIN_APEX_TIME;
    static inline var JUMP_SPEED = -2 * MIN_JUMP / MIN_APEX_TIME;
    static inline var JUMP_HOLD_TIME = (MAX_JUMP - MIN_JUMP) / -JUMP_SPEED;
    static var airJumpSpeed(default, never) = -Math.sqrt(2 * GRAVITY * AIR_JUMP);
    
    public inline static var JUMP_DISTANCE = TILE_SIZE * (USE_NEW_SETTINGS ? 5 : 5);
    public inline static var GROUND_SLOW_DOWN_TIME = (USE_NEW_SETTINGS ? 0.3 : 0.135);
    public inline static var GROUND_SPEED_UP_TIME  = (USE_NEW_SETTINGS ? 0.25 : 0.16);
    public inline static var AIR_SLOW_DOWN_TIME    = (USE_NEW_SETTINGS ? 0.2 : 0.135);
    public inline static var AIR_SPEED_UP_TIME     = (USE_NEW_SETTINGS ? 0.36 : 0.16);
    public inline static var AIRHOP_SPEED_UP_TIME  = (USE_NEW_SETTINGS ? 0.5 : 0.5);
    public inline static var FALL_SPEED = (USE_NEW_SETTINGS ? -JUMP_SPEED : 520.0);
    
    inline static var MAXSPEED = JUMP_DISTANCE / MAX_APEX_TIME / 2;
    inline static var GROUND_ACCEL = MAXSPEED / GROUND_SPEED_UP_TIME;
    inline static var AIR_ACCEL = MAXSPEED / AIR_SPEED_UP_TIME;
    inline static var AIRHOP_ACCEL = MAXSPEED / AIRHOP_SPEED_UP_TIME;
    inline static var GROUND_DRAG = MAXSPEED / GROUND_SLOW_DOWN_TIME;
    inline static var AIR_DRAG = MAXSPEED / AIR_SLOW_DOWN_TIME;
    
    #if debug
    inline static var SHOW_JUMP_HEIGHT = false;
    public var jumpSprite(default, never) = SHOW_JUMP_HEIGHT ? new JumpSprite(MAX_JUMP + AIR_JUMP) : null;
    #end
    
    private var baseJumpStrength:Float = 120;
    private var apexReached:Bool = true;

    // Not a boost per se, simply a counter for the cos wave thing
    private var jumpBoost:Int = 0;

    public var gettingHurt:Bool = false;
    
    /** Input buffering, allow normal jump slightly after walking off a ledge */
    static inline var COYOTE_TIME = 8/60;
    private var coyoteTimer:Float = 0;
    private var airHopped:Bool = false;
    private var jumped:Bool = false;
    private var jumpTimer:Float = 0;
    private var hovering:Bool = false;
    private var wallClimbing:Bool = false;
    /** horizontal boost from being launched, usually by a moving platform */
    private var xAirBoost:Float;
    public var onGround      (default, null):Bool = false;
    public var wasOnGround   (default, null):Bool = false;
    public var onCoyoteGround(default, null):Bool = false;
    
    public var dust:FlxTypedGroup<Dust> = new FlxTypedGroup();
    public var platform:MovingPlatform = null;
    
    public var cheese = new List<Cheese>();
    
    public var left (default, null):Bool;
    public var right(default, null):Bool;
    public var jump (default, null):Bool;
    public var down (default, null):Bool;

    public function new(x:Float, y:Float):Void
    {
        super(x, y);

        loadGraphic(AssetPaths.ritz_spritesheet__png, true, 32, 32);
        animation.add('idle', [0]);
        animation.add('walk', [1, 2, 2, 0], 12);
        animation.add('jumping', [2]);
        animation.add('skid', [3]);
        animation.add('falling', [4]);
        animation.add('fucking died lmao', [7, 8, 9, 10, 11], 12);

        animation.play("idle");

        width  -= 20;
        height -= 8;
        offset.y = 6;
        offset.x = 10;

        setFacingFlip(FlxObject.LEFT, false, false);
        setFacingFlip(FlxObject.RIGHT, true, false);
        
        drag.x = AIR_DRAG;
        acceleration.y = GRAVITY;
        maxVelocity.x = MAXSPEED;
        maxVelocity.y = FALL_SPEED;
    }
    
    public function hurtAndRespawn(x, y):Void
    {
        for (c in cheese)
            c.resetToSpawn();
        cheese.clear();
        
        gettingHurt = true;
        animation.play('fucking died lmao');
        FlxG.sound.play('assets/sounds/damageTaken' + BootState.soundEXT, 0.6);

        new FlxTimer().start(0.5, (_)->respawn(x, y));
    }
    
    public function respawn(x, y):Void
    {
        reset(x, y);
        platform = null;
        gettingHurt = false;
        acceleration.y = GRAVITY;
    }

    override public function update(elapsed:Float):Void
    {
        if (gettingHurt)
        {
            velocity.set();
            acceleration.set();
            xAirBoost = 0;
            
            super.update(elapsed);
        }
        else
        {
            movement(elapsed);
            
            // prevent drag from reducing speed granted from moving platforms unless they accelerate
            var oldDragX = drag.x;
            var oldAccelX = acceleration.x;
            var boosting = xAirBoost != 0;
            if (boosting)
            {
                // boosted but still able to make noticable adjustments in either direction
                var slowBoosted = Math.abs(velocity.x) < MAXSPEED;
                
                // apply acceleration to xBoost and adjust velocity/maxspeed from that
                velocity.x -= xAirBoost;
                
                // accelerating opposite to boost reduces boost
                if (acceleration.x != 0)
                {
                    if (!FlxMath.sameSign(acceleration.x, xAirBoost))
                    {
                        xAirBoost = FlxVelocity.computeVelocity(xAirBoost, acceleration.x, 0, 0, elapsed);
                        acceleration.x = 0;
                    }
                    else if (slowBoosted)
                    {
                        // If the player is making air adjustments convert boost to normal speed, since the player
                        // expects to stop when letting go of left right keys
                        var delta = FlxVelocity.computeVelocity(xAirBoost, -acceleration.x, 0, 0, elapsed) - xAirBoost;
                        xAirBoost += delta;
                        velocity.x = FlxVelocity.computeVelocity(velocity.x, -delta, 0, MAXSPEED, elapsed);
                    }
                    // maxVelocity.x = MAXSPEED + Math.abs(xAirBoost);
                }
                // accelerating forward works like normal
                if (oldAccelX == 0 || acceleration.x != 0)
                    velocity.x = FlxVelocity.computeVelocity(velocity.x, acceleration.x, drag.x, MAXSPEED, elapsed);
                // apply normal drag here
                velocity.x += xAirBoost;
                
                drag.x = 0;
                acceleration.x = 0;
            }
            super.update(elapsed);
            if (boosting)
            {
                drag.x = oldDragX;
                acceleration.x = oldAccelX;
            }
        }
    }
    private function movement(elapsed:Float):Void
    {
        jump  = Inputs.pressed.JUMP;
        down  = Inputs.pressed.DOWN;
        left  = Inputs.pressed.LEFT;
        right = Inputs.pressed.RIGHT;
        
        var jumpR  = Inputs.justReleased.JUMP;
        var downR  = Inputs.justReleased.DOWN;
        var leftR  = Inputs.justReleased.LEFT;
        var rightR = Inputs.justReleased.RIGHT;
        
        var jumpP  = Inputs.justPressed.JUMP;
        var downP  = Inputs.justPressed.DOWN;
        var leftP  = Inputs.justPressed.LEFT;
        var rightP = Inputs.justPressed.RIGHT;
        
        if (velocity.y > 0)
            maxVelocity.y = FALL_SPEED;
        
        wasOnGround = onGround;
        onGround = isTouching(FlxObject.FLOOR);
        
        if (onGround)
        {
            coyoteTimer = 0;
            onCoyoteGround = true;
            
            if (!wasOnGround)
                makeDust(Land);
        }
        else if (coyoteTimer < COYOTE_TIME)
        {
            coyoteTimer += elapsed;
            onCoyoteGround = true;
        }
        else
            onCoyoteGround = false;
        
        if (onGround != wasOnGround)
            drag.x = onGround ? GROUND_DRAG : AIR_DRAG;
        
        if (isTouching(FlxObject.CEILING) || jumpR)
            apexReached = true;
        
        if (left != right)
        {
            var accel:Float = GROUND_ACCEL;
            if (!onCoyoteGround)
            {
                if (airHopped && velocity.y > 0)
                    accel = AIRHOP_ACCEL;
                else
                    accel = AIR_ACCEL;
            }

            // if (hovering)
            //     hoverMulti = 0.6;
            
            acceleration.x = (left ? -1 : 1) * accel;
        }
        else
            acceleration.x = 0;
        
        if (velocity.x != 0)
        {
            facing = velocity.x > 0 ? FlxObject.RIGHT : FlxObject.LEFT;
            if (acceleration.x == 0 || FlxMath.sameSign(velocity.x, acceleration.x))
                animation.play('walk');
            else
            {
                if (onCoyoteGround && animation.curAnim.name == "walk")
                    makeDust(Skid);
                animation.play('skid');
            }
        }
        else if (acceleration.x == 0)
            animation.play('idle');

        //wallJumping();      
        
        if (onCoyoteGround)
        {
            airHopped = false;
            jumped = false;
            hovering = false;
            apexReached = false;
            jumpBoost = 0;
            jumpTimer = 0;
            xAirBoost = 0;
            if (maxVelocity.x > MAXSPEED)
                maxVelocity.x = MAXSPEED;

            if (jumpP)
                startJump();
        }
        else
        {
            if (jumped)
            {
                animation.play(velocity.y < 0 ? 'jumping' : "falling");
                #if debug
                if (jumpSprite != null)
                    jumpSprite.updateHeight(jumpSprite.y - y - height);
                #end
            }
            if (USE_NEW_SETTINGS)
                variableJump_new(elapsed);
            else
            {
                variableJump_old(elapsed);
                jumpTimer = Math.POSITIVE_INFINITY;
            }
            
            
            if (jumpP && !airHopped && !wallClimbing)
            {
                velocity.y = 0;
                
                if (USE_NEW_SETTINGS && left != right)
                {
                    // remove boost if reversing direction
                    if (xAirBoost != 0 && !FlxMath.sameSign(acceleration.x, xAirBoost))
                    {
                        xAirBoost = 0;
                        maxVelocity.x = MAXSPEED;
                    }
                    velocity.x = maxVelocity.x * (left ? -1 : 1);
                }
                // if ((velocity.x > 0 && left) || (velocity.x < 0 && right))
                // {
                //     sorta sidejump style boost thingie
                //     velocity.y -= 200;
                //     velocity.x *= -0.1;
                // }
                    
                // velocity.y = -600;
                velocity.y = airJumpSpeed;
                airHopped = true;
                FlxG.sound.play('assets/sounds/doubleJump' + BootState.soundEXT, 0.75);
            }
        }

        
        
        /* 
        if (airHopped && velocity.y > 0)
        {
            drag.x = 200;

            if (jump)
            {
                hovering = true;
            }
            else
            {
                hovering = false;
            }
        }
        */

        if (wallClimbing)
        {
            airHopped = false;
            hovering = false;
        }
    }
    
    /**
     *  This is super ad-hoc and probably going to cause a ton of bugs
     * @param platform 
     */
    public function onSeparatePlatform(platform:MovingPlatform):Void
    {
        if (onGround && velocity.y < 0 && !jumped)
        {
            y = platform.y - height;
            velocity.y = 0;
            this.platform = platform;
        }
    }
    
    public function onLandPlatform(platform:MovingPlatform):Void
    {
        velocity.x -= platform.velocity.x;
    }
    
    function startJump()
    {
        if (USE_NEW_SETTINGS && acceleration.x != 0)
        {
            //quick change jump dir
            final allowSkidJump = !onCoyoteGround
                || (velocity.x != 0 && !FlxMath.sameSign(acceleration.x, velocity.x));
            if (allowSkidJump)
                velocity.x = maxVelocity.x * (left ? -1 : 1);
        }
        maxVelocity.y = Math.max(-airJumpSpeed, -JUMP_SPEED);
        if (platform != null)
        {
            if (platform.transferVelocity.y < 0)
                maxVelocity.y += -platform.transferVelocity.y;
            velocity.y = platform.transferVelocity.y;
            
            xAirBoost = platform.transferVelocity.x;
            // persistent x force after jumping from moving platform?
            if (maxVelocity.x < Math.abs(xAirBoost))
                maxVelocity.x = Math.abs(xAirBoost);
            velocity.x += xAirBoost;
            platform = null;
        }
        #if debug
        if (jumpSprite != null)
        {
            jumpSprite.resetHeight();
            jumpSprite.x = x;
            jumpSprite.y = y + height;
        }
        #end
        velocity.y += JUMP_SPEED;
        jumped = true;
        onGround = false;
        onCoyoteGround = false;
        wasOnGround = true;
        FlxG.sound.play('assets/sounds/jump' + BootState.soundEXT, 0.5);
        coyoteTimer = COYOTE_TIME;
    }
    
    function variableJump_new(elapsed:Float):Void
    {
        if (jump && !apexReached)
        {
            if (!jumped)
            {
                velocity.y = 0;
                startJump();
            }
            
            jumpTimer += elapsed;
            if (jumpTimer < JUMP_HOLD_TIME)
            {
                if (velocity.y > JUMP_SPEED)
                    velocity.y = JUMP_SPEED;
            }
            else
            {
                jumpTimer = JUMP_HOLD_TIME;
                apexReached = true;
            }
        }
    }
    
    function variableJump_old(elapsed:Float):Void
    {
        if (jump && !apexReached)
        {
            jumped = true;
            jumpBoost++;

            var C = FlxMath.fastCos(10.7 * jumpBoost * FlxG.elapsed);
            FlxG.watch.addQuick('Cos', C);
            if (C < 0)
            {
                apexReached = true;
            }
            else
            {
                velocity.y -= C * (baseJumpStrength * 1.6) * 2;
            }
        }
    }

    private function wallJumping():Void
    {
        if (isTouching(FlxObject.WALL))
        {
            
            if (jump && down)
                jump = down = false;
            
            if (jump || down)
            {
                if (jump)
                {
                    acceleration.y = -GROUND_ACCEL * 0.8;
                }
    
                if (down)
                {
                    acceleration.y = 900;
                }
            }
            else
            {
                acceleration.y = 0;
            }
            
    
    
            wallClimbing = true;
        }
        else
        {
            wallClimbing = false;
        }

    }
    
    function makeDust(type:DustType):Dust
    {
        var newDust = dust.recycle(Dust);
        newDust.place(type, x + width / 2, y + height, flipX);
        if (type == Skid)
        {
            newDust.x += (flipX ? 1 : -1) * width;
            newDust.velocity.x = velocity.x / 4;
            newDust.drag.x = Math.abs(newDust.velocity.x) * 2;
        }
        return newDust;
    }
}

abstract JumpSprite(FlxSpriteGroup) to FlxSprite
{
    static var colors = [0xFF123884, 0xFF69bcf3, 0xFF123884, 0xFFffffff];
    inline static var TILE = 32 >> 2;
    
    public var x(get, set):Float;
    inline function get_x() return this.x;
    inline function set_x(value:Float) return this.x = value;
    public var y(get, set):Float;
    inline function get_y() return this.y;
    inline function set_y(value:Float) return this.y = value;
    public var height (get, set):Float;
    function get_height()
    {
        final alive = this.countLiving();
        return
            if (alive == 0) 0;
            else (alive - 1 + this.group.members[alive - 1].scale.y) * TILE;
    }
    function set_height(value:Float)
    {
        for (i in 0...this.length)
        {
            if ((i+1) * TILE < value)
            {
                this.members[i].revive();
                this.members[i].scale.y = 1;
            }
            else if(i * TILE < value)
            {
                this.members[i].revive();
                this.members[i].scale.y = (value % TILE) / TILE;
            }
            else
                this.members[i].kill();
        }
        
        return this.height = value;
    }
    
    inline public function new (maxHeight:Float, x = 0.0, y = 0.0)
    {
        var size = Math.ceil(maxHeight / TILE);
        this = new FlxSpriteGroup(x, y, size);
        while (size-- > 0)
        {
            var sprite = new FlxSprite(0, -(this.maxSize - size + 1) * TILE);
            sprite.makeGraphic(TILE, TILE, colors[size % colors.length]);
            sprite.offset.x = sprite.origin.x;
            sprite.offset.y = -TILE;
            sprite.origin.y = TILE;
            this.add(sprite);
        }
    }
    
    public function updateHeight(value:Float):Void
    {
        if (value > height)
            height = value;
    }
    
    public function resetHeight():Void
    {
        for (child in this.members)
        {
            child.scale.y = 1;
            child.kill();
        }
    }
}