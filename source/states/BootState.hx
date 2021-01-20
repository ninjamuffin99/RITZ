package states;

import data.PlayerSettings;
import ui.BitmapText;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

import flixel.addons.effects.FlxTrailArea;
import flixel.addons.effects.FlxTrail;

class BootState extends flixel.FlxState
{
    inline public static var soundEXT = #if desktop ".ogg" #else ".mp3" #end;
    var daText:BitmapText;
    var intro:FlxSprite;
    
    override function create() 
    {
        PlayerSettings.init();
        FlxG.autoPause = false;
        FlxG.camera.bgColor = FlxColor.WHITE;
        
        #if NG_LOGIN
        new utils.NGio(data.ApiData.ID, data.ApiData.ENC_KEY, data.ApiData.SESSION);
        #end
        
        #if SKIP_TO_PLAYSTATE
        FlxG.switchState(new AdventureState());
        #else
        // startIntro();
        #end
        
        super.create();
    }
    
    @:keep// So menustate code is always checked for errors
    public function startIntro():Void
    {
        daText = new BitmapText(0, 0, "ninjamuffin99\nMKMaffo\nKawaisprite\nDigimin\nand Geokureli\npresent...", 0xFF000000, 2);

        var blackBG:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        add(blackBG);
        
        intro = new FlxSprite();
        intro.loadGraphic("assets/images/ui/intro/ritz.png", true, 480, 288);
        intro.animation.add('standby', [0], 0, false);
        intro.animation.add('start', [for (i in 0...intro.animation.frames) i], 12, false);
        intro.animation.play('standby');
        intro.visible = false;
        
        var _trail:FlxTrailArea = new FlxTrailArea(0, 0, FlxG.width, FlxG.height, 0.4, 2, true);
        _trail.visible = false;
        _trail.add(intro);
        //add(_trail);
        add(intro);

        daText.alignment = CENTER;
        daText.screenCenter();
        daText.y -= 8;
        add(daText);
        daText.alpha = 0;
        

        FlxTween.tween(daText, {alpha: 1}, 0.8, {ease:FlxEase.quadInOut});
        FlxTween.tween(daText, {y: daText.y + 8}, 2.2, {ease:FlxEase.quadInOut});
        
        FlxG.sound.playMusic('assets/sounds/boot' + soundEXT, 0.6, false);
        
        new FlxTimer().start(4.74, function(_)
        {
            FlxTween.tween(blackBG, {alpha: 0}, 0.9);
            FlxG.sound.play('assets/sounds/drumRoll' + BootState.soundEXT, 0.6);
        });

        new FlxTimer().start(5, function(_)
        {
            // FlxG.sound.play('assets/sounds/drumRoll' + BootState.soundEXT, 0.6);
            intro.animation.play('start');
            intro.animation.finishCallback = function(_) onIntroComplete();
            intro.visible = true;
            _trail.visible = true;
        });
        
        super.create();
    }
    
    function onIntroComplete()
    {
        FlxG.switchState(new TitleState());
    }
    
    override function update(elapsed:Float)
    {
        if (FlxG.sound.music == null)
        {
            if (FlxG.mouse.pressed)
                startIntro();
        }
        else if (FlxG.sound.music.time >= 4270)
        {
            daText.text = "";
        }
        else if (FlxG.sound.music.time >= 3470)
        {
            daText.text = "In association \nwith Newgrounds...";
            daText.alignment = CENTER;
            daText.screenCenter();
        }
        
        super.update(elapsed);
    }
}