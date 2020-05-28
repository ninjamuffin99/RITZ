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
    var UP      = "up";
    var LEFT    = "left";
    var RIGHT   = "right";
    var DOWN    = "down";
    var UP_P    = "up-press";
    var LEFT_P  = "left-press";
    var RIGHT_P = "right-press";
    var DOWN_P  = "down-press";
    var JUMP    = "jump";
    var JUMP_P  = "jump-press";
    var JUMP_R  = "jump-release";
    var TALK    = "talk";
    var ACCEPT  = "accept";
    var BACK    = "back";
    var MAP     = "map";
    var PAUSE   = "pause";
    var RESET   = "reset";
}

enum Device
{
    Keys;
    Gamepad(id:Int);
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

enum KeyboardScheme
{
    Solo;
    Duo(first:Bool);
    None;
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
    
    var _up     = new FlxActionDigital(Action.UP     );
    var _left   = new FlxActionDigital(Action.LEFT   );
    var _right  = new FlxActionDigital(Action.RIGHT  );
    var _down   = new FlxActionDigital(Action.DOWN   );
    var _upP    = new FlxActionDigital(Action.UP_P   );
    var _leftP  = new FlxActionDigital(Action.LEFT_P );
    var _rightP = new FlxActionDigital(Action.RIGHT_P);
    var _downP  = new FlxActionDigital(Action.DOWN_P );
    var _jump   = new FlxActionDigital(Action.JUMP   );
    var _jumpP  = new FlxActionDigital(Action.JUMP_P );
    var _jumpR  = new FlxActionDigital(Action.JUMP_R );
    var _talk   = new FlxActionDigital(Action.TALK   );
    var _accept = new FlxActionDigital(Action.ACCEPT );
    var _back   = new FlxActionDigital(Action.BACK   );
    var _map    = new FlxActionDigital(Action.MAP    );
    var _pause  = new FlxActionDigital(Action.PAUSE  );
    var _reset  = new FlxActionDigital(Action.RESET  );
    
    var byName:Map<String, FlxActionDigital> = [];
    public var gamepadsAdded:Array<Int> = [];
    public var keyboardScheme = KeyboardScheme.None;
    
    public var UP     (get, never):Bool; inline function get_UP     () return _left  .check();
    public var LEFT   (get, never):Bool; inline function get_LEFT   () return _left  .check();
    public var RIGHT  (get, never):Bool; inline function get_RIGHT  () return _right .check();
    public var DOWN   (get, never):Bool; inline function get_DOWN   () return _down  .check();
    public var UP_P   (get, never):Bool; inline function get_UP_P   () return _upP   .check();
    public var LEFT_P (get, never):Bool; inline function get_LEFT_P () return _leftP .check();
    public var RIGHT_P(get, never):Bool; inline function get_RIGHT_P() return _rightP.check();
    public var DOWN_P (get, never):Bool; inline function get_DOWN_P () return _downP .check();
    public var JUMP   (get, never):Bool; inline function get_JUMP   () return _jump  .check();
    public var JUMP_P (get, never):Bool; inline function get_JUMP_P () return _jumpP .check();
    public var JUMP_R (get, never):Bool; inline function get_JUMP_R () return _jumpR .check();
    public var TALK   (get, never):Bool; inline function get_TALK   () return _talk  .check();
    public var ACCEPT (get, never):Bool; inline function get_ACCEPT () return _accept.check();
    public var BACK   (get, never):Bool; inline function get_BACK   () return _back  .check();
    public var MAP    (get, never):Bool; inline function get_MAP    () return _map   .check();
    public var PAUSE  (get, never):Bool; inline function get_PAUSE  () return _pause .check();
    public var RESET  (get, never):Bool; inline function get_RESET  () return _reset .check();
    
    
    public function new(name, scheme = None)
    {
        super(name);
        
        add(_up);
        add(_left);
        add(_right);
        add(_down);
        add(_upP);
        add(_leftP);
        add(_rightP);
        add(_downP);
        add(_jump);
        add(_jumpP);
        add(_jumpR);
        add(_talk);
        add(_accept);
        add(_back);
        add(_map);
        add(_pause);
        add(_reset);
        
        for (action in digitalActions)
            byName[action.name] = action;
        
        setKeyboardScheme(scheme, false);
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
    
    public function getDialogueNameFromToken(token:String):String
    {
        return getDialogueName(getActionFromControl(Control.createByName(token.toUpperCase())));
    }
    
    function getActionFromControl(control:Control):FlxActionDigital
    {
        return switch(control)
        {
            case UP    : _up    ;
            case DOWN  : _down  ;
            case LEFT  : _left  ;
            case RIGHT : _right ;
            case JUMP  : _jump  ;
            case TALK  : _talk  ;
            case ACCEPT: _accept;
            case BACK  : _back  ;
            case PAUSE : _pause ;
            case MAP   : _map   ;
            case RESET : _reset ;
        }
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
        inline solo.setKeyboardScheme(Solo, false);
        actions.addSet(solo);
        
        duo1 = new Controls("duo1");
        inline duo1.setKeyboardScheme(Duo(true), false);
        actions.addSet(duo1);
        
        duo2 = new Controls("duo2");
        inline duo2.setKeyboardScheme(Duo(false), false);
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
            case UP    :func(_up    , PRESSED);
                        func(_upP   , JUST_PRESSED);
            case LEFT  :func(_left  , PRESSED);
                        func(_leftP , JUST_PRESSED);
            case RIGHT :func(_right , PRESSED);
                        func(_rightP, JUST_PRESSED);
            case DOWN  :func(_down  , PRESSED);
                        func(_downP , JUST_PRESSED);
            case JUMP  :func(_jump  , PRESSED);
                        func(_jumpP , JUST_PRESSED);
                        func(_jumpR , JUST_RELEASED);
            case TALK  :func(_talk  , JUST_PRESSED);
            case ACCEPT:func(_accept, JUST_PRESSED);
            case BACK  :func(_back  , JUST_PRESSED);
            case MAP   :func(_map   , JUST_PRESSED);
            case PAUSE :func(_pause , JUST_PRESSED);
            case RESET :func(_reset , JUST_PRESSED);
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
    
    public function setKeyboardScheme(scheme:KeyboardScheme, reset = true)
    {
        if (reset)
            removeKeyboard();
        
        keyboardScheme = scheme;
        switch(scheme)
        {
            case Solo:
                inline bindKeys(Control.UP    , [W, FlxKey.UP]);
                inline bindKeys(Control.DOWN  , [S, FlxKey.DOWN]);
                inline bindKeys(Control.LEFT  , [A, FlxKey.LEFT]);
                inline bindKeys(Control.RIGHT , [D, FlxKey.RIGHT]);
                inline bindKeys(Control.JUMP  , [Z, Y, W, FlxKey.UP]);
                inline bindKeys(Control.TALK  , [E, F, X]);
                inline bindKeys(Control.ACCEPT, [Z, SPACE]);
                inline bindKeys(Control.BACK  , [X, ESCAPE]);
                inline bindKeys(Control.PAUSE , [P, ESCAPE, ENTER]);
                inline bindKeys(Control.MAP   , [M]);
                inline bindKeys(Control.RESET , [R]);
            case Duo(true):
                inline bindKeys(Control.UP    , [W]);
                inline bindKeys(Control.DOWN  , [S]);
                inline bindKeys(Control.LEFT  , [A]);
                inline bindKeys(Control.RIGHT , [D]);
                inline bindKeys(Control.JUMP  , [G, W, Z]);
                inline bindKeys(Control.TALK  , [H, X]);
                inline bindKeys(Control.ACCEPT, [G, Z]);
                inline bindKeys(Control.BACK  , [H, X]);
                inline bindKeys(Control.PAUSE , [ESCAPE, ONE]);
                inline bindKeys(Control.MAP   , [TWO]);
                inline bindKeys(Control.RESET , [R]);
            case Duo(false):
                inline bindKeys(Control.UP    , [FlxKey.UP]);
                inline bindKeys(Control.DOWN  , [FlxKey.DOWN]);
                inline bindKeys(Control.LEFT  , [FlxKey.LEFT]);
                inline bindKeys(Control.RIGHT , [FlxKey.RIGHT]);
                inline bindKeys(Control.JUMP  , [O, FlxKey.UP]);
                inline bindKeys(Control.TALK  , [P]);
                inline bindKeys(Control.ACCEPT, [O]);
                inline bindKeys(Control.BACK  , [P]);
                inline bindKeys(Control.PAUSE , [ENTER]);
                inline bindKeys(Control.MAP   , [M]);
                inline bindKeys(Control.RESET , [BACKSPACE]);
            case None: //nothing
            case Custom: //nothing
        }
    }
    
    function removeKeyboard()
    {
        for (action in this.digitalActions)
        {
            while (action.inputs.length > 0)
            {
                var input = action.inputs[0];
                if (input.device == KEYBOARD)
                    action.remove(input, true);
            }
        }
    }
    
    public function addGamepad(id:Int, ?buttonMap:Map<Control, Array<FlxGamepadInputID>>):Void
    {
        gamepadsAdded.push(id);
        for (control=>buttons in buttonMap)
            bindButtons(control, id, buttons);
    }
    
    inline function addGamepadLiteral(id:Int, ?buttonMap:Map<Control, Array<FlxGamepadInputID>>):Void
    {
        gamepadsAdded.push(id);
        for (control=>buttons in buttonMap)
            inline bindButtons(control, id, buttons);
    }
    
    public function removeGamepad(deviceID:Int = FlxInputDeviceID.ALL):Void
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
    
    public function addDefaultGamepad(id):Void
    {
        addGamepadLiteral(id, 
            [ Control.ACCEPT => [A]
            , Control.BACK   => [B]
            , Control.UP     => [DPAD_UP   , LEFT_STICK_DIGITAL_UP]
            , Control.DOWN   => [DPAD_DOWN , LEFT_STICK_DIGITAL_DOWN]
            , Control.LEFT   => [DPAD_LEFT , LEFT_STICK_DIGITAL_LEFT]
            , Control.RIGHT  => [DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT]
            , Control.JUMP   => [A]
            , Control.TALK   => [X]
            , Control.PAUSE  => [START]
            , Control.MAP    => [GUIDE]
            , Control.RESET  => [Y]
            ]
        );
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
    
    public function getInputsFor(control:Control, device:Device, ?list:Array<String>):Array<String>
    {
        if (list == null)
            list = [];
        
        switch(device)
        {
            case Keys:
                for (input in getActionFromControl(control).inputs)
                {
                    if (input.device == KEYBOARD)
                        list.push(FlxKey.toStringMap[input.inputID]);
                }
            case Gamepad(id):
                for (input in getActionFromControl(control).inputs)
                {
                    if (input.deviceID == id)
                        list.push(FlxGamepadInputID.toStringMap[input.inputID]);
                }
        }
        return list;
    }
}