package;
import flixel.path.FlxPath;
import flixel.FlxObject;
import flixel.util.FlxColor;
import flixel.FlxSprite;

class Enemy extends FlxSprite
{
    public function new(x:Float, y:Float, p:FlxPath, speed:Float) {
        super(x, y);

        loadGraphic(AssetPaths.spider_enemy__PNG, true, 32, 32);
        animation.add('idle', [0, 1, 2, 3], 12);
        animation.add('walk', [4, 5, 6, 7], 12);

        setFacingFlip(LEFT, false, false);
        setFacingFlip(RIGHT, true, false);

        path = p;
        path.centerMode = TOP_LEFT;
        
        for (n in path.nodes)
        {
            n.y += 14;
        }

        path.start(null, speed, LOOP_FORWARD);


        height -= 14;
        offset.y = 8;
        width -= 10;
        offset.x = 8;
    }

    override public function update(e:Float) {
        super.update(e);

        if (velocity.x != 0)
        {
            animation.play('walk');

            if (velocity.x > 0)
                facing = RIGHT;
            else
                facing = LEFT;

        }
        else
            animation.play('idle');
    }
}