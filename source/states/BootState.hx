package states;

import ui.BitmapText;
import flixel.text.FlxBitmapText;
import flixel.addons.effects.FlxTrailArea;
import flixel.addons.effects.FlxTrail;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.FlxSprite;
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
    var daText:BitmapText;
    var titleJump:FlxSprite;
    

    override function create() 
    {
        FlxG.camera.bgColor = FlxColor.WHITE;

        var blackBG:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        add(blackBG);

        var titleFrames = FlxAtlasFrames.fromSpriteSheetPacker(AssetPaths.titleJump__png, AssetPaths.titleJump__txt);
        titleJump = new FlxSprite();
        titleJump.frames = titleFrames;
        titleJump.animation.add('standby', [0], 0, false);
        titleJump.animation.addByPrefix('start', 'frame', 12, false);
        titleJump.animation.play('standby');
        titleJump.visible = false;
        

        var _trail:FlxTrailArea = new FlxTrailArea(0, 0, FlxG.width, FlxG.height, 0.4, 2, true);
        _trail.visible = false;
        _trail.add(titleJump);
        //add(_trail);
        add(titleJump);

        daText = new BitmapText(0, 0, "ninjamuffin99\nMKMaffo\nKawaisprite\nDigimin\nand Geokureli\npresent...", 0xFF000000, 2);
        // daText = new FlxBitmapText(0, 0, 0, "ninjamuffin99\nMKMaffo\nKawaisprite\nDigimin\nand Geokureli\npresent...",16);
        daText.alignment = CENTER;
        daText.screenCenter();
        daText.y -= 8;
        add(daText);
        daText.alpha = 0;
        

        FlxTween.tween(daText, {alpha: 1}, 0.8, {ease:FlxEase.quadInOut});
        FlxTween.tween(daText, {y: daText.y + 8}, 2.2, {ease:FlxEase.quadInOut});
        
        FlxG.sound.playMusic('assets/sounds/boot' + soundEXT, 0.6, false);
        
        new FlxTimer().start(4.74, function(tmr:FlxTimer)
        {
            FlxTween.tween(blackBG, {alpha: 0}, 0.9);
            FlxG.sound.play('assets/sounds/drumRoll' + BootState.soundEXT, 0.6);
        });

        new FlxTimer().start(5, function(tmr:FlxTimer)
        {
            // FlxG.sound.play('assets/sounds/drumRoll' + BootState.soundEXT, 0.6);
            titleJump.animation.play('start');
            titleJump.visible = true;
            _trail.visible = true;
        });
        
        super.create();
    }


    override function update(elapsed:Float) {
        
        if (titleJump.animation.curAnim.name == 'start' && titleJump.animation.curAnim.curFrame == 7)
        {
            FlxG.switchState(new TitleState());  
        }


        if (FlxG.sound.music.time >= 3470)
        {
            daText.text = "In association \nwith Newgrounds...";
            daText.alignment = CENTER;
            daText.screenCenter();
        }
        
        super.update(elapsed);
    }
}