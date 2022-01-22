package utils;

import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;

abstract Flicker(FlxTween)
{
    static public function ease(rate = 0.04):(t:Float)->Void
    {
        return function (t)
        {
            return (t % rate) > rate / 2;
        }
    }
    
    public function new(object, values, duration = 1, rate = 0.04, ?options)
    {
        options = optionsHelper(rate);
        this = FlxTween.tween(object, values, duration, options);
    }
    
    function optionsHelper(options:Null<TweenOptions>, rate:Float)
    {
        if (options == null)
            options = {};
        
        if (options.ease == null)
            options.ease = ease(rate);
        
        return options;
    }
    
    static function addCallback(options:Null<TweenOptions>, field:String, callback:TweenCallback)
    {
        if (options == null)
            options = {};
        
        final oldCallback = Reflect.field(options, field);
        var func = callback;
        if (oldCallback != null)
        {
            func = function (t)
            {
                oldCallback(t);
                callback(t);
            }
        }
        
        Reflect.setField(options, field, func);
    }
    
    inline static function addCompleteCallback(options:Null<TweenOptions>, callback:TweenCallback)
    {
        addCallback(options, "onComplete", callback);
    }
    
    inline static function addUpdateCallback(options:Null<TweenOptions>, callback:TweenCallback)
    {
        addCallback(options, "onUpdate", callback);
    }
    
    static public function flicker(object, values, duration = 1, rate = 0.04, ?options)
    {
        return new Flicker(object, values, duration, rate, options);
    }
    
    // static public function flickerColor(sprite:FlxSprite, color:FlxColor, duration = 1, rate = 0.04, ?options)
    // {
    //     var oldValue = sprite.useColorTransform;
    //     var oldTransform = sprite.colorTransform;
    //     sprite.useColorTransform = true;
    //     sprite.colorTransform = new ColorTransform()
    //     options = {};
    //     options = addCompleteCallback(options,
    //         (_)->
    //         {
    //             sprite.useColorTransform = oldValue;
    //             sprite.colorTransform = oldTransform;
    //         }
    //     );
    //     return new Flicker(sprite.colorTransform., { color:color }, duration, rate, options);
    // }
}