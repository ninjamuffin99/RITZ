package ui.pause;

import flixel.input.keyboard.FlxKey;
import data.PlayerSettings;
import ui.BitmapText;
import ui.ButtonGroup;
import ui.Controls;
import ui.pause.PauseSubstate;

import flixel.group.FlxSpriteGroup;

class ControlsPage extends PausePage
{
    final settings:PlayerSettings;
    final navCallback:(PausePageType)->Void;
    
    final title:BitmapText;
    final devices:ButtonGroup;
    var devicePage:DevicePage;
    var device:Device = null;
    
    public function new(settings:PlayerSettings, navCallback:(PausePageType)->Void)
    {
        this.settings = settings;
        this.navCallback = navCallback;
        super();
        
        title = new BitmapText(32, 4, "CONTROLS");
        title.x = (settings.camera.width - title.width) / 2;
        add(title);
        
        final hasKeys = settings.controls.keyboardScheme != None;
        final numDevices = settings.controls.gamepadsAdded.length + (hasKeys ? 1 : 0);
        if (numDevices == 1)
        {
            if (!hasKeys)
                showDevice(Gamepad(settings.controls.gamepadsAdded[0]));
            else
                showDevice(Keys);
        }
        else
        {
            add(devices = new ButtonGroup(0, settings.controls, false));
            
            if (settings.controls.keyboardScheme != None)
                devices.addNewButton(devices.width, 0, "KEYS", showDevice.bind(Keys));
            
            for (id in settings.controls.gamepadsAdded)
                devices.addNewButton(devices.width, 0, 'PAD $id', showDevice.bind(Gamepad(id)));
            
            devices.x = (settings.camera.width - devices.width) / 2;
        }
    }
    
    override function revive()
    {
        super.revive();
        
        title.x = (settings.camera.width - title.width) / 2;
        
        if (device != null)
            showDevice(device);
    }
    
    function showDevice(device:Device):Void
    {
        if (devicePage == null)
        {
            add(devicePage = new DevicePage(settings));
            // add to bottom
            if (devices != null)
                devicePage.y = devices.y + devices.height + 8;
            else
                devicePage.y = title.y + title.lineHeight + 2;
        }
        
        this.device = device;
        devicePage.showDeviceControls(settings.controls, device);
        devicePage.x = (settings.camera.width - devicePage.width) / 2;
        
        if (devices != null)
            devices.active = false;
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        if (settings.controls.BACK)
        {
            if (devices == null || devices.active)
                navCallback(Main);
            else
            {
                devicePage.kill();
                devices.active = true;
            }
        }
    }
}

class DevicePage extends FlxSpriteGroup
{
    static final allControls = Control.createAll();
    
    var controlNames:ButtonGroup;
    var buttonMap = new Array<BitmapText>();
    
    public function new (settings:PlayerSettings)
    {
        super();
        
        add(controlNames = new ButtonGroup(0, settings.controls, false));
        for(i=>control in allControls)
        {
            var button = controlNames.addNewButton(0, 0, control.getName(), onControlSelect.bind(i));
            button.y += i * button.lineHeight;
        }
        
        for(i in 0...allControls.length)
        {
            var inputs = new BitmapText(controlNames.x + controlNames.width, controlNames.members[i].y);
            buttonMap[i] = inputs;
            add(inputs);
        }
    }
    
    public function showDeviceControls(controls:Controls, device:Device)
    {
        var list:Array<String> = [];
        var inputsX = 0;
        for(i=>control in allControls)
        {
            list = controls.getInputsFor(control, device, list);
            var buttons = buttonMap[i].text = " - " + list.map(shortenInput).join(" ");
            list.resize(0);
        }
    }
    
    function onControlSelect(index:Int)
    {
    }
    
    static function shortenInput(input:String):String
    {
        if (FlxKey.fromStringMap.exists(input))
        {
            return switch(FlxKey.fromStringMap[input])
            {
                case ZERO          : "0";
                case ONE           : "1";
                case TWO           : "2";
                case THREE         : "3";
                case FOUR          : "4";
                case FIVE          : "5";
                case SIX           : "6";
                case SEVEN         : "7";
                case EIGHT         : "8";
                case NINE          : "9";
                case PAGEUP        : "PgUp";
                case PAGEDOWN      : "PgDn";
                case HOME          : "Home";
                case END           : "End";
                case INSERT        : "Insert";
                case ESCAPE        : "Esc";
                case MINUS         : "-";
                case PLUS          : "+";
                case DELETE        : "Del";
                case BACKSPACE     : "BckSpc";
                case LBRACKET      : "[";
                case RBRACKET      : "]";
                case BACKSLASH     : "\\";
                case CAPSLOCK      : "Caps";
                case SEMICOLON     : ";";
                case QUOTE         : "'";
                case ENTER         : "Ent";
                case SHIFT         : "Shift";
                case COMMA         : ",";
                case PERIOD        : ".";
                case SLASH         : "/";
                case GRAVEACCENT   : "`";
                case CONTROL       : "Ctrl";
                case ALT           : "Alt";
                case SPACE         : "Spc";
                case UP            : "Up";
                case DOWN          : "Down";
                case LEFT          : "Left";
                case RIGHT         : "Right";
                case TAB           : "Tab";
                case PRINTSCREEN   : "PrtScn";
                case NUMPADZERO    : "#0";
                case NUMPADONE     : "#1";
                case NUMPADTWO     : "#2";
                case NUMPADTHREE   : "#3";
                case NUMPADFOUR    : "#4";
                case NUMPADFIVE    : "#5";
                case NUMPADSIX     : "#6";
                case NUMPADSEVEN   : "#7";
                case NUMPADEIGHT   : "#8";
                case NUMPADNINE    : "#9";
                case NUMPADMINUS   : "#-";
                case NUMPADPLUS    : "#+";
                case NUMPADPERIOD  : "#.";
                case NUMPADMULTIPLY: "#*";
                default: input;
            }
        }
        return input;
    }
}