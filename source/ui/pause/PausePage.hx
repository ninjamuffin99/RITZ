package ui.pause;

import ui.BitmapText;

import flixel.FlxG;
import flixel.group.FlxGroup;

class PausePage extends FlxGroup
{
    public function new(maxSize:Int = 0)
    {
        super(maxSize);
    }
    
    public function allowUnpause() return true;
    
    override function revive()
    {
        super.revive();
        
        redraw();
    }
    
    public function redraw():Void {}
}

abstract ReadyPage(PausePage) to PausePage
{
    public function new ()
    {
        this = new PausePage(1);
        
        var title = new BitmapText(0, 4, "Waiting for player");
        title.x = (FlxG.camera.width - title.width) / 2;
        title.y = (FlxG.camera.height - title.height) / 2;
        title.scrollFactor.set();
        this.add(title);
    }
}