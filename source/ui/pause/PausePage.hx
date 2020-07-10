package ui.pause;

import ui.BitmapText;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;

class PausePage extends FlxGroup
{
    public function new(maxSize:Int = 0)
    {
        super(maxSize);
    }
    
    public function allowUnpause() return false;
    
    public function awaitingInput() return false;
    
    override function kill()
    {
        // super.kill();
        
        alive = false;
        exists = false;
    }
    
    override function revive()
    {
        // super.revive();
        
        alive = true;
        exists = true;
        
        redraw();
    }
    
    public function redraw():Void {}
}

class ReadyPage extends PausePage
{
    public function new ()
    {
        super(1);
        
        var title = new BitmapText(0, 4, "Waiting for player");
        title.x = (FlxG.camera.width - title.width) / 2;
        title.y = (FlxG.camera.height - title.height) / 2;
        title.scrollFactor.set();
        add(title);
    }
    
    override function redraw()
    {
        super.redraw();
        var title:FlxSprite = cast members[0];
        title.x = (FlxG.camera.width - title.width) / 2;
    }
}