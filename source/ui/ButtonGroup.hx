package ui;

// import utils.Sounds;

import ui.Controls;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.effects.FlxFlicker;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxTween.TweenOptions;
import flixel.util.FlxColor;

interface ITransitionable {
	
	function startIntro(delay:Float = 0.0, ?callback:()->Void):Void;
	function startOutro(delay:Float = 0.0, ?callback:()->Void):Void;
}

@:forward
abstract DesktopButton(BitmapText) to BitmapText from BitmapText {
	
	inline public function deselect(colorDefault:Int, colorHilite:Int):Void {
		
		this.color = colorDefault;
		this.useTextColor = false;
	}
	
	inline public function select(colorDefault:Int, colorHilite:Int):Void {
		
		this.color = colorHilite;
		this.useTextColor = false;
	} 
	
	inline public function disable():Void {
		
		this.color = 0xFF928fb8;
		this.useTextColor = false;
		this.alive = false;
	}
}

class ButtonGroup extends TypedButtonGroup<DesktopButton> {
	
	public function new (maxSize, controls, hideForIntro = true) {
		
		super(maxSize, controls, hideForIntro);
		
		colorHilite = 0xFFffda76;
		// colorDefault = 0xFF000000;
		colorDefault = 0xFFffffff;//doesn't work, not sure why
	}
	
	override function add(text:DesktopButton):DesktopButton {
		
		text.deselect(colorDefault, colorHilite);
		
		return super.add(text);
	}
	
	public function addNewButton(x:Float, y:Float, text:String, callback:Void->Void, borderColor = 0xFF202e38):BitmapText {
		
		var button = new BitmapText(x, y, text, borderColor);
		addButton(button, callback);
		return button;
	}
	
	override public function disableButon(button:DesktopButton):DesktopButton
	{
		if (button.alive && members.indexOf(button) != -1)
			button.disable();
		
		return button;
	}
	
	override function set_selected(value:Int):Int {
		// super.set_selected(value);
		
		if (members.length > value) {
			
			// if (selected != value)
			// 	Sounds.play(MENU_NAV);
			
			members[selected].deselect(colorDefault, colorHilite);
			selected = value;
			members[selected].select(colorDefault, colorHilite);
		}
		return value;
	}
}

class TypedButtonGroup<T:FlxSprite>
	extends FlxTypedSpriteGroup<T>
	implements ITransitionable {
	
	public var colorHilite:FlxColor = 0xFFffda76;
	public var colorDefault:FlxColor = 0xFFffffff;
	
	public var keysNext  :Null<Action> = DOWN_P;
	public var keysPrev  :Null<Action> = UP_P;
	public var keysSelect:Null<Action> = ACCEPT;
	public var keysBack:Null<Action> = null;
	var onBack:()->Void;
	
	public var selected(default, set) = 0;
	function set_selected(value:Int):Int {
		
		if (members.length > value) {
			
			// if (selected != value)
				// Sounds.play(MENU_NAV);
			
			members[selected].color = colorDefault;
			selected = value;
			members[selected].color = colorHilite;
		}
		return value;
	}
	
	var controls:Controls;
	var callbacks:Map<FlxSprite, Void->Void> = new Map();
	
	public function new(maxSize:Int = 0, controls:Controls, hideForIntro = true)
	{
		this.controls = controls;
		super(maxSize);
		if (hideForIntro)
		{
			visible = false;
			active = false;
		}
	}
	
	public function addButton(button:T, callback:Void->Void):TypedButtonGroup<T> {
		
		add(button);
		callbacks[button] = callback;
		
		if (members.length == selected + 1)
			set_selected(selected);
		
		return this;
	}
	
	public function disableButon(button:T):T
	{
		if (button.alive && members.indexOf(button) != -1)
		{
			button.color = 0xFF928fb8;
			button.alive = false;
		}
		
		return button;
	}
	
	public function setCallback(button:T, callback:Void->Void):Void {
		
		callbacks[button] = callback;
	}
	
	override public function update(elapsed:Float):Void {
		super.update(elapsed);
		
		checkKeys(elapsed);
	}
	
	function checkKeys(elapsed:Float):Void {
		
		var newSelected = selected;
		if (keysNext != null && controls.checkByName(keysNext))
		{
			do
			{
				if (newSelected + 1 > members.length - 1)
					newSelected = 0;
				else
					newSelected++;
			}
			while(members[newSelected] == null || !members[newSelected].alive);
		}
		
		if (keysPrev != null && controls.checkByName(keysPrev))
		{
			do
			{
				if (newSelected - 1 < 0 )
					newSelected = members.length - 1;
				else
					newSelected--;
			}
			while(members[newSelected] == null || !members[newSelected].alive);
		}
		
		if (selected != newSelected)
			selected = newSelected;
		
		if (keysSelect != null && controls.checkByName(keysSelect))
			onSelect();
		
		if (keysBack != null && controls.checkByName(keysBack) && onBack != null)
			onBack();
	}
	
	public function choose(button:T):Void
	{
		selected = members.indexOf(button);
		if (selected == -1)
			throw "Specified button not a member of this button group";
		onSelect();
	}
	
	function onSelect():Void {
		
		// Sounds.play(MENU_SELECT);
		active = false;
		
		var callback = callbacks[members[selected]];
		FlxFlicker.flicker(members[selected], 0.5, 0.05, true, true,
			function(_) {
				active = true;
				callback();
			}
		);
	}
	
	public function startIntro(delay = 0.0, ?callback:()->Void):Void
	{
		visible = true;
		active = false;
		
		function onIntroComplete(_) {
			active = true;
			
			if (callback != null)
				callback();
		}
		
		for (i in 0...members.length)
		{
			var button = members[i];
			
			var options:TweenOptions = { ease:FlxEase.backOut, startDelay: delay + i * 0.125 };
			if (i == members.length - 1)
				options.onComplete = onIntroComplete;
			
			button.x = -button.width - 2;
			FlxTween.tween(button, { x:(FlxG.width - button.width) / 2 }, 0.25, options);
		}
	}
	
	public function startOutro(delay = 0.0, ?callback:()->Void):Void
	{
		active = false;
		for (i in 0...members.length)
		{
			var button = members[i];
			
			var options:TweenOptions = { ease:FlxEase.backIn, startDelay: delay + i * 0.125 };
			if (i == members.length - 1 && callback != null)
				options.onComplete = (_)-> callback();
			
			FlxTween.tween(button, { x:-button.width - 2 }, 0.25, options);
		}
	}
}