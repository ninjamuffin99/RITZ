package props;

import flixel.tweens.FlxEase;
import flixel.graphics.FlxGraphic;
import flixel.FlxG;
import props.Platform;

import zero.utilities.OgmoUtils;

typedef BlinkingPlatformValues = TriggerPlatformValues & 
{
    showTime:Float,
    warnTime:Float,
    ?hideTime:Float,
    startDelay:Float
}

class BlinkingPlatform extends TriggerPlatform
{
    public var showTime = 1.0;
    public var warnTime = 0.25;
    public var hideTime = 0.0;
    var timer = 0.0;
    var onGraphic:FlxGraphic;
    var offGraphic:FlxGraphic;
    
    public function new(x:Float, y:Float)
    {
        super(x, y);
    }
    
    override function setOgmoProperties(data:EntityData)
    {
        final values:BlinkingPlatformValues = cast data.values;
        showTime = values.showTime;
        warnTime = values.warnTime;
        if (values.hideTime == null || values.hideTime <= 0)
            hideTime = showTime;
        else
            hideTime = values.hideTime;
        
        active = showTime > 0;
        
        super.setOgmoProperties(data);
        onGraphic = graphic;
        offGraphic = Platform.getImageFromOgmo(data.values.graphic, data.width, data.height, oneWayPlatform ? "cloudOff" : "solidOff");
        
        var startDelay = values.startDelay % (showTime + hideTime);
        if (trigger != Load && startDelay != 0)
            throw 'startDelay is only usable when trigger="Load"';
        else if (trigger == Load && startDelay > 0)
        {
            timer = showTime + hideTime - startDelay;
            enabled = timer < showTime;
        }
    }
    
    inline static var NUM_FLICKERS = 2;
    inline static var FLICKER_ON_RATIO = 0.75;
    inline static var FLICKER_OFF_RATIO = 1 - FLICKER_ON_RATIO;
    inline static var FLICKER_OFF_COLOR_MULT = 0.5;
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        if (!triggered)
            return;
        
        var oldTimer = timer;
        timer += elapsed;
        
        if (timer > showTime + hideTime)
        {
            timer -= showTime + hideTime;
            showOn();
            enabled = true;
            resetTrigger();
        }
        
        if (timer >= showTime)
        {
            if (oldTimer < showTime)
            {
                showOff();
                enabled = false;
            }
        }
        else if (timer > showTime - warnTime)
        {
            final flickerRate = warnTime / NUM_FLICKERS;
            var onAmount = ((timer - (showTime - warnTime)) % flickerRate) / flickerRate;
            if (onAmount < FLICKER_OFF_RATIO)
                onAmount = (FLICKER_OFF_RATIO - onAmount) / FLICKER_OFF_RATIO;
            else
                onAmount = (onAmount - FLICKER_OFF_RATIO) / Math.min(FLICKER_ON_RATIO, FLICKER_OFF_RATIO);
            
            if (onAmount > 1)
                onAmount = 1;
            
            final colorMult = (1 - FLICKER_OFF_COLOR_MULT) + FlxEase.smoothStepIn(onAmount) * FLICKER_OFF_COLOR_MULT;
            setColorTransform(colorMult, colorMult, colorMult);
        }
        else if (timer > 0 && oldTimer <= 0)
        {
            showOn();
            enabled = true;
        }
    }
    
    function showOn()
    {
        setColorTransform();
        graphic = onGraphic;
        frames = graphic.imageFrame;
    }
    
    function showOff()
    {
        setColorTransform();
        graphic = offGraphic;
        frames = graphic.imageFrame;
    }
    inline function showOnWarn() showOff();
    
    override function resetTrigger()
    {
        super.resetTrigger();
        if (trigger == Load)
            fire();
    }
    
    inline static public function fromOgmo(data:EntityData)
    {
        var platform = new BlinkingPlatform(data.x, data.y);
        platform.setOgmoProperties(data);
        return platform;
    }
}