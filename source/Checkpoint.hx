package;

import flixel.util.FlxColor;
import flixel.FlxSprite;

import zero.utilities.OgmoUtils;

class Checkpoint extends FlxSprite
{
    public static var counter(default, null) = 0;
    
    public var isCurCheckpoint:Bool = false;
    public var id(default, null) = -1;
    public var dialogue(default, null):String = "";
    public var autoTalk(default, null) = false;
    public var cameraOffsetX(default, null) = 0.0;

    public function new(x:Float, y:Float, dialogue:String, autoTalk = false, cameraOffsetX = 0, collectible = false) {
        this.dialogue = dialogue;
        this.autoTalk = autoTalk;
        this.cameraOffsetX = cameraOffsetX;
        if (collectible)
            id = counter++;
        super(x, y + 2);
        
        loadGraphic(AssetPaths.checkpoint_rat__png, true, 32, 32);
        animation.add('idle', [0, 1, 2, 3], 10);
        animation.add('play', [4, 5, 6, 7], 10);
        animation.play('idle');
    }

    override function update(elapsed:Float) {
        if (isCurCheckpoint)
            animation.play('play');
        else
            animation.play('idle');
        super.update(elapsed);
    }
    
    public function onTalk() autoTalk = false;
    
    inline static public function fromOgmo(entity:EntityData)
    {
        return new Checkpoint
            ( entity.x
            , entity.y
            , entity.values.dialogue
            , entity.values.autoTalk
            , entity.values.cameraOffsetX
            , true
            );
    }
}