package props;

import states.BootState;
import ui.BitmapText;

import flixel.FlxG;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

import zero.utilities.OgmoUtils;

class Lock extends flixel.FlxSprite
{
    public var amountNeeded:Int = 0;
    
    public function new (tall = false, x = 0.0, y = 0.0, width = 64, height = 32, amountNeeded = 32)
    {
        super(x, y, "assets/images/door_" + (tall ? "tall" : "wide") + ".png");
        setGraphicSize(width, height);
        updateHitbox();
        immovable = true;
        this.amountNeeded = amountNeeded;
    }
    
    inline public function open():Void
    {
        kill();
        FlxG.sound.play('assets/sounds/allcheesesunlocked' + BootState.soundEXT);
        FlxG.camera.shake(0.05, 0.15);
    }
    
    public function createText()
    {
        return new LockAmountText(x + width / 2, y + height / 2, amountNeeded);
    }
    
    static public function fromOgmo(data:EntityData)
    {
        return new Lock
            ( data.name == "locked_tall"
            , data.x, data.y
            , data.width, data.height
            , data.values.amountNeeded
            );
    }
}

@:forward
abstract LockAmountText(BitmapText) to BitmapText
{
	inline public function new (x, y, amount:Int)
	{
		this = new BitmapText(x, y, Std.string(amount));
		#if debug this.ignoreDrawDebug = true; #end
		this.offset.x = this.width / 2;
		this.offset.y = this.height / 2;
	}
	
	inline public function animateTo(x:Float, y:Float, callback:()->Void):Void
	{
		showLockAmount
		(   ()->
			{
				this.x -= this.camera.scroll.x;
				this.y -= this.camera.scroll.y;
				this.scrollFactor.set();
			}
		).then(FlxTween.tween
			( this
			, { x:x, y:y }
			,   { ease:FlxEase.cubeIn
				, onComplete:(_)->callback()
				}
			)
		);
	}
	
	inline static var RISE_AMOUNT = 32;
	inline public function showLockAmount(callback:()->Void)
	{
		var onComplete:TweenCallback = null;
		if (callback != null)
			onComplete = (_)->callback();
		
		return FlxTween.tween
			( this
			, { y:this.y - RISE_AMOUNT }
			, 0.5
			,   { ease:FlxEase.backOut
				, onComplete:onComplete
			 	}
			);
	}
}