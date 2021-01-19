package states;

import ui.Controls;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.util.FlxColor;

class TitleState extends flixel.FlxState
{
    var pressStart:FlxSprite;

    
    override public function create() {

        FlxG.sound.playMusic('assets/music/fluffydream' + OptionsSubState.DXmusic + BootState.soundEXT, 0.7);
        // FlxG.sound.music.fadeIn(5, 0, 1);
        FlxG.camera.fade(FlxColor.WHITE, 2, true);
        FlxG.sound.play('assets/sounds/titleCrash' + BootState.soundEXT, 0.4);
        
        var titleBg = new FlxSprite("assets/images/ui/intro/bg.png");
        add(titleBg);
        
        var ritz = new FlxSprite();
        ritz.loadGraphic("assets/images/ui/intro/ritz.png", true, titleBg.graphic.width, titleBg.graphic.height);
        ritz.animation.add('idle', [ritz.animation.frames - 1]);
        ritz.animation.play('idle');
        add(ritz);

        pressStart = new FlxSprite().loadGraphic("assets/images/ui/intro/instructions.png");
        add(pressStart);

        FlxFlicker.flicker(pressStart, 0, 0.5);
        
        super.create();
    }

    override function update(elapsed:Float)
    {
        if ((FlxG.keys.justPressed.ANY || FlxG.gamepads.anyButton(JUST_PRESSED)) && FlxG.sound.music != null)
        {
            
            FlxFlicker.flicker(pressStart, 1, 0.04, false, true, function(_)
            {
                //FlxG.sound.play('assets/sounds/ritzstartjingle' + BootState.soundEXT);
                FlxG.camera.fade(FlxColor.BLACK, 2, false, function()
                {
                    FlxG.switchState(new MainMenuState());
                });
            });
            
            FlxG.sound.play('assets/sounds/startbleep' + BootState.soundEXT);
            if (FlxG.sound.music != null)
            {
                FlxG.sound.music.stop();
                FlxG.sound.music = null;
            }
        }
        
        super.update(elapsed);
    }
}