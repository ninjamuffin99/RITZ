package ui;

import flixel.FlxG;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxVector;
import flixel.util.FlxSignal;

enum Input
{
	ACCEPT;
	BACK;
	UP;
	DOWN;
	LEFT;
	RIGHT;
	JUMP;
	TALK;
	PAUSE;
}

class Inputs extends flixel.FlxBasic {
	
	static public var keyPressed       (default, null):InputList;
	static public var keyJustPressed   (default, null):InputList;
	static public var keyJustReleased  (default, null):InputList;
	
	static public var padPressed       (default, null):InputList;
	static public var padJustPressed   (default, null):InputList;
	static public var padJustReleased  (default, null):InputList;
	
	static public var pressed          (default, null):InputList;
	static public var justPressed      (default, null):InputList;
	static public var justReleased     (default, null):InputList;
	
	static public function checkPressed     (input:Input):Bool { return pressed     .get(input); }
	static public function checkPustPressed (input:Input):Bool { return justPressed .get(input); }
	static public function checkPustReleased(input:Input):Bool { return justReleased.get(input); }
	
	static public var onInputChange(default, null) = new FlxSignal();
	static public var acceptGesture(default, null) = new FlxSignal();
	static public var analogDir(get, never):FlxVector;
	inline static function get_analogDir() { return null; }
	
	static var keyMap:Map<Input, Array<FlxKey>> = 
		[ ACCEPT => [Z, SPACE]
		, BACK   => [X, ESCAPE]
		, UP     => [W, UP]
		, DOWN   => [S, DOWN]
		, LEFT   => [A, LEFT]
		, RIGHT  => [D, RIGHT]
		, JUMP   => [Z, Y, UP, W, SPACE]
		, TALK   => [E, F, X]
		, PAUSE  => [P, ESCAPE, ENTER]
		];
	
	static var padMap:Map<Input, Array<FlxGamepadInputID>> = 
		[ ACCEPT => [A]
		, BACK   => [B]
		, UP     => [DPAD_UP   , LEFT_STICK_DIGITAL_UP]
		, DOWN   => [DPAD_DOWN , LEFT_STICK_DIGITAL_DOWN]
		, LEFT   => [DPAD_LEFT , LEFT_STICK_DIGITAL_LEFT]
		, RIGHT  => [DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT]
		, JUMP   => [A]
		, TALK   => [X]
		, PAUSE  => [START, GUIDE]
		];
	
	var wasUsingPad = false;
	
	public function new () {
		super();
		
		FlxG.gamepads.globalDeadZone = 0.1;
		
		keyPressed      = new InputList("key");
		keyJustPressed  = new InputList("keyP");
		keyJustReleased = new InputList("keyR");
		keyPressed     .handler = inputToKeyList(FlxG.keys.anyPressed);
		keyJustPressed .handler = inputToKeyList(FlxG.keys.anyJustPressed);
		keyJustReleased.handler = inputToKeyList(FlxG.keys.anyJustReleased);
		
		padPressed      = new InputList("pad");
		padJustPressed  = new InputList("padP");
		padJustReleased = new InputList("padR");
		
		pressed      = new InputList("all");
		justPressed  = new InputList("allP");
		justReleased = new InputList("allR");
		
		function combine(pad:InputList, key:InputList):Input->Bool {
			return function (input) { return pad.get(input) || key.get(input); };
		}
		pressed     .handler = combine(padPressed     , keyPressed     );
		justPressed .handler = combine(padJustPressed , keyJustPressed );
		justReleased.handler = combine(padJustReleased, keyJustReleased);
	}
	
	override function update(elapsed:Float) {
		super.update(elapsed);
		
		var isUsingPad = usingPad();
		
		if (isUsingPad) {
			
			var pad = FlxG.gamepads.lastActive;
			padPressed     .handler = inputToPadList(pad.anyPressed);
			padJustPressed .handler = inputToPadList(pad.anyJustPressed);
			padJustReleased.handler = inputToPadList(pad.anyJustReleased);
		}
		
		if (isUsingPad != wasUsingPad) {
			
			wasUsingPad = isUsingPad;
			onInputChange.dispatch();
		}
	}
	
	inline static public function usingPad():Bool {
		return FlxG.gamepads.numActiveGamepads > 0;
	}
	
	static function inputToKeyList(handler:Array<FlxKey>->Bool):Input->Bool {
		
		return function (input:Input):Bool { return handler(getKeys(input)); };
	}
	
	static function inputToPadList(handler:Array<FlxGamepadInputID>->Bool):Input->Bool {
		
		return function (input:Input):Bool { return handler(getPadButtons(input)); };
	}
	
	inline static public function getKeys(input) {
		return keyMap.get(input);
	}
	
	inline static public function getPadButtons(input) {
		return padMap.get(input);
	}
}

class InputList {
	
	inline static var LOG
		= false;
		// = true;
	
	public var handler:Null<Input->Bool>;
	public var logId:String;
	
	public function new(logId:String) {
		
		this.logId = logId;
	}
	
	public function get(input:Input):Bool {
		
		var value = get_actual(input);
		if (LOG) {
			trace('$logId handler:${handler != null}'
				+ ' input:${inputToString(input)}'
				+ ' value:$value'
				);
		}
		
		return value;
	}
	
	inline function get_actual(input:Input):Bool {
		
		return handler != null && handler(input);
	}
	
	function inputToString(input:Input):String {
		return switch(input) {
			case UP    : "UP";
			case DOWN  : "DOWN";
			case LEFT  : "LEFT";
			case RIGHT : "RIGHT";
			case BACK  : "BACK";
			case PAUSE : "PAUSE";
			case JUMP  : "JUMP";
			case TALK  : "TALK";
			case ACCEPT: "ACCEPT";
		}
	}
	
	public var ACCEPT(get, never):Bool; inline function get_ACCEPT() { return get(Input.ACCEPT); };
	public var BACK  (get, never):Bool; inline function get_BACK  () { return get(Input.BACK  ); };
	public var UP    (get, never):Bool; inline function get_UP    () { return get(Input.UP    ); };
	public var DOWN  (get, never):Bool; inline function get_DOWN  () { return get(Input.DOWN  ); };
	public var LEFT  (get, never):Bool; inline function get_LEFT  () { return get(Input.LEFT  ); };
	public var RIGHT (get, never):Bool; inline function get_RIGHT () { return get(Input.RIGHT ); };
	public var JUMP  (get, never):Bool; inline function get_JUMP  () { return get(Input.JUMP  ); };
	public var TALK  (get, never):Bool; inline function get_TALK  () { return get(Input.TALK  ); };
	public var PAUSE (get, never):Bool; inline function get_PAUSE () { return get(Input.PAUSE ); };
}