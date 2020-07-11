package ui;

import ui.Controls;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.text.FlxBitmapText;

enum Options
{
	Ok;
	Cancel;
	YesNo;
	Single(text:String);
	Double(yesText:String, noText:String);
}

class Prompt extends flixel.group.FlxGroup {
	
	inline static var BUFFER = 12;
	
	public var controls:Controls;
	
	var box:SliceBg;
	var label:BitmapText;
	var keyButtons:ButtonGroup;
	var yesText:BitmapText;
	var noText:BitmapText;
	
	public function new (controls:Controls, options:Options = YesNo) {
		this.controls = controls;
		super();
		
		add(box = SliceBg.prompt());
		
		add(label = new BitmapText());
		label.alignment = CENTER;
		label.scrollFactor.set();
		
		keyButtons = new ButtonGroup(controls);
		keyButtons.keysNext = RIGHT_P;
		keyButtons.keysPrev = LEFT_P;
		
		options = switch options
		{
			case Ok    : Single("OK");
			case Cancel: Single("CANCEL");
			case YesNo : Double("YES", "NO");
			default: options;
		}
		
		switch options
		{
			case Single(text):
				keyButtons.addButton(yesText = new BitmapText(0, 0, text), null);
				yesText.screenCenter(X);
				yesText.scrollFactor.set();
			case Double(yes, no):
				keyButtons.addButton(yesText = new BitmapText(yes), null);
				keyButtons.addButton(noText  = new BitmapText(no ), null);
				yesText.scrollFactor.set();
				noText.scrollFactor.set();
			default:
				throw "Invalid options type: " + options;// Should not be possible
		}
		add(keyButtons);
	}
	
	public function setup(text:String, onYes:Void->Void, ?onNo:Void->Void, ?onChoose:Void->Void):Void {
		
		var camera = this.camera;
		label.text = text;
		label.x = (camera.width - label.width) / 2 + 1;
		label.y = (camera.height - label.height - label.lineHeight) / 2;
		
		box.setSize
			( Std.int(label.width ) + BUFFER * 2
			, Std.int(label.height) + label.lineHeight + BUFFER * 2
			);
		box.x = (camera.width  - box.width ) / 2;
		box.y = (camera.height - box.height) / 2;
		box.scrollFactor.set();
		
		yesText.x = label.x;
		yesText.y = label.y + label.height + 2;
		keyButtons.setCallback(yesText, onDecide.bind(onYes, onChoose));
		
		if (noText != null) {
			noText.x = label.x + label.width - noText.width;
			noText.y = label.y + label.height + 2;
			keyButtons.setCallback(noText , onDecide.bind(onNo , onChoose));
		}
	}
	
	function onDecide(callback:Void->Void, onChoose:Void->Void) {
		
		keyButtons.setCallback(yesText, null);
		if (noText != null)
			keyButtons.setCallback(noText , null);
		
		// Sounds.play(MENU_SELECT);
		
		if (callback != null)
			callback();
		
		if (onChoose != null)
			onChoose();
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (controls.BACK && keyButtons.active)
			cancel();
	}
	
	function cancel():Void
	{
		keyButtons.choose(noText);
	}
	
	/**
	 * Shows a single-button prompt and enables/disables the specified button group
	 * @param text    the dialog messsage.
	 * @param buttons the active ui group being interrupted.
	 */
	inline static public function showOKInterrupt(text:String, controls:Controls, buttons:FlxBasic):Void {
		
		var prompt = new Prompt(controls, Ok);
		var parent = FlxG.state;
		parent.add(prompt);
		buttons.active = false;
		prompt.setup(text, null, null,
			function () {
				
				parent.remove(prompt);
				buttons.active = true;
			}
		);
	}
}