package props;

import flixel.effects.FlxFlicker;
import data.PlayerSettings;

import zero.utilities.OgmoUtils;

import flixel.math.FlxPoint;
import flixel.util.FlxPath;
import flixel.FlxObject;
import flixel.util.FlxColor;
import flixel.FlxSprite;

class Enemy extends FlxSprite implements Bouncer
{
    inline static var RESPAWN_TIME = 5.0;
    inline static var RESPAWN_BLINK_TIME = 1.0;
    inline static var RESPAWN_BLINK_FREQ = 1.0 / 8;
    
    public var bumpMin(default, null) = 0.0;
    public var bumpMax(default, null) = 2.0;
    
    var spawn = FlxPoint.get();
    var spawnTimer = 0.0;
    
    public function new(data:TypedEntityData<{speed:Float}>) {
        super(data.x - data.originX, data.y - data.originY);
        
        width = 22;
        offset.x = 8;
        x += offset.x;
        height = 18;
        offset.y = 8;
        y += offset.y;
        spawn = getPosition(spawn);
        
        loadGraphic("assets/images/spider.png", true, 27, 28);
        animation.add('idle', [0, 1, 2, 3], 12);
        animation.add('walk', [4, 5, 6], 12);

        setFacingFlip(FlxObject.LEFT, false, false);
        setFacingFlip(FlxObject.RIGHT, true, false);

        path = OgmoPath.fromEntity(data);
        path.autoCenter = false;
        
        for (n in path.nodes)
        {
            n.x += x - data.x;
            n.y += y - data.y;
        }
        
        path.restart();
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);
        
        if (spawnTimer > 0)
        {
            spawnTimer -= elapsed;
            if (spawnTimer <= 0)
                respawn();
            else if (spawnTimer <= RESPAWN_BLINK_TIME)
                visible = (spawnTimer % RESPAWN_BLINK_FREQ) > (RESPAWN_BLINK_FREQ / 2);
        }
        else if (velocity.x != 0)
        {
            animation.play('walk');

            if (velocity.x > 0)
                facing = FlxObject.RIGHT;
            else
                facing = FlxObject.LEFT;

        }
        else
            animation.play('idle');
    }
    
    public function die()
    {
        solid = false;
        spawnTimer = 5.0;
        path.active = false;
        velocity.set(0, 0);
        FlxFlicker.flicker(this, RESPAWN_BLINK_TIME, RESPAWN_BLINK_FREQ, false, true, (_)->onDeathComplete());
    }
    
    function onDeathComplete()
    {
        reset(spawn.x, spawn.y);
    }
    
    public function respawn()
    {
        spawnTimer = 0;
        visible = true;
        solid = true;
        path.restart();
    }
}