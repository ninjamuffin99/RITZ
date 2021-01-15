package props;

import beat.BeatGame;

import flixel.util.FlxColor;
import flixel.FlxSprite;

import zero.utilities.OgmoUtils;

typedef OgmoValues = { autoTalk:Bool, cameraOffsetX:Float };

class Checkpoint extends FlxSprite
{
    public var dialogue = "";
    public var autoTalk = false;
    public var cameraOffsetX = 0.0;

    public function new(x:Float, y:Float, dialogue:String, collectible = false) {
        this.dialogue = dialogue;
        super(x, y + 2);
        moves = false;
        
        inline function addBeatAnim(name:String, frames:Array<Int>, loopsPerBeat = 1.0)
        {
            animation.add(name, frames, 0);
            var anim = animation.getByName(name);
            anim.frameRate = BeatGame.beatsPerSecond * anim.numFrames * loopsPerBeat;
        }
        
        loadGraphic("assets/images/checkpoint.png", true, 32, 32);
        addBeatAnim('idle', [0, 1, 2, 3]);
        addBeatAnim('play', [4, 5, 6, 7]);
        animation.play('idle');
    }
    
    inline function setOgmoProperties(data:EntityData):Checkpoint
    {
        this.ID = data.id;
        var values:OgmoValues = cast data.values;
        this.autoTalk = values.autoTalk;
        this.cameraOffsetX = values.cameraOffsetX;
        return this;
    }
    
    inline public function activate():Void
    {
        @:privateAccess
        var frameTime = animation.curAnim._frameTimer;
        animation.play('play', false, false, animation.curAnim.curIndex);
        @:privateAccess
        animation.curAnim._frameTimer = frameTime;
    }
    inline public function deactivate():Void
    {
        @:privateAccess
        var frameTime = animation.curAnim._frameTimer;
        animation.play('idle', false, false, animation.curAnim.curIndex);
        @:privateAccess
        animation.curAnim._frameTimer = frameTime;
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