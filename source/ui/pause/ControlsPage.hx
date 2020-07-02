package ui.pause;

import data.PlayerSettings;
import ui.BitmapText;
import ui.Controls;
import ui.MouseButtonGroup;
import ui.Prompt;
import ui.pause.PauseSubstate;
import utils.SpriteEffects;

import flixel.FlxG;
import flixel.FlxCamera;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

using flixel.util.FlxStringUtil;

class ControlsPage extends PausePage
{
    final settings:PlayerSettings;
    final navCallback:(PausePageType)->Void;
    
    final title:BitmapText;
    var deviceList:ButtonGroup;
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
    }
    
    function firstDraw()
    {
        final hasKeys = settings.controls.keyboardScheme != None;
        final numDevices = settings.controls.gamepadsAdded.length + (hasKeys ? 1 : 0);
        if (numDevices == 1)
        {
            if (!hasKeys)
                showDevice(Gamepad(settings.controls.gamepadsAdded[0]), false);
            else
                showDevice(Keys, false);
        }
        else
        {
            add(deviceList = new ButtonGroup(settings.controls));
            deviceList.y = title.y + title.lineHeight + 8;
            deviceList.keysNext = RIGHT_P;
            deviceList.keysPrev = LEFT_P;
            
            var nextX = 0.0;
            if (settings.controls.keyboardScheme != None)
            {
                final button = deviceList.addNewButton(0, 0, "KEYS", onDeviceSelect.bind(Keys));
                nextX += button.width * 1.25;
            }
            
            for (id in settings.controls.gamepadsAdded)
            {
                final name = getPadName(FlxG.gamepads.getByID(id).name).toUpperCase();
                final button = deviceList.addNewButton(nextX, 0, name, onDeviceSelect.bind(Gamepad(id)));
                nextX += button.width * 1.25;
            }
            
            deviceList.x = (settings.camera.width - deviceList.width) / 2;
        }
    }
    
    function getPadName(name:String):String
    {
        name = name.toLowerCase().remove("-").remove("_");
        return if (name.contains("ouya"))
                "Ouya"; // "OUYA Game Controller"
            else if (name.contains("wireless controller") || name.contains("ps4"))
                "PS4"; // "Wireless Controller" or "PS4 controller"
            else if (name.contains("logitech"))
                "Logi";
            else if (name.contains("xbox"))
                "XBox"
            else if (name.contains("xinput"))
                "XInput";
            else if (name.contains("nintendo rvlcnt01tr") || name.contains("nintendo rvlcnt01"))
                "Wii"; // WiiRemote w/o  motion plus
            else if (name.contains("mayflash wiimote pc adapter"))
                "Wii"; // WiiRemote paired to MayFlash DolphinBar (with or w/o motion plus)
            else if (name.contains("pro controller"))
                "Pro_Con";
            else if (name.contains("joycon l+r"))
                "Joycons";
            else if (name.contains("joycon (l)"))
                "Joycon_L";
            else if (name.contains("joycon (r)"))
                "Joycon_R";
            else if (name.contains("mfi"))
                "MFI";
            else
                "Pad";
    }
    
    function onDeviceSelect(device:Device)
    {
        FlxTween.tween(deviceList.members[deviceList.selected].scale, {x:1.2, y:1.2}, 0.25, { ease:FlxEase.backOut });
        showDevice(device, true);
    }
    
    override function redraw()
    {
        title.x = (settings.camera.width - title.width) / 2;
        
        if (device == null && deviceList == null)
            firstDraw();
        else if (device != null)
            showDevice(device, false);
    }
    
    override function kill()
    {
        super.kill();
        FlxG.mouse.visible = false;
        FlxG.mouse.useSystemCursor = true;
    }
    
    function showDevice(device:Device, animateIn:Bool):Void
    {
        if (devicePage == null)
        {
            add(devicePage = new DevicePage(settings));
            // add to bottom
            if (deviceList != null)
                devicePage.y = deviceList.y + deviceList.height + 8;
            else
                devicePage.y = title.y + title.lineHeight + 2;
        }
        else
            devicePage.revive();
        
        this.device = device;
        devicePage.showDeviceControls(settings.controls, device, animateIn);
        devicePage.x = (settings.camera.width - devicePage.width) / 2;
        
        if (deviceList != null)
            deviceList.active = false;
        
        FlxG.mouse.visible = true;
        FlxG.mouse.useSystemCursor = false;
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        if (deviceList == null || deviceList.active)
        {
            if (!getControlsBlocked() && settings.controls.BACK)
                navCallback(Main);
        }
        else if (devicePage != null && devicePage.exists && devicePage.hideRequested)
            hideDevicePage();
    }
    
    function hideDevicePage()
    {
        FlxTween.tween(deviceList.members[deviceList.selected].scale, {x:1, y:1}, 0.25, { ease:FlxEase.backIn });
        devicePage.hide(true);
        deviceList.active = true;
    }
    
    override function allowUnpause() return !getControlsBlocked();
    
    inline function getControlsBlocked() return devicePage != null && devicePage.alive && devicePage.blockingParentKeys;
}

private typedef ButtonData = { button:MouseButton, control:Control, ?id:Int};
private class DevicePage extends FlxSpriteGroup
{
    static final allControls = Control.createAll();
    
    var inputs:InputGrid;
    var controlNames = new Array<BitmapText>();
    var buttonMap = new Array<Array<ButtonData>>();
    var settings:PlayerSettings;
    var currentDevice:Device;
    var prompt = new InputSelectionPrompt();
    
    var fullWidth:Float = 0;
    override function get_width() return fullWidth;
    
    public var hideRequested(default, null) = false;
    public var blockingParentKeys(get, never):Bool;
    inline function get_blockingParentKeys():Bool return !isValidSetup || blockingKeys;
    var blockingKeys(get, never):Bool;
    inline function get_blockingKeys():Bool return prompt.alive;
    
    var isValidSetup = true;
    
    public function new (settings:PlayerSettings)
    {
        this.settings = settings;
        super();
        
        final startY = 8;
        final gap = 1;
        final buttonHeight = 14;
        var controlsRight = 0.0;
        for(i=>control in allControls)
        {
            var controlName = new Nokia8Text(0, 0, control.getName());
            add(controlName);
            controlNames.push(controlName);
            controlName.y += startY + i * (buttonHeight + gap);
            if (controlsRight < controlName.x + controlName.width)
                controlsRight = controlName.x + controlName.width;
        }
        
        inputs = new InputGrid(settings.controls);
        add(inputs);
        inputs.x = controlsRight + 8;
        final buttonWidth = 23;
        final spacing = buttonWidth + gap;
        for(i in 0...allControls.length)
        {
            buttonMap.push([]);
            for (j in 0...4)
            {
                var button = inputs.addNewButton(j * spacing, members[i].y, " ");
                button.y -= button.labelOffsets[0].y;//match text
                var data = { control:allControls[i], button:button };
                inputs.setCallback(button, onInputSelect.bind(data));
                buttonMap[i].push(data);
            }
        }
        fullWidth = super.get_width();
        
        add(prompt).kill();
    }
    
    override function kill() exists = alive = false;
    override function revive() exists = alive = true;
    override function set_exists(value:Bool):Bool return this.exists = value;
    override function set_alive(value:Bool):Bool return this.alive = value;
    
    public function showDeviceControls(controls:Controls, device:Device, animateIn:Bool)
    {
        hideRequested = false;
        isValidSetup = true;
        var format = InputFormatter.format.bind(_, device);
        
        currentDevice = device;
        var list:Array<Int> = [];
        var inputsX = 0;
        for(i=>control in allControls)
        {
            list.resize(0);
            list = controls.getInputsFor(control, device, list);
            for (j=>buttonData in buttonMap[i])
            {
                buttonData.id = list[j];
                buttonData.button.text = list.length > j ? format(list[j]) : " ";
            }
        }
        
        if (animateIn)
        {
            inputs.active = false;
            scale.x = scale.y = 0.01;
            SpriteEffects.scaleToInTime(this, 1, 0.25, ()->inputs.active = true);
        }
    }
    
    public function hide(animateOut:Bool)
    {
        hideRequested = false;
        if (animateOut)
        {
            inputs.active = false;
            scale.x = scale.y = 1;
            FlxTween.tween(this,
                { "scale.x":0.01, "scale.y":0.01 },
                0.25,
                {
                    ease:FlxEase.backIn,
                    onComplete:(_)->
                    {
                        inputs.active = true;
                        kill();
                    }
                }
            );
        }
        else
            kill();
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        if (!blockingKeys)
        {
            if (settings.controls.RESET)
            {
                var data = buttonMap[Math.floor(inputs.selected / inputs.columns)][inputs.selected % inputs.columns];
                replaceBinding(data, null);
            }
            
            if (isValidSetup)
            {
                if (settings.controls.BACK)
                    hideRequested = isValidSetup;
            }
            else if (settings.controls.BACK || settings.controls.PAUSE)
            {
                function showAnim(control)
                {
                    var text = controlNames[allControls.indexOf(control)];
                    if (text.borderColor == BitmapText.DEFAULT_BORDER_COLOR)
                    {
                        text.borderColor = 0xFFac3232;
                        SpriteEffects.wiggleX(text, 4, 0.25, ()->text.borderColor = BitmapText.DEFAULT_BORDER_COLOR);
                    }
                }
                
                if (settings.controls.getInputsFor(ACCEPT, currentDevice).length == 0)
                    showAnim(ACCEPT);
                
                if (settings.controls.getInputsFor(BACK, currentDevice).length == 0)
                    showAnim(BACK);
                
                if (settings.controls.getInputsFor(PAUSE, currentDevice).length == 0)
                    showAnim(PAUSE);
            }
        }
    }
    
    function onInputSelect(data:ButtonData):Void
    {
        inputs.active = false;
        
        prompt.revive();
        prompt.show(currentDevice, 
            function(?inputId)
            {
                if (inputId != null)
                {
                    for (buttonData in buttonMap[data.control.getIndex()])
                    {
                        if (data != buttonData && buttonData.id == inputId)
                        {
                            inputId = null;
                            break;
                        }
                    }
                }
                replaceBinding(data, inputId);
                prompt.kill();
                inputs.active = true;
            }
        );
    }
    
    function replaceBinding(data:ButtonData, inputId:Null<Int>)
    {
        if (inputId != null)
        {
            // Don't allow ACCEPT and BACK to share an input
            if (data.control == ACCEPT)
                removeInputFromControl(BACK, inputId);
            else if (data.control == BACK)
                removeInputFromControl(ACCEPT, inputId);
        }
        
        settings.controls.replaceBinding(data.control, currentDevice, inputId, data.id);
        
        var newText = inputId == null ? " " : InputFormatter.format(inputId, currentDevice);
        if ((data.button.text == " ") != (newText == " "))
        {
            // disappearing/reappearing text anim
            var scale = inputId == null ? 0 : data.button.scale.x;
            var options:TweenOptions = { ease:inputId == null ? FlxEase.backIn : FlxEase.backOut };
            if (newText == " ")
                options.onComplete = (_)->data.button.text = newText;
            else
            {
                data.button.label.scale.set();
                data.button.text = newText;
            }
            FlxTween.tween(data.button.label.scale, { x:scale, y:scale }, 0.1, options);
        }
        else
            data.button.text = newText;
        
        data.id = inputId;
        
        checkValidSetup();
    }
    
    function removeInputFromControl(control, inputId:Int)
    {
        final buttonIndex = settings.controls.getInputsFor(control, currentDevice).indexOf(inputId);
        final controlIndex = allControls.indexOf(control);
        if (buttonIndex != -1)
            replaceBinding(buttonMap[controlIndex][buttonIndex], null); // remove binding
    }
    
    public function checkValidSetup()
    {
        isValidSetup
            =  settings.controls.getInputsFor(ACCEPT, currentDevice).length > 0
            && settings.controls.getInputsFor(BACK  , currentDevice).length > 0
            && settings.controls.getInputsFor(PAUSE , currentDevice).length > 0
            ;
    }
}

private class InputGrid extends MouseButtonGroup
{
    public var columns(default, null):Int;
    public function new (controls, columns = 4)
    {
        this.columns = columns;
        super(controls, InputGrid);
        
        selectFlickerTime = 0.25;
    }
    
    override function checkKeys(elapsed:Float):Void
    {
        var newSelected = selected;
        if (keysNext != null && controls.RIGHT_P)
        {
            do
            {
                if ((newSelected + 1) % columns == 0)
                    newSelected -= columns - 1;
                else
                    newSelected++;
            }
            while(members[newSelected] == null || isDisabled(members[newSelected]));
        }
        
        if (keysPrev != null && controls.LEFT_P)
        {
            do
            {
                if ((newSelected % columns) == 0)
                    newSelected += columns - 1;
                else
                    newSelected--;
            }
            while(members[newSelected] == null || isDisabled(members[newSelected]));
        }
        
        if (keysNext != null && controls.DOWN_P)
        {
            do
            {
                if (newSelected + columns > members.length - 1)
                    newSelected -= members.length;
                
                newSelected += columns;
            }
            while(members[newSelected] == null || isDisabled(members[newSelected]));
        }
        
        if (keysPrev != null && controls.UP_P)
        {
            do
            {
                if (newSelected - columns < 0)
                    newSelected += members.length;
                
                newSelected -= columns;
            }
            while(members[newSelected] == null || isDisabled(members[newSelected]));
        }
        
        if (selected != newSelected)
            selected = newSelected;
        
        if (keysSelect != null && controls.checkByName(keysSelect))
            onSelect();
        
        if (keysBack != null && controls.checkByName(keysBack) && onBack != null)
            onBack();
    }
}

private class InputSelectionPrompt extends FlxSpriteGroup
{
    inline static var BUFFER = 12;
    
    // public final button = new MouseButton(;
    final bg = new Prompt.BgSprite();
    final label = new BitmapText();
    final button:MouseButton;
    var inputCheck:()->Int = null;
    var callback:(Null<Int>)->Void = null;
    
    public function new ()
    {
        button = new MouseButton(0, 0, "CLEAR", Orange8, hide.bind(null));
        super();
        
        add(bg);
        add(label);
        label.alignment = CENTER;
        add(button);
    }
    
    override function kill() exists = alive = false;
    override function revive() exists = alive = true;
    override function set_exists(value:Bool):Bool return this.exists = value;
    override function set_alive(value:Bool):Bool return this.alive = value;
    
    public function show(device:Device, callback:(Null<Int>)->Void)
    {
        revive();
        label.text = "Press any " + (device == Device.Keys ? "key" : "button");
        this.callback = callback;
        inputCheck = switch (device)
        {
            case Keys: FlxG.keys.firstJustReleased;
            case Gamepad(id): FlxG.gamepads.getByID(id).firstJustReleasedID;
        }
        
        bg.setSize
            ( Std.int(label.width ) + BUFFER * 2
            , Std.int(label.height) + label.lineHeight + BUFFER * 2
            );
        bg.x = (FlxG.camera.width - bg.width) / 2;
        bg.y = (FlxG.camera.height - bg.height) / 2;
        
        label.x = bg.x + Math.floor((bg.width - label.width) / 2);
        label.y = bg.y + BUFFER;
        
        button.x = bg.x + (bg.width - button.width) / 2;
        button.y = bg.y + bg.height - button.height - BUFFER;
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        var firstReleased = inputCheck();
        if (firstReleased != -1)
            hide(firstReleased);
    }
    
    function hide(response:Null<Int>):Void
    {
        if (callback == null)
            throw "button clicked when hidden";
        
        inputCheck = null;
        var func = callback;
        callback = null;
        
        func(response);
    }
}