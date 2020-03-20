package ui;

import ui.BitmapText;
import ui.Inputs;

import flixel.FlxG;
import flixel.text.FlxText;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;

class PauseSubstate extends flixel.FlxSubState
{
    var pauseReleased = false;
    var buttons:ButtonGroup = new ButtonGroup(3, false);
    
    public function new ()
    {
        super();
        
        var title = new BitmapText(0, 4, "PAUSED");
        title.screenCenter(X);
        title.scrollFactor.set();
        add(title);
        
        inline function addButton(text, callback)
        {
            var button:BitmapText;
            button = buttons.addNewButton(0, 0, text, callback);
            button.y += (buttons.length - 1) * button.lineHeight;
            button.screenCenter(X);
            button.scrollFactor.set();
        }
        
        addButton("CONTINUE", close);
        addButton("MUTE", ()->FlxG.sound.muted = !FlxG.sound.muted);
        addButton("RESTART", onSelectRestart);
        buttons.y = title.y + title.lineHeight * 2;
        add(buttons);
        
        var controls = new ControlsData();
        controls.add("Action", "Keyboard", "Gamepad");
        controls.add("------", "----------", "---------");
        controls.add("Move", "Arrows WASD", "D-Pad L-Stick");
        controls.addFromInput(ACCEPT);
        controls.addFromInput(BACK  );
        controls.addFromInput(JUMP  );
        controls.addFromInput(TALK  );
        controls.addFromInput(MAP   );
        controls.addFromInput(RESET );
        
        inline function addColumn()
        {
            var column = new BitmapText();
            column.scrollFactor.set();
            add(column);
            return column;
        }
        
        var actionsColumn = addColumn();
        var    keysColumn = addColumn();
        var buttonsColumn = addColumn();
        for (input in (controls:RawControlsData))
        {
            actionsColumn.text += input.action + "\n";
            keysColumn.text += input.keys + "\n";
            buttonsColumn.text += input.buttons + "\n";
        }
        // remove last \n
        actionsColumn.text = actionsColumn.text.substr(0, actionsColumn.text.length - 1);
           keysColumn.text =    keysColumn.text.substr(0,    keysColumn.text.length - 1);
        buttonsColumn.text = buttonsColumn.text.substr(0, buttonsColumn.text.length - 1);
        final gap = 32;
        final width = actionsColumn.width + gap + keysColumn.width + gap + buttonsColumn.width;
        // X margin
        var margin = (FlxG.width - width) / 2;
        actionsColumn.x = margin;
        keysColumn.x = actionsColumn.x + actionsColumn.width + gap;
        buttonsColumn.x = keysColumn.x + keysColumn.width + gap;
        // Y margin
        margin = (FlxG.height - (buttons.y + buttons.length * buttons.group.members[0].lineHeight + actionsColumn.height)) / 2;
        trace(margin, buttons.y + buttons.length * buttons.group.members[0].lineHeight);
        actionsColumn.y = FlxG.height - actionsColumn.height - margin;
           keysColumn.y = FlxG.height -    keysColumn.height - margin;
        buttonsColumn.y = FlxG.height - buttonsColumn.height - margin;
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        if (Inputs.justReleased.PAUSE)
            pauseReleased = true;
        
        if (buttons.active && (Inputs.justPressed.BACK || (Inputs.pressed.PAUSE && pauseReleased)))
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

typedef RawControlsData = Array<{ action:String, keys:String, buttons:String }>;

@:forward
abstract ControlsData(RawControlsData) from RawControlsData to RawControlsData
{
    inline public function new () this = [];
    
    inline public function add(action, keys, buttons)
        this.push({ action:action, keys:keys, buttons:buttons });
    
    inline public function addFromInput(input:Input, name:String = null)
    {
        this.push(
            { action : name == null ? toTitleCase(input.getName()) : name
            , keys   : keysTitleCase(input)
            , buttons: buttonsTitleCase(input)
            }
        );
    }
    
    inline function keysTitleCase(input:Input)
    {
        var strList = "";
        var list = Inputs.getKeys(input);
        for (i in 0...list.length)
        {
            strList += toTitleCase(list[i]);
            if (i < list.length)
                strList += " ";
        }
        return strList;
    }
    
    inline function buttonsTitleCase(input:Input)
    {
        var strList = "";
        var list = Inputs.getPadButtons(input);
        for (i in 0...list.length)
        {
            strList += toTitleCase(list[i]);
            if (i < list.length)
                strList += " ";
        }
        return strList;
    }
    
    inline function toTitleCase(str:String)
    {
        return str.charAt(0) + str.substr(1).toLowerCase();
    }
}