package ui;

import flixel.FlxG;
import flixel.input.actions.FlxActionManager;
import flixel.input.actions.FlxActionSet;
import flixel.input.FlxInput;
import flixel.input.actions.FlxAction;
import flixel.input.keyboard.FlxKey;

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
    
    var _jump   = new FlxActionDigital("jump");
    var _jumpP  = new FlxActionDigital("jump-press");
    var _jumpR  = new FlxActionDigital("jump-release");
    var _up     = new FlxActionDigital("up");
    var _left   = new FlxActionDigital("left");
    var _right  = new FlxActionDigital("right");
    var _down   = new FlxActionDigital("down");
    var _talk   = new FlxActionDigital("talk");
    var _accept = new FlxActionDigital("accept");
    var _back   = new FlxActionDigital("back");
    var _map    = new FlxActionDigital("map");
    var _pause  = new FlxActionDigital("pause");
    var _reset  = new FlxActionDigital("reset");
    var _any    = new FlxActionDigital("any");
    
    public var jump  (get, never):Bool;
    public var jumpP (get, never):Bool;
    public var jumpR (get, never):Bool;
    public var up    (get, never):Bool;
    public var left  (get, never):Bool;
    public var right (get, never):Bool;
    public var down  (get, never):Bool;
    public var talk  (get, never):Bool;
    public var accept(get, never):Bool;
    public var back  (get, never):Bool;
    public var map   (get, never):Bool;
    public var pause (get, never):Bool;
    public var reset (get, never):Bool;
    public var any   (get, never):Bool;
    
    inline function get_jump  () return _jump  .check();
    inline function get_jumpP () return _jumpP .check();
    inline function get_jumpR () return _jumpR .check();
    inline function get_up    () return _up    .check();
    inline function get_left  () return _left  .check();
    inline function get_right () return _right .check();
    inline function get_down  () return _down  .check();
    inline function get_talk  () return _talk  .check();
    inline function get_accept() return _accept.check();
    inline function get_back  () return _back  .check();
    inline function get_map   () return _map   .check();
    inline function get_pause () return _pause .check();
    inline function get_reset () return _reset .check();
    inline function get_any   () return _any   .check();
    
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
        add(_accept);
        add(_back);
        add(_map);
        add(_pause);
        add(_reset);
        add(_any);
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
        addKeys(solo._jump  , [Z, Y, UP, W, SPACE], PRESSED);
        addKeys(solo._jumpP , [Z, Y, UP, W, SPACE], JUST_PRESSED);
        addKeys(solo._jumpR , [Z, Y, UP, W, SPACE], JUST_RELEASED);
        addKeys(solo._accept, [Z, SPACE], JUST_PRESSED);
        addKeys(solo._back  , [X, ESCAPE], JUST_PRESSED);
        addKeys(solo._up    , [W, UP]);
        addKeys(solo._down  , [S, DOWN]);
        addKeys(solo._left  , [A, LEFT]);
        addKeys(solo._right , [D, RIGHT]);
        addKeys(solo._talk  , [E, F, X], JUST_PRESSED);
        addKeys(solo._pause , [P, ESCAPE, ENTER], JUST_PRESSED);
        addKeys(solo._map   , [M], JUST_PRESSED);
        addKeys(solo._reset , [R], JUST_PRESSED);
        addKeys(solo._any   , [ANY], JUST_PRESSED);
        actions.addSet(solo);
        
        duo1 = new Controls("duo1");
        addKeys(duo1._jump  , [G, W], PRESSED);
        addKeys(duo1._jumpP , [G, W], JUST_PRESSED);
        addKeys(duo1._jumpR , [G, W], JUST_RELEASED);
        addKeys(duo1._accept, [G], JUST_PRESSED);
        addKeys(duo1._back  , [H, ESCAPE], JUST_PRESSED);
        addKeys(duo1._up    , [W]);
        addKeys(duo1._down  , [S]);
        addKeys(duo1._left  , [A]);
        addKeys(duo1._right , [D]);
        addKeys(duo1._talk  , [H], JUST_PRESSED);
        addKeys(duo1._pause , [ESCAPE], JUST_PRESSED);
        addKeys(duo1._map   , [M], JUST_PRESSED);
        addKeys(duo1._reset , [R], JUST_PRESSED);
        addKeys(duo1._any   , [ANY], JUST_PRESSED);
        actions.addSet(duo1);
        
        duo2 = new Controls("duo2");
        addKeys(duo2._jump  , [O, UP], PRESSED);
        addKeys(duo2._jumpP , [O, UP], JUST_PRESSED);
        addKeys(duo2._jumpR , [O, UP], JUST_RELEASED);
        addKeys(duo2._accept, [O, ENTER], JUST_PRESSED);
        addKeys(duo2._back  , [P], JUST_PRESSED);
        addKeys(duo2._up    , [UP]);
        addKeys(duo2._down  , [DOWN]);
        addKeys(duo2._left  , [LEFT]);
        addKeys(duo2._right , [RIGHT]);
        addKeys(duo2._talk  , [P], JUST_PRESSED);
        addKeys(duo2._pause , [ENTER], JUST_PRESSED);
        addKeys(duo2._map   , [M], JUST_PRESSED);
        addKeys(duo2._reset , [BACKSPACE], JUST_PRESSED);
        addKeys(duo2._any   , [ANY], JUST_PRESSED);
        actions.addSet(duo2);
    }
    
    inline static function addKeys(action:FlxActionDigital, keys:Array<FlxKey>, state:FlxInputState = PRESSED)
    {
        for (key in keys)
            action.addKey(key, state);
    }
}