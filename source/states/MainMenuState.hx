package states;

import flixel.effects.FlxFlicker;
import flixel.math.FlxAngle;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxSprite;
import flixel.addons.display.FlxTiledSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.FlxG;
import ui.MenuItem;

class MainMenuState extends flixel.FlxState
{
    var cheese:FlxTiledSprite;
    public static var textMenuItems:Array<String> = ['Single Player', 'Race Mode', "Gallery", 'Options', 'Credits']; 

    override function create() {
        FlxG.autoPause = false;
        FlxG.sound.playMusic('assets/music/ultracheddar' + BootState.soundEXT, OptionsSubState.masterVol * OptionsSubState.musicVol);

        var cheeseBG:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFFf2a348);
        add(cheeseBG);

        cheese = new FlxTiledSprite("assets/images/ui/main_menu/cheese.png", FlxG.width, FlxG.height);
        cheese.scrollX = 10;
        cheese.scrollY = 10;
        add(cheese);

       
        persistentDraw = persistentUpdate = true;

        openSubState(new MenuBackend(textMenuItems));
        

        super.create();
    }

    override function update(elapsed:Float) {

        super.update(elapsed);

        var scrollShit:Float = FlxG.height * 0.3 * 0.25 * FlxG.elapsed;
        cheese.alpha = 0.1;
        cheese.scrollX -= scrollShit;
        cheese.scrollY += scrollShit;
    }
}