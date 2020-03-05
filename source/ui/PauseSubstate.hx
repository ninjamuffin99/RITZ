package ui;

import flixel.FlxG;

class PauseSubstate extends flixel.FlxSubState
{
    var pauseReleased = false;
    var buttons:ButtonGroup = new ButtonGroup(3, false);
    
    public function new ()
    {
        super();
        
        var title = new BitmapText(0, 24, "PAUSED");
        title.screenCenter(X);
        title.scrollFactor.set();
        add(title);
        
        buttons.y = title.y + title.height * 2;
        addButton("CONTINUE", close);
        addButton("MUTE", ()->FlxG.sound.muted = !FlxG.sound.muted);
        addButton("RESTART", onSelectRestart);
        add(buttons);
    }
    
    inline function addButton(text, callback)
    {
        var button:BitmapText;
        button = buttons.addNewButton(0, 20 * buttons.length, text, callback);
        button.screenCenter(X);
        button.scrollFactor.set();
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        if (Inputs.justReleased.PAUSE)
            pauseReleased = true;
        
        if (Inputs.justPressed.BACK || (Inputs.pressed.PAUSE && pauseReleased))
            close();
    }
    
    function onSelectRestart():Void
    {
        buttons.active = false;
        var prompt = new Prompt();
        add(prompt);
        prompt.setup
            ( "Restart game?\n(Lose all progress)"
            , FlxG.resetState
            , ()->buttons.active = true
            , remove.bind(prompt)
            );
    }
}