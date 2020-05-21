package ui;

import flixel.FlxG;
import flixel.text.FlxText.FlxTextFormat;
import flixel.text.FlxText.FlxTextFormatMarkerPair;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
using flixel.util.FlxStringUtil;

/**
 * THE SEQUEL TO FLXTYPETEXT
 * 
 * Shitty homemade extension bullshit of FlxTypeText lmaooo
 * @author ninjamuffin99
 */
class TypeTextTwo extends flixel.addons.text.FlxTypeText 
{
	/**
	 * key:      list of characters to match against.
	 * time:     Time in seconds that the text will pause for when encountering a comma
	 * variance: Percentage that the period pause changes? Similar to typingVariance in FlxTypeText
	 *     0.5 == up to 50% change in possible speed I think
	**/
	public var pauseData = new Map<String, {time:Float, variance:Float}>();
	var pauseTime = 0.0;
	
	/** The height of the finished text */
	public var finalHeight(default, null):Float;
	
	/**
	   Text that has break lines included, used to see if the text is done
	**/
	private var _intendedText:String = "";
	
	/**
	   If the final intended text equals the current typed out text, this tru
	**/
	public var isFinished:Bool = false;
	
			
	var format1 = new FlxTextFormat(0xE6E600, false, false, 0xFF8000);
	var format2 = new FlxTextFormat(0xFCA138, false, false, 0xFF8000);
	var format3 = new FlxTextFormat(FlxColor.MAGENTA, false, false, null);
	var format4 = new FlxTextFormat(0x0080C0, false, false, null);
	var format5 = new FlxTextFormat(0x00E6E6, false, false, null);
	var format6 = new FlxTextFormat(0x0080FF, false, false, 0xFFFFFF);
		
	
	public var markUpShit:Array<FlxTextFormatMarkerPair>;

	public function new(X:Float, Y:Float, Width:Int, Text:String, Size:Int=8, EmbeddedFont:Bool=true) 
	{
		super(X, Y, Width, Text, Size, EmbeddedFont);
		
		markUpShit = 
		[
			new FlxTextFormatMarkerPair(format1, "<y>"),
			new FlxTextFormatMarkerPair(format2, "<ng>"),
			new FlxTextFormatMarkerPair(format3, "<purp>"),
		];
		
		addPauseChars(".?!", 0.175);
		addPauseChars(",", 0.1);
		
		text = _finalText;
		insertBreakLines();
		finalHeight = height;
		text = "";
	}
	
	public function addPauseChars(chars:String, time:Float, variance = 0.3)
	{
		var data = { time:time, variance:variance };
		for (i in 0...chars.length)
			pauseData[chars.charAt(i)] = data;
	}
	
	override function insertBreakLines() 
	{
		super.insertBreakLines();
		
		//trace(_finalText);
		// sets intended text
		_intendedText = _finalText;
		/* 
		// applies markup
		applyMarkup(_intendedText, markUpShit);
		// when it applies the markup, it also sets the text to the full string for like a frame
		// that looks ugly so we set it to nothing so that the auto type looks proper
		text = "";
		
		// removes markup
		for (markup in markUpShit)
		{
			_finalText = _finalText.remove(markup.marker);
		}
		
		//sets intended text again so that the auto type stuff can finish properly
		_intendedText = _finalText;
		 */
		//trace(_finalText);

	}
	
	override public function update(elapsed:Float):Void 
	{
		super.update(elapsed);
		
		if (text == _intendedText)
			isFinished = true;
		else
			isFinished = false;
		
		if (pauseTime > 0)
		{
			pauseTime -= elapsed;
			if (pauseTime < 0)
			{
				pauseTime = 0;
				paused = false;
			}
		}
		else if (pauseData.exists(_finalText.charAt(_length - 1)))
		{
			final pause = pauseData[_finalText.charAt(_length - 1)];
			pauseTime = pause.time * FlxG.random.float(1 - pause.variance, 1 + pause.variance);
			paused = true;
		}
	}

	override public function skip():Void
	{
		super.skip();
		//isFinished = true;
	}
}