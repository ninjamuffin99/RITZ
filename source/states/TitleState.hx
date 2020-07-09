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
    var title:FlxSprite;

    
    override public function create() {

        FlxG.sound.playMusic('assets/music/fluffydream' + OptionsSubState.DXmusic + BootState.soundEXT, 0.7);
        // FlxG.sound.music.fadeIn(5, 0, 1);
        FlxG.camera.fade(FlxColor.WHITE, 2, true);
        FlxG.sound.play('assets/sounds/titleCrash' + BootState.soundEXT, 0.4);

        var tex = FlxAtlasFrames.fromSpriteSheetPacker(AssetPaths.titleScreen__png, AssetPaths.titleScreen__txt);

        title = new FlxSprite();
        title.frames = tex;
        title.animation.add('baby', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10], 0);
        title.animation.add('ritz', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10], 12, false);
        title.animation.play('baby', false, false, 10);
        add(title);

        pressStart = new FlxSprite().loadGraphic(AssetPaths.introcheesetext__png);
        add(pressStart);

        FlxFlicker.flicker(pressStart, 0, 0.5);

        #if (!debug && NG_LOGIN)
		    var ng:NGio = new NGio(APIStuff.APIKEY, APIStuff.EncKey);
		#end
        
        super.create();
    }

    override function update(elapsed:Float) {
        
        if (title.animation.curAnim.name != 'ritz')
        {
            if ((FlxG.keys.justPressed.ANY || FlxG.gamepads.anyButton(JUST_PRESSED)) && FlxG.sound.music != null)
            {
                FlxFlicker.flicker(pressStart, 1, 0.04, false, true, function(flic:FlxFlicker)
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
        }
        
        super.update(elapsed);
    }
}