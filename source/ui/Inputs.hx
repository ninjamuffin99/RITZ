package ui;

import flixel.FlxG;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.gamepad.lists.FlxGamepadButtonList;
import flixel.input.keyboard.FlxKey;
import flixel.input.keyboard.FlxKeyList;
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
	MAP;
	ANY;
}

class Inputs extends flixel.FlxBasic
{
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
	
	static public var lastUsedKeyboard(default, null) = true;
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
		, MAP    => [M]
		, ANY    => [ANY]
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
		, PAUSE  => [START]
		, MAP    => [GUIDE, Y]
		, ANY    => [ANY]
		];
	
	var wasUsingPad = false;
	
	public function new ()
	{
		super();
		
		FlxG.gamepads.globalDeadZone = 0.1;
		
		keyPressed      = new InputList("key");
		keyJustPressed  = new InputList("keyP");
		keyJustReleased = new InputList("keyR");
		keyPressed     .handler = inputToKeyList(FlxG.keys.pressed);
		keyJustPressed .handler = inputToKeyList(FlxG.keys.justPressed);
		keyJustReleased.handler = inputToKeyList(FlxG.keys.justReleased);
		
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
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		
		var isUsingPad = usingPad();
		
		if (isUsingPad) {
			
			var pad = FlxG.gamepads.lastActive;
			padPressed     .handler = inputToPadList(pad.pressed);
			padJustPressed .handler = inputToPadList(pad.justPressed);
			padJustReleased.handler = inputToPadList(pad.justReleased);
			
			var padPress = pad.pressed.ANY;
			if (FlxG.keys.pressed.ANY != padPress)
			{
				if (lastUsedKeyboard == padPress)
				{
					lastUsedKeyboard = !padPress;
					onInputChange.dispatch();
				}
			}
		}
		else if (!lastUsedKeyboard)
			onInputChange.dispatch();
		
		wasUsingPad = isUsingPad;
	}
	
	inline static public function usingPad():Bool
	{
		return FlxG.gamepads.numActiveGamepads > 0;
	}
	
	static function inputToKeyList(handler:FlxKeyList):Input->Bool
	{
		return function (input:Input):Bool
		{
			for (key in getKeys(input))
			{
				@:privateAccess
				if (key == ANY ? handler.ANY : handler.check(key))
					return true;
			}
			return false;
		};
	}
	
	static function inputToPadList(handler:FlxGamepadButtonList):Input->Bool
	{
		return function (input:Input):Bool
		{
			for (button in getPadButtons(input))
			{
				@:privateAccess
				if (button == ANY ? handler.ANY : handler.check(button))
					return true;
			}
			return false;
		};
	}
	
	inline static public function getKeys(input)
	{
		return keyMap.get(input);
	}
	
	inline static public function getPadButtons(input)
	{
		return padMap.get(input);
	}
	
	inline static public function getDialogueName(input:Input):String
	{
		return lastUsedKeyboard ? ("[" + getKeys(input)[0] + "]") : ("(" + getPadButtons(input)[0] + ")");
	}
	
	static public function getDialogueNameFromToken(inputName:String):String
	{
		return getDialogueName(Input.createByName(inputName));
	}
}

class TypedInputList<T:EnumValue>
{
	inline static var LOG
		= false;
		// = true;
	
	public var handler:Null<T->Bool>;
	public var logId:String;
	
	public function new(logId:String)
		this.logId = logId;
	
	inline public function get(input:T):Bool
	{
		var value = get_actual(input);
		if (LOG) {
			trace('$logId handler:${handler != null}'
				+ ' input:${input.getName()}'
				+ ' value:$value'
				);
		}
		
		return value;
	}
	
	inline function get_actual(input:T):Bool
	{
		return handler != null && handler(input);
	}
}

@:forward
abstract InputList(TypedInputList<Input>)
{
	inline public function new (logId:String) this = new TypedInputList<Input>(logId);
	
	public var ACCEPT(get, never):Bool; inline function get_ACCEPT() return this.get(Input.ACCEPT);
	public var BACK  (get, never):Bool; inline function get_BACK  () return this.get(Input.BACK  );
	public var UP    (get, never):Bool; inline function get_UP    () return this.get(Input.UP    );
	public var DOWN  (get, never):Bool; inline function get_DOWN  () return this.get(Input.DOWN  );
	public var LEFT  (get, never):Bool; inline function get_LEFT  () return this.get(Input.LEFT  );
	public var RIGHT (get, never):Bool; inline function get_RIGHT () return this.get(Input.RIGHT );
	public var JUMP  (get, never):Bool; inline function get_JUMP  () return this.get(Input.JUMP  );
	public var TALK  (get, never):Bool; inline function get_TALK  () return this.get(Input.TALK  );
	public var PAUSE (get, never):Bool; inline function get_PAUSE () return this.get(Input.PAUSE );
	public var MAP   (get, never):Bool; inline function get_MAP   () return this.get(Input.MAP   );
	public var ANY   (get, never):Bool; inline function get_ANY   () return this.get(Input.ANY   );
}