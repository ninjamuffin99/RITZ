package ui;

import flixel.FlxG;
import flixel.input.FlxInput;
import flixel.input.actions.FlxAction;
import flixel.input.actions.FlxActionInput;
import flixel.input.actions.FlxActionManager;
import flixel.input.actions.FlxActionSet;
import flixel.input.gamepad.FlxGamepadButton;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;

enum abstract Action(String) to String from String
{
    var JUMP       = "jump";
    var JUMP_P     = "jump-press";
    var JUMP_R     = "jump-release";
    var LEFT       = "left";
    var RIGHT      = "right";
    var DOWN       = "down";
    var TALK       = "talk";
    var MENU_UP    = "menuUp";
    var MENU_DOWN  = "menuDown";
    var MENU_LEFT  = "menuLeft";
    var MENU_RIGHT = "menuRight";
    var ACCEPT     = "accept";
    var BACK       = "back";
    var MAP        = "map";
    var PAUSE      = "pause";
    var RESET      = "reset";
}

/**
 * Since, in many cases multiple actions should use similar keys, we don't want the
 * rebinding UI to list every action. ActionBinders are what the user percieves as
 * an input so, for instance, they can't set jump-press and jump-release to different keys.
 */
enum Control
{
    UP;
    LEFT;
    RIGHT;
    DOWN;
    JUMP;
    TALK;
    RESET;
    ACCEPT;
    BACK;
    PAUSE;
    MAP;
}

enum ControlsType
{
    Solo;
    Duo(first:Bool);
    Custom;
}

/**
 * A list of actions that a player would invoke via some input device.
 * Uses FlxActions to funnel various inputs to a single action.
 */
class Controls extends FlxActionSet
{
    static public var solo(get, null):Controls;
    static public var duo1(get, null):Controls;
    static public var duo2(get, null):Controls;
    
    var _jump      = new FlxActionDigital("jump");
    var _jumpP     = new FlxActionDigital("jump-press");
    var _jumpR     = new FlxActionDigital("jump-release");
    var _left      = new FlxActionDigital("left");
    var _right     = new FlxActionDigital("right");
    var _down      = new FlxActionDigital("down");
    var _talk      = new FlxActionDigital("talk");
    var _menuUp    = new FlxActionDigital("menuUp");
    var _menuDown  = new FlxActionDigital("menuDown");
    var _menuLeft  = new FlxActionDigital("menuLeft");
    var _menuRight = new FlxActionDigital("menuRight");
    var _accept    = new FlxActionDigital("accept");
    var _back      = new FlxActionDigital("back");
    var _map       = new FlxActionDigital("map");
    var _pause     = new FlxActionDigital("pause");
    var _reset     = new FlxActionDigital("reset");
    
    var byName:Map<String, FlxActionDigital> = [];
    
    public var JUMP       (get, never):Bool; inline function get_JUMP       () return _jump     .check();
    public var JUMP_P     (get, never):Bool; inline function get_JUMP_P     () return _jumpP    .check();
    public var JUMP_R     (get, never):Bool; inline function get_JUMP_R     () return _jumpR    .check();
    public var LEFT       (get, never):Bool; inline function get_LEFT       () return _left     .check();
    public var RIGHT      (get, never):Bool; inline function get_RIGHT      () return _right    .check();
    public var DOWN       (get, never):Bool; inline function get_DOWN       () return _down     .check();
    public var TALK       (get, never):Bool; inline function get_TALK       () return _talk     .check();
    public var MENU_UP    (get, never):Bool; inline function get_MENU_UP    () return _menuUp   .check();
    public var MENU_DOWN  (get, never):Bool; inline function get_MENU_DOWN  () return _menuDown .check();
    public var MENU_LEFT  (get, never):Bool; inline function get_MENU_LEFT  () return _menuLeft .check();
    public var MENU_RIGHT (get, never):Bool; inline function get_MENU_RIGHT () return _menuRight.check();
    public var ACCEPT     (get, never):Bool; inline function get_ACCEPT     () return _accept   .check();
    public var BACK       (get, never):Bool; inline function get_BACK       () return _back     .check();
    public var MAP        (get, never):Bool; inline function get_MAP        () return _map      .check();
    public var PAUSE      (get, never):Bool; inline function get_PAUSE      () return _pause    .check();
    public var RESET      (get, never):Bool; inline function get_RESET      () return _reset    .check();
    
    
    function new(name:String)
    {
        super("name");
        
        add(_jump);
        add(_jumpP);
        add(_jumpR);
        add(_left);
        add(_right);
        add(_down);
        add(_talk);
        add(_menuUp);
        add(_menuDown);
        add(_menuLeft);
        add(_menuRight);
        add(_accept);
        add(_back);
        add(_map);
        add(_pause);
        add(_reset);
        
        for (action in digitalActions)
            byName[action.name] = action;
    }
    
    // inline
    public function checkByName(name:Action):Bool
    {
        #if debug
        if (!byName.exists(name))
            throw 'Invalid name: $name';
        #end
        return byName[name].check();
    }
    
    public function getDialogueName(action:FlxActionDigital):String
    {
        var input = action.inputs[0];
        return switch input.device
        {
            case KEYBOARD: return '[${(input.inputID:FlxKey)}]';
            case GAMEPAD : return '(${(input.inputID:FlxGamepadInputID)})';
            case device: throw 'unhandled device: $device';
        }
    }
    
    public function getDialogueNameFromToken(inputName:String):String
    {
        inputName = inputName.toLowerCase();
        for (action in this.digitalActions)
        {
            if (action.name == inputName)
                return getDialogueName(action);
        }
        
        throw 'Unrecognised inputName:$inputName';
    }
    
    static function get_solo():Controls
    {
        if (solo == null)
            init();
        return solo;
    }
    
    static function get_duo1():Controls
    {
        if (duo1 == null)
            init();
        return duo1;
    }
    
    static function get_duo2():Controls
    {
        if (duo2 == null)
            init();
        return duo2;
    }
    
    static function init():Void
    {
        var actions = new FlxActionManager();
        FlxG.inputs.add(actions);
        
        /*
         * Inlining bindKeys calls with literal values will change them to a series of direct addKey calls.
         */
        solo = new Controls("solo");
        inline solo.bindKeys(ACCEPT, [Z, SPACE]);
        inline solo.bindKeys(BACK  , [X, ESCAPE]);
        inline solo.bindKeys(JUMP  , [Z, Y]);
        inline solo.bindKeys(UP    , [W, UP]);
        inline solo.bindKeys(DOWN  , [S, DOWN]);
        inline solo.bindKeys(LEFT  , [A, LEFT]);
        inline solo.bindKeys(RIGHT , [D, RIGHT]);
        inline solo.bindKeys(TALK  , [E, F, X]);
        inline solo.bindKeys(PAUSE , [P, ESCAPE, ENTER]);
        inline solo.bindKeys(MAP   , [M]);
        inline solo.bindKeys(RESET , [R]);
        actions.addSet(solo);
        
        duo1 = new Controls("duo1");
        inline duo1.bindKeys(ACCEPT, [G]);
        inline duo1.bindKeys(BACK  , [H]);
        inline duo1.bindKeys(JUMP  , [G]);
        inline duo1.bindKeys(UP    , [W]);
        inline duo1.bindKeys(DOWN  , [S]);
        inline duo1.bindKeys(LEFT  , [A]);
        inline duo1.bindKeys(RIGHT , [D]);
        inline duo1.bindKeys(TALK  , [H]);
        inline duo1.bindKeys(PAUSE , [ESCAPE, ONE]);
        inline duo1.bindKeys(MAP   , [TWO]);
        inline duo1.bindKeys(RESET , [R]);
        actions.addSet(duo1);
        
        duo2 = new Controls("duo2");
        inline duo2.bindKeys(ACCEPT, [O]);
        inline duo2.bindKeys(BACK  , [P]);
        inline duo2.bindKeys(JUMP  , [O]);
        inline duo2.bindKeys(UP    , [UP]);
        inline duo2.bindKeys(DOWN  , [DOWN]);
        inline duo2.bindKeys(LEFT  , [LEFT]);
        inline duo2.bindKeys(RIGHT , [RIGHT]);
        inline duo2.bindKeys(TALK  , [P]);
        inline duo2.bindKeys(PAUSE , [P, ENTER]);
        inline duo2.bindKeys(MAP   , [M]);
        inline duo2.bindKeys(RESET , [BACKSPACE]);
        actions.addSet(duo2);
    }
    
    /**
     * Calls a function passing each action bound by the specified control
     * @param control 
     * @param func 
     * @return ->Void)
     */
    function forEachBound(control:Control, func:(FlxActionDigital, FlxInputState)->Void)
    {
        switch (control)
        {
            case UP    :func(_menuUp   , JUST_PRESSED);
                        func(_jump     , PRESSED);
                        func(_jumpP    , JUST_PRESSED);
                        func(_jumpR    , JUST_RELEASED);
            case DOWN  :func(_down     , PRESSED);
                        func(_menuDown , JUST_PRESSED);
            case LEFT  :func(_left     , PRESSED);
                        func(_menuLeft , JUST_PRESSED);
            case RIGHT :func(_right    , PRESSED);
                        func(_menuRight, JUST_PRESSED);
            case JUMP  :func(_jump     , PRESSED);
                        func(_jumpP    , JUST_PRESSED);
                        func(_jumpR    , JUST_RELEASED);
            case TALK  :func(_talk     , JUST_PRESSED);
            case ACCEPT:func(_accept   , JUST_PRESSED);
            case BACK  :func(_back     , JUST_PRESSED);
            case MAP   :func(_map      , JUST_PRESSED);
            case PAUSE :func(_pause    , JUST_PRESSED);
            case RESET :func(_reset    , JUST_PRESSED);
        }
    }
    
    /**
     * Sets all actions that pertain to the binder to trigger when the supplied keys are used.
     * If binder is a literal you can inline this
     */
    public function bindKeys(control:Control, keys:Array<FlxKey>)
    {
        inline forEachBound(control, (action, state)->addKeys(action, keys, state));
    }
    
    /**
     * Sets all actions that pertain to the binder to trigger when the supplied keys are used.
     * If binder is a literal you can inline this
     */
    public function unbindKeys(control:Control, keys:Array<FlxKey>)
    {
        inline forEachBound(control, (action, _)->removeKeys(action, keys));
    }
    
    inline static function addKeys(action:FlxActionDigital, keys:Array<FlxKey>, state:FlxInputState)
    {
        for (key in keys)
            action.addKey(key, state);
    }
    
    static function removeKeys(action:FlxActionDigital, keys:Array<FlxKey>)
    {
        var i = action.inputs.length;
        while (i-- > 0)
        {
            var input = action.inputs[i];
            if (input.device == KEYBOARD && keys.indexOf(cast input.inputID) != -1)
                action.remove(input, true);
        }
    }
    
    public function addDefaultGamepad(id):Void
    {
        inline bindButtons(Control.ACCEPT, id, [A]);
        inline bindButtons(Control.BACK  , id, [B]);
        inline bindButtons(Control.UP    , id, [DPAD_UP   , LEFT_STICK_DIGITAL_UP]);
        inline bindButtons(Control.DOWN  , id, [DPAD_DOWN , LEFT_STICK_DIGITAL_DOWN]);
        inline bindButtons(Control.LEFT  , id, [DPAD_LEFT , LEFT_STICK_DIGITAL_LEFT]);
        inline bindButtons(Control.RIGHT , id, [DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT]);
        inline bindButtons(Control.JUMP  , id, [A]);
        inline bindButtons(Control.TALK  , id, [X]);
        inline bindButtons(Control.PAUSE , id, [START]);
        inline bindButtons(Control.MAP   , id, [GUIDE]);
        inline bindButtons(Control.RESET , id, [Y]);
    }
    
    public function removeAllGamepad(deviceID:Int = FlxInputDeviceID.ALL):Void
    {
        for (action in this.digitalActions)
        {
            var i = action.inputs.length;
            while (i-- > 0)
            {
                var input = action.inputs[i];
                if (input.device == GAMEPAD && (deviceID == FlxInputDeviceID.ALL || input.deviceID == deviceID))
                    action.remove(input, true);
            }
        }
    }
    
    /**
     * Sets all actions that pertain to the binder to trigger when the supplied keys are used.
     * If binder is a literal you can inline this
     */
    public function bindButtons(control:Control, id, buttons)
    {
        inline forEachBound(control, (action, state)->addButtons(action, buttons, state, id));
    }
    
    /**
     * Sets all actions that pertain to the binder to trigger when the supplied keys are used.
     * If binder is a literal you can inline this
     */
    public function unbindButtons(control:Control, buttons)
    {
        inline forEachBound(control, (action, _)->removeButtons(action, buttons));
    }
    
    inline static function addButtons(action:FlxActionDigital, buttons:Array<FlxGamepadInputID>, state, id)
    {
        for (button in buttons)
            action.addGamepad(button, state, id);
    }
    
    static function removeButtons(action:FlxActionDigital, buttons:Array<FlxGamepadInputID>)
    {
        var i = action.inputs.length;
        while (i-- > 0)
        {
            var input = action.inputs[i];
            if (input.device == GAMEPAD && buttons.indexOf(cast input.inputID) != -1)
                action.remove(input, true);
        }
    }
}