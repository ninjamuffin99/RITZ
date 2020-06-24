package states;

import data.PlayerSettings;

import flixel.util.FlxTimer;
import flixel.FlxG;
import flixel.system.FlxSoundGroup;
import flixel.text.FlxText;
import flixel.FlxState;

class BootState extends FlxState
{
    inline public static var soundEXT = #if desktop ".ogg" #else ".mp3" #end;
    override function create() 
    {
        PlayerSettings.init();
        
        #if SKIP_TO_PLAYSTATE
        FlxG.switchState(new AdventureState());
        #else
        startIntro();
        #end
        
        super.create();
    }
    
    @:keep// So menustate code is always checked for errors
    public function startIntro():Void
    {
        var daText:FlxText = new FlxText(0, 0, 0, "ninjamuffin99\nMKMaffo\nKawaisprite\nand Digimin\npresent...", 16);
        daText.alignment = CENTER;
        daText.screenCenter();
        add(daText);
        
        FlxG.sound.play('assets/sounds/checkpoint' + soundEXT, 0.6);
        
        new FlxTimer().start(2, function(tmr:FlxTimer){FlxG.switchState(new MenuState());});
    }
}