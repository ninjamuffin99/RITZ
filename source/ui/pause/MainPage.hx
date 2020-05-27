package ui.pause;

import data.PlayerSettings;
import states.PlayState;
import ui.pause.PauseSubstate;

import flixel.FlxG;

class MainPage extends PausePage
{
    final buttons:ButtonGroup;
    final settings:PlayerSettings;
    final navCallback:(PausePageType)->Void;
    
    public function new (settings:PlayerSettings, navCallback:(PausePageType)->Void)
    {
        this.navCallback = navCallback;
        this.settings = settings;
        buttons = new ButtonGroup(0, settings.controls, false);
        super();
        
        var title = new BitmapText(32, 4, "PAUSED");
        title.x = (settings.camera.width - title.width) / 2;
        title.scrollFactor.set();
        add(title);
        
        inline function addButton(text, callback)
        {
            var button:BitmapText;
            button = buttons.addNewButton(0, 0, text, callback);
            button.y += (buttons.length - 1) * button.lineHeight;
            button.x = (settings.camera.width - button.width) / 2;
            button.scrollFactor.set();
            return button;
        }
        
        addButton("CONTINUE", navCallback.bind(Ready));
        addButton("MUTE", ()->FlxG.sound.muted = !FlxG.sound.muted);
        addButton("CONTROLS", navCallback.bind(Controls));
        if (PlayerSettings.numAvatars == 1)
            addButton("ADD PLAYER", ()->
                {
                    cast (FlxG.state, PlayState).createSecondPlayer();
                    navCallback(Ready);
                }
            );
        else if (settings.id > 0)
        {
            var button = addButton("REMOVE PLAYER", ()->
                {
                    cast (FlxG.state, PlayState).removeSecondPlayer(settings.avatar);
                    navCallback(Ready);
                }
            );
        }
        addButton("RESTART", onSelectRestart);
        buttons.y = title.y + title.lineHeight * 2;
        add(buttons);
    }
    
    function removePlayer():Void
    {
    }
    
    function onSelectRestart():Void
    {
        buttons.active = false;
        var prompt = new Prompt(settings.controls);
        add(prompt);
        prompt.setup
            ( "Restart game?\n(Lose all progress)"
            , FlxG.resetState
            , ()->buttons.active = true
            , remove.bind(prompt)
            );
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        if (settings.controls.BACK)
            navCallback(Ready);
    }
    
    override function allowUnpause():Bool
    {
        return buttons.active;
    }
}