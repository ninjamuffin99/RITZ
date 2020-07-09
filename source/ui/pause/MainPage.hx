package ui.pause;

import data.PlayerSettings;
import states.PlayState;
import ui.pause.PauseSubstate;

import flixel.FlxG;

class MainPage extends PausePage
{
    final settings:PlayerSettings;
    final navCallback:(PausePageType)->Void;
    final buttons:ButtonGroup;
    final title:BitmapText;
    
    public function new (settings:PlayerSettings, navCallback:(PausePageType)->Void)
    {
        this.navCallback = navCallback;
        this.settings = settings;
        buttons = new ButtonGroup(settings.controls);
        super();
        
        title = new BitmapText(32, 4, "PAUSED");
        title.x = (settings.camera.width - title.width) / 2;
        add(title);
        
        inline function addButton(text, callback)
        {
            var button:BitmapText;
            button = buttons.addNewButton(0, 0, text, callback);
            button.y += (buttons.length - 1) * button.lineHeight;
            button.x = (settings.camera.width - button.width) / 2;
            return button;
        }
        
        addButton("CONTINUE", navCallback.bind(Ready));
        addButton("MUTE", ()->FlxG.sound.muted = !FlxG.sound.muted);
        addButton("CONTROLS", navCallback.bind(Controls));
        if (PlayerSettings.numAvatars == 1)
        {
            var button:BitmapText = null;
            button = addButton("ADD PLAYER", ()->
                {
                    buttons.disableButton(button);
                    buttons.selected = 0;
                    addPlayer();
                }
            );
        }
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
    
    override function redraw()
    {
        title.x = (settings.camera.width - title.width) / 2;
        for (button in buttons.members)
            button.x = (settings.camera.width - button.width) / 2;
    }
    
    function addPlayer():Void
    {
        final totalDevices = DeviceManager.totalDevices();
        if (totalDevices == 1)
            PlayerSettings.player1.setKeyboardScheme(Duo(true));
        
        cast (FlxG.state, PlayState).createSecondPlayer();
        navCallback(Controls);
        
        if (totalDevices > 1)
            DeviceManager.requestAlert(P1);
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
    
    override function awaitingInput():Bool
    {
        return !buttons.active;
    }
    
    override function allowUnpause():Bool
    {
        return !buttons.active;
    }
}