package;

import flixel.FlxG;
import flixel.FlxSprite;

class Dust extends FlxSprite
{
    public function new(x:Float, y:Float) {
        super(x, y);


        this.x -= 5;
        this.y -=  8; 

        loadGraphic(AssetPaths.dust__png, true, 32, 32);
        animation.add("play", [0, 1, 2, 2, 2, 3], FlxG.random.int(19,24), false);
        animation.play('play');

        flipX = FlxG.random.bool();
    }

    override function update(elapsed:Float) {
        if (animation.curAnim.finished)
            kill();
        
        super.update(elapsed);
    }
}