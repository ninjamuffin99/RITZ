package utils;

import flixel.FlxG;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxSprite;

class SpriteEffects
{
    inline static public function scaleToInTime(
        sprite:FlxSprite,
        scaleFactor:Float,
        duration:Float,
        ?onComplete:()->Void,
        ?options:TweenOptions)
    {
        if (options == null)
            options = { ease: sprite.scale.x < scaleFactor ? FlxEase.backOut : FlxEase.backIn };
        
        if (onComplete != null)
            options.onComplete = (_)->onComplete();
        
        return FlxTween.tween(sprite.scale, { x:scaleFactor, y:scaleFactor }, duration, options);
    }
    
    static public function wiggleX(target, ?distance, duration = 0.5, ?onComplete, numWiggles = 5)
        inline wiggle(target, distance, true, duration, onComplete);
    
    static public function wiggleY(target, ?distance, duration = 0.5, ?onComplete, numWiggles = 5)
        inline wiggle(target, distance, false, duration, onComplete);
    
    @:noCompletion
    static public function wiggle(target:FlxSprite, ?distance:Float, horizontal = true, duration = 0.5, ?onComplete:()->Void, numWiggles = 5)
    {
        if (distance == null)
            distance = horizontal ? target.width : target.height;
        
        var start = horizontal ? target.x : target.y;
        function end(_)
        {
            if (horizontal)
                target.x = start;
            else
                target.y = start;
            if (onComplete != null)
                onComplete();
        }
        
        FlxTween.num(0, 1, duration, { onComplete:end }, 
            function (n)
            {
                final tSin = Math.sin(n * Math.PI * numWiggles);
                final strength = 1 - FlxEase.quadIn(n);
                
                if (horizontal)
                    target.x = start + distance * tSin * strength;
                else
                    target.y = start + distance * tSin * strength;
            }
        );
    }
    
    inline static public function blink(period:Float, offset = 0.0):Bool
    {
        return (((FlxG.game.ticks / 1000) - offset) % period) * 2 > period;
    }
    
    inline static public function blinkTicks(period:Int, offset = 0):Bool
    {
        return ((FlxG.game.ticks - offset) % period) * 2 > period;
    }
}