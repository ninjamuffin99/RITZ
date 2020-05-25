package states;

import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.FlxG;
import flixel.system.FlxSoundGroup;
import flixel.text.FlxText;
import flixel.FlxState;

class BootState extends FlxState
{
    inline public static var soundEXT = #if desktop ".ogg" #else ".mp3" #end;
    var daText:FlxText;

    override function create() 
    {
        daText = new FlxText(0, 0, 0, "ninjamuffin99\nMKMaffo\nKawaisprite\nDigimin\nand Geokureli\npresent...",16);
        daText.alignment = CENTER;
        daText.screenCenter();
        daText.y -= 8;
        add(daText);
        daText.alpha = 0;

        FlxTween.tween(daText, {alpha: 1}, 0.8, {ease:FlxEase.quadInOut});
        FlxTween.tween(daText, {y: daText.y + 8}, 2.2, {ease:FlxEase.quadInOut});
        
        FlxG.sound.playMusic('assets/sounds/boot' + soundEXT, 0.6, false);
        
        new FlxTimer().start(5.5, function(tmr:FlxTimer)
        {
            FlxG.camera.fade(FlxColor.WHITE, 1, function()
                {
                    FlxG.switchState(new MenuState());
                });
            
        });
        
        super.create();
    }

    override function update(elapsed:Float) {
        
        if (FlxG.sound.music.time >= 3470)
        {
            daText.text = "In association \nwith Newgrounds...";
            daText.alignment = CENTER;
            daText.screenCenter();
        }
        
        super.update(elapsed);
    }
}