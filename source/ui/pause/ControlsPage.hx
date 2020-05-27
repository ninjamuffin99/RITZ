package ui.pause;

import data.PlayerSettings;
import ui.pause.PauseSubstate;

class ControlsPage extends PausePage
{
    final settings:PlayerSettings;
    final inputs:ButtonGroup;
    
    public function new(settings:PlayerSettings, navCallback:(PausePageType)->Void)
    {
        this.settings = settings;
        super();
        
        var title = new BitmapText(32, 4, "CONTROLS");
        title.x = (settings.camera.width - title.width) / 2;
        title.scrollFactor.set();
        add(title);
        
        inputs = new ButtonGroup(0, settings.controls, false);
        inline function addInput(text, callback)
        {
            var button:BitmapText;
            button = inputs.addNewButton(0, 0, text, callback);
            button.y += (inputs.length - 1) * button.lineHeight;
            button.x = (settings.camera.width - button.width) / 2;
            button.scrollFactor.set();
        }
        
        addInput("BACK", navCallback.bind(Main));
        inputs.y = title.y + title.lineHeight * 2;
    }
}
/*
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
*/