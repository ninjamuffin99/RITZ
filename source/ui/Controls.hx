package ui;

import flixel.FlxG;
import flixel.input.FlxInput;
import flixel.input.actions.FlxActionManager;
import flixel.input.actions.FlxActionSet;
import flixel.input.actions.FlxAction;
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
    var ANY        = "any";
}

enum ControlsType
{
    Solo;
    Duo(first:Bool);
    Custom;
}

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
    var _any       = new FlxActionDigital("any");
    
    var byName:Map<String, FlxActionDigital> = [];
    
    public var JUMP       (get, never):Bool;
    public var JUMP_P     (get, never):Bool;
    public var JUMP_R     (get, never):Bool;
    public var LEFT       (get, never):Bool;
    public var RIGHT      (get, never):Bool;
    public var DOWN       (get, never):Bool;
    public var TALK       (get, never):Bool;
    public var MENU_UP    (get, never):Bool;
    public var MENU_DOWN  (get, never):Bool;
    public var MENU_LEFT  (get, never):Bool;
    public var MENU_RIGHT (get, never):Bool;
    public var ACCEPT     (get, never):Bool;
    public var BACK       (get, never):Bool;
    public var MAP        (get, never):Bool;
    public var PAUSE      (get, never):Bool;
    public var RESET      (get, never):Bool;
    public var ANY        (get, never):Bool;
    
    inline function get_JUMP       () return _jump     .check();
    inline function get_JUMP_P     () return _jumpP    .check();
    inline function get_JUMP_R     () return _jumpR    .check();
    inline function get_LEFT       () return _left     .check();
    inline function get_RIGHT      () return _right    .check();
    inline function get_DOWN       () return _down     .check();
    inline function get_TALK       () return _talk     .check();
    inline function get_MENU_UP    () return _menuUp   .check();
    inline function get_MENU_DOWN  () return _menuDown .check();
    inline function get_MENU_LEFT  () return _menuLeft .check();
    inline function get_MENU_RIGHT () return _menuRight.check();
    inline function get_ACCEPT     () return _accept   .check();
    inline function get_BACK       () return _back     .check();
    inline function get_MAP        () return _map      .check();
    inline function get_PAUSE      () return _pause    .check();
    inline function get_RESET      () return _reset    .check();
    inline function get_ANY        () return _any      .check();
    
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
        add(_any);
        
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
        
        solo = new Controls("solo");
        addKeys(solo._jump     , [Z, Y, UP, W, SPACE], PRESSED);
        addKeys(solo._jumpP    , [Z, Y, UP, W, SPACE], JUST_PRESSED);
        addKeys(solo._jumpR    , [Z, Y, UP, W, SPACE], JUST_RELEASED);
        addKeys(solo._accept   , [Z, SPACE], JUST_PRESSED);
        addKeys(solo._back     , [X, ESCAPE], JUST_PRESSED);
        addKeys(solo._down     , [S, DOWN]);
        addKeys(solo._left     , [A, LEFT]);
        addKeys(solo._right    , [D, RIGHT]);
        addKeys(solo._menuUp   , [W, UP], JUST_PRESSED);
        addKeys(solo._menuDown , [S, DOWN], JUST_PRESSED);
        addKeys(solo._menuLeft , [A, LEFT], JUST_PRESSED);
        addKeys(solo._menuRight, [D, RIGHT], JUST_PRESSED);
        addKeys(solo._talk     , [E, F, X], JUST_PRESSED);
        addKeys(solo._pause    , [P, ESCAPE, ENTER], JUST_PRESSED);
        addKeys(solo._map      , [M], JUST_PRESSED);
        addKeys(solo._reset    , [R], JUST_PRESSED);
        addKeys(solo._any      , [ANY], JUST_PRESSED);
        actions.addSet(solo);
        
        duo1 = new Controls("duo1");
        addKeys(duo1._jump     , [G, W], PRESSED);
        addKeys(duo1._jumpP    , [G, W], JUST_PRESSED);
        addKeys(duo1._jumpR    , [G, W], JUST_RELEASED);
        addKeys(duo1._down     , [S]);
        addKeys(duo1._left     , [A]);
        addKeys(duo1._right    , [D]);
        addKeys(duo1._menuUp   , [W], JUST_PRESSED);
        addKeys(duo1._menuDown , [S], JUST_PRESSED);
        addKeys(duo1._menuLeft , [A], JUST_PRESSED);
        addKeys(duo1._menuRight, [D], JUST_PRESSED);
        addKeys(duo1._accept   , [G], JUST_PRESSED);
        addKeys(duo1._back     , [H, ESCAPE], JUST_PRESSED);
        addKeys(duo1._talk     , [H], JUST_PRESSED);
        addKeys(duo1._pause    , [ESCAPE], JUST_PRESSED);
        addKeys(duo1._map      , [M], JUST_PRESSED);//Todo
        addKeys(duo1._reset    , [R], JUST_PRESSED);
        addKeys(duo1._any      , [ANY], JUST_PRESSED);
        actions.addSet(duo1);
        
        duo2 = new Controls("duo2");
        addKeys(duo2._jump     , [O, UP], PRESSED);
        addKeys(duo2._jumpP    , [O, UP], JUST_PRESSED);
        addKeys(duo2._jumpR    , [O, UP], JUST_RELEASED);
        addKeys(duo2._down     , [DOWN]);
        addKeys(duo2._left     , [LEFT]);
        addKeys(duo2._right    , [RIGHT]);
        addKeys(duo2._menuUp   , [UP], JUST_PRESSED);
        addKeys(duo2._menuDown , [DOWN], JUST_PRESSED);
        addKeys(duo2._menuLeft , [LEFT], JUST_PRESSED);
        addKeys(duo2._menuRight, [RIGHT], JUST_PRESSED);
        addKeys(duo2._accept   , [O, ENTER], JUST_PRESSED);
        addKeys(duo2._back     , [P], JUST_PRESSED);
        addKeys(duo2._talk     , [P], JUST_PRESSED);
        addKeys(duo2._pause    , [ENTER], JUST_PRESSED);
        addKeys(duo2._map      , [M], JUST_PRESSED);//todo
        addKeys(duo2._reset    , [BACKSPACE], JUST_PRESSED);
        addKeys(duo2._any      , [ANY], JUST_PRESSED);
        actions.addSet(duo2);
    }
    
    inline static function addKeys(action:FlxActionDigital, keys:Array<FlxKey>, state:FlxInputState = PRESSED)
    {
        for (key in keys)
            action.addKey(key, state);
    }
}