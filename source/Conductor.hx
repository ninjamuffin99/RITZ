package;

class Conductor 
{
	public static var bpm:Int = 132;
	public static var crochet:Float = (60 / bpm) * 1000;// beats in milliseconds
	public static var steps:Float = (crochet * 0.25);//4 times a beat!
	public static var songPosition:Float = 0;
	public static var offset:Float = 5;
	
	public static function changeBPM(diffVal:Int):Void
	{
		bpm += diffVal;
		crochet = (60 / bpm);
		steps = crochet * 0.25;
	}
}
	