package;

import flixel.FlxG;
import flixel.addons.text.FlxTypeText;
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
class TypeTextTwo extends FlxTypeText 
{
	/**
	   Time in seconds that the text will pause for when encountering a period
	**/
	public var periodPause:Float = 0.175;
	
	/**
	   Percentage that the period pause changes? Similar to typingVariance in FlxTypeText
	   0.5 == up to 50% change in possible speed I think
	**/
	public var periodPauseVariance:Float = 0.3;
	
	/**
	   Time in seconds that the text will pause for when encountering a comma
	**/
	public var commaPause:Float = 0.1;
	
	/**
	   Percentage that the period pause changes? Similar to typingVariance in FlxTypeText
	   0.5 == up to 50% change in possible speed I think
	**/
	public var commaPauseVariance:Float = 0.3;
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
		
		//addFormat(format1, 8, 15);
		
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
		
		if (!paused)
		{
			switch(_finalText.charAt(_length - 1))
			{
				case ".":
					paused = true;
					new FlxTimer().start(periodPause * FlxG.random.float(1 - periodPauseVariance, 1 + periodPauseVariance), function(tmr:FlxTimer)
					{
						paused = false; 
						
					});
				case ",":
					paused = true;
					new FlxTimer().start(commaPause * FlxG.random.float(1 - commaPauseVariance, 1 + commaPauseVariance), function(tmr:FlxTimer)
					{
						paused = false; 
						
					});
			}
		}
		
	}

	override public function skip():Void
	{
		super.skip();
		//isFinished = true;
	}
}