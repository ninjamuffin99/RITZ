package;

import flixel.util.FlxTimer;
import flixel.FlxG;
import flixel.system.FlxSoundGroup;
import flixel.text.FlxText;
import flixel.FlxState;

class BootState extends FlxState
{
    override function create() {
        var daText:FlxText = new FlxText(0, 0, 0, "ninjamuffin99\nMKMaffo\nKawaisprite\nand Digimin\npresents...",16);
        daText.alignment = CENTER;
        daText.screenCenter();
        add(daText);

        FlxG.sound.play(AssetPaths.checkpoint__mp3, 0.6);

        new FlxTimer().start(2, function(tmr:FlxTimer){FlxG.switchState(new MenuState());});


        super.create();
    }
}