package;

class Conductor 
{
	public static var bpm:Int = 132;
	public static var crochet:Float = (60 / bpm) * 1000;// beats in milliseconds
	public static var songPosition:Float;
	public static var offset:Float = 5;
}
	