package utils;

import flixel.util.FlxSignal;
import io.newgrounds.NG;
import io.newgrounds.objects.Medal;
import io.newgrounds.objects.Score;
import io.newgrounds.objects.ScoreBoard;
import io.newgrounds.components.ScoreBoardComponent.Period;
import openfl.display.Stage;

import flixel.FlxG;

/**
 * MADE BY GEOKURELI THE LEGENED GOD HERO MVP
 */
class NGio
{
	
	public static var isLoggedIn:Bool = false;
	public static var scoreboardsLoaded:Bool = false;
	
	public static var boardsByName:Map<String, ScoreBoard> = [];

	public static var ngDataLoaded(default, null):FlxSignal = new FlxSignal();
	public static var ngScoresLoaded(default, null):FlxSignal = new FlxSignal();
	
	public function new(api:String, encKey:String, ?sessionId:String) {
		
		trace("connecting to newgrounds");
		
		
		NG.createAndCheckSession(api, #if NG_DEBUG true #else false #end, sessionId);
		
		NG.core.verbose = true;
		// Set the encryption cipher/format to RC4/Base64. AES128 and Hex are not implemented yet
		NG.core.initEncryption(encKey);// Found in you NG project view
		
		trace(NG.core.attemptingLogin);
		
		if (NG.core.loggedIn)
		{
			trace("logged in");
		}
		else if (NG.core.attemptingLogin)
		{
			/* a session_id was found in the loadervars, this means the user is playing on newgrounds.com
			 * and we should login shortly. lets wait for that to happen
			 */
			trace("attempting login");
			NG.core.onLogin.add(onNGLogin);
		}
		else
		{
			/* They are NOT playing on newgrounds.com, no session id was found. We must start one manually, if we want to.
			 * Note: This will cause a new browser window to pop up where they can log in to newgrounds
			 */
			NG.core.requestLogin(onNGLogin);
		}
		
		// Load Scoreboards hten call onNGBoardsFetch()
		NG.core.requestScoreBoards(onNGBoardsFetch);
	}
	
	function onNGLogin():Void
	{
		trace ('logged in! user:${NG.core.user.name}');
		isLoggedIn = true;
		FlxG.save.data.sessionId = NG.core.sessionId;
		//FlxG.save.flush();
		// Load medals then call onNGMedalFetch()
		NG.core.requestMedals(onNGMedalFetch);
		
		ngDataLoaded.dispatch();
	}
	
	// --- MEDALS
	function onNGMedalFetch():Void
	{
		
		/*
		// Reading medal info
		for (id in NG.core.medals.keys())
		{
			var medal = NG.core.medals.get(id);
			trace('loaded medal id:$id, name:${medal.name}, description:${medal.description}');
		}
		
		// Unlocking medals
		var unlockingMedal = NG.core.medals.get(54352);// medal ids are listed in your NG project viewer 
		if (!unlockingMedal.unlocked)
			unlockingMedal.sendUnlock();
		*/
	}
	
	// --- SCOREBOARDS
	function onNGBoardsFetch():Void
	{
		for (id in NG.core.scoreBoards.keys())
		{
			var board = NG.core.scoreBoards.get(id);
			trace('loaded scoreboard id:$id, name:${board.name}');
			boardsByName[board.name] = board;
		}
	}
	
	inline static public function unlockMedal(id:Int)
	{
		if (isLoggedIn)
		{
			var medal = NG.core.medals.get(id);
			if (!medal.unlocked)
				medal.sendUnlock();
		}
	}
}