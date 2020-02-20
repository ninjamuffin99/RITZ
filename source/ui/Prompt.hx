package ui;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxBitmapText;

using flixel.util.FlxSpriteUtil;

class Prompt extends flixel.group.FlxGroup {
	
	inline static var BUFFER = 12;
	
	var box:BgSprite;
	var label:BitmapText;
	var keyButtons:ButtonGroup;
	var yesText:BitmapText;
	var noText:BitmapText;
	
	public function new (singleButton = false) {
		super();
		
		add(box = new BgSprite());
		
		add(label = new BitmapText());
		label.alignment = CENTER;
		label.scrollFactor.set();
		
		keyButtons = new ButtonGroup(0, false);
		keyButtons.keysNext = RIGHT;
		keyButtons.keysPrev = LEFT;
		if (singleButton) {
			keyButtons.addButton(yesText = new BitmapText(0, 0, "OK"), null);
			yesText.screenCenter(X);
			yesText.scrollFactor.set();
		} else {
			keyButtons.addButton(yesText = new BitmapText("YES"), null);
			keyButtons.addButton(noText  = new BitmapText("NO"), null);
			yesText.scrollFactor.set();
			noText.scrollFactor.set();
			
		}
		add(keyButtons);
	}
	
	public function setup(text:String, onYes:Void->Void, ?onNo:Void->Void, ?onChoose:Void->Void):Void {
		
		label.text = text;
		label.x = (FlxG.width - label.width) / 2 + 1;
		label.y = (FlxG.height - label.height - label.lineHeight) / 2;
		
		box.setSize
			( Std.int(label.width ) + BUFFER * 2
			, Std.int(label.height) + label.lineHeight + BUFFER * 2
			);
		box.x = (FlxG.width  - box.width ) / 2;
		box.y = (FlxG.height - box.height) / 2;
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
		
		if (Inputs.justPressed.BACK)
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
	inline static public function showOKInterrupt(text:String, buttons:FlxBasic):Void {
		
		var prompt = new Prompt(true);
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

@:forward
abstract BgSprite(FlxSprite) to FlxSprite
{
	inline public function new(x = 0.0, y = 0.0)
	{
		this = new FlxSprite(x, y);
	}
	
	inline public function setSize(width:Int, height:Int)
	{
		this.makeGraphic(width, height, 0, true, "prompt-bg");
		var oldQuality = FlxG.stage.quality;
		FlxG.stage.quality = LOW;
		this.drawRoundRect(
			1, 1,
			width - 2, height - 2,
			8, 8,
			0xFF6d5ba8,
			{ color:0xFF9089c7, thickness:2 },
			{ smoothing: false }
		);
		FlxG.stage.quality = oldQuality;
	}
}