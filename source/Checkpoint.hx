package;

import flixel.util.FlxColor;
import flixel.FlxSprite;

import zero.utilities.OgmoUtils;

typedef OgmoValues = { autoTalk:Bool, cameraOffsetX:Float };

class Checkpoint extends FlxSprite
{
    public var isCurCheckpoint:Bool = false;
    public var dialogue = "";
    public var autoTalk = false;
    public var cameraOffsetX = 0.0;

    public function new(x:Float, y:Float, dialogue:String, collectible = false) {
        this.dialogue = dialogue;
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
    
    inline function setOgmoProperties(data:EntityData):Checkpoint
    {
        this.ID = data.id;
        var values:OgmoValues = cast data.values;
        this.autoTalk = values.autoTalk;
        this.cameraOffsetX = values.cameraOffsetX;
        return this;
    }
    
    public function onTalk() autoTalk = false;
    
    inline static public function fromOgmo(entity:EntityData)
    {
        return new Checkpoint
            ( entity.x
            , entity.y
            , entity.values.dialogue
            , true
            ).setOgmoProperties(entity);
    }
}