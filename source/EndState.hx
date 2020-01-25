package;

import io.newgrounds.NG;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.FlxState;

class EndState extends FlxState
{
    private var creds:Array<String> =
    [
        "RITZ",
        "For Pixel Day 2020 on Newgrounds.com",
        "",
        "A game by",
        "ninjamuffin99",
        "MKMaffo", 
        "Digimin",
        "Kawaisprite",
        "",
        "",
        "Programming and level design",
        "ninjamuffin99",
        "", 
        "Character art and animation",
        "MKMaffo",
        "",
        "Tile and background art",
        "Digimin",
        "",
        "Music and sounds",
        "Kawaisprite",
        ""

    ];

    var text:FlxText;

    override function create() {
        text = new FlxText(0, FlxG.height, 0, "", 16);
        
        for (i in creds)
        {
            text.text += i + "\n";
        }

        add(text);

        if (NGio.isLoggedIn)
        {
            var hornyMedal = NG.core.medals.get(58882);
            if (!hornyMedal.unlocked)
                hornyMedal.sendUnlock();
        }
        
        super.create();
    }

    var credsCounter:Int = 0;
    override function update(elapsed:Float) {
        credsCounter++;

        if (credsCounter >= 2)
        {
            credsCounter = 0;
            text.y -= 1.75;
        }
        
        
        super.update(elapsed);
    }
}