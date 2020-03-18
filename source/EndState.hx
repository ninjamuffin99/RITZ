package;

import ui.DialogueSubstate;

import io.newgrounds.NG;

import flixel.FlxG;
import flixel.text.FlxText;

class EndState extends flixel.FlxState
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
        "Programming, design and writing",
        "ninjamuffin99",
        "", 
        "Character art and animation",
        "MKMaffo",
        "",
        "Tile, background art and additional writing",
        "Digimin",
        "",
        "Music and sounds",
        "Kawaisprite",
        "",
        "",
        "Made with HaxeFlixel",
        "",
        "Source code",
        "github.com/ninjamuffin99/actualPixelDay2020",
        "",
        "Map editor",
        "OGMO 3",
        "",
        "",
        "",
        "Special Thanks",
        "OzoneOrange",
        "Wandaboy",
        "Snackers",
        "Carmet",
        "HenryEYES",
        "FuShark",
        "PhantomArcade",
        "GeoKureli",
        "Joe Swanson from Family Guy",
        "MuccTucc",
        "SuperMega",
        "DonRRR",
        "",
        "Tom Fulp and Newgrounds"
        

    ];

    var text:FlxText;
    var dumbass:Checkpoint;
    override function create() {
        text = new FlxText(0, FlxG.height + 100, 0, "", 16);
        dumbass = new Checkpoint(400, 1600, "Huh, looks like it's over. Thanks for playing Ritz! I'm still kinda hungry though... go find me more cheese!");
        add(dumbass);

        FlxG.sound.playMusic('assets/music/ritz' + BootState.soundEXT, 0.8);
        
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
    var finishedShit:Bool = false;
    override function update(elapsed:Float) {
        credsCounter++;

        FlxG.watch.addQuick('da', text.y);
        if (dumbass.y < FlxG.height - 110)
        {
            if (finishedShit)
            {
                FlxG.switchState(new MenuState());
            }
            else
            {
                finishedShit = true;
                openSubState(new DialogueSubstate(dumbass.dialogue));
            }
        }

        if (text.y < -900 && FlxG.sound.music.volume == 0.8)
        {
            FlxG.sound.music.fadeOut(2, 0);
        }
            

        if (credsCounter >= 2)
        {
            credsCounter = 0;
            text.y -= 1.45;

            dumbass.y -= 1.45;
        }
        
        
        super.update(elapsed);
    }
}