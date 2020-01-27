package;

import flixel.util.FlxTimer;
import flixel.FlxG;
import flixel.system.FlxSoundGroup;
import flixel.text.FlxText;
import flixel.FlxState;

class BootState extends FlxState
{
    public static var soundEXT:String = ".mp3";
    override function create() {
        FlxG.mouse.visible = false;

        #if desktop
            soundEXT = ".ogg";
        #end

        var daText:FlxText = new FlxText(0, 0, 0, "ninjamuffin99\nMKMaffo\nKawaisprite\nand Digimin\npresent...",16);
        daText.alignment = CENTER;
        daText.screenCenter();
        add(daText);

        FlxG.sound.play('assets/sounds/checkpoint' + soundEXT, 0.6);

        new FlxTimer().start(2, function(tmr:FlxTimer){FlxG.switchState(new MenuState());});


        super.create();
    }
}