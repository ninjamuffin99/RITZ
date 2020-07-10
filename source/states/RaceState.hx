package states;

import flixel.FlxG;

class RaceState extends PlayState
{
    override function create()
    {
        

        super.create();

        FlxG.sound.playMusic("assets/music/race" + BootState.soundEXT, OptionsSubState.musicVol * OptionsSubState.masterVol);
    }
    
    override function createInitialLevel()
    {
        createLevel(AssetPaths.raceStartFlat0__json);
        createLevel("assets/data/raceLevels/raceFlatSplit" + FlxG.random.int(0, 2) + '.json', FlxG.worldBounds.width);
        
        for (i in 0...FlxG.random.int(4, 12))
        {
            createLevel("assets/data/raceLevels/raceSplitSplit" + FlxG.random.int(0, 5) + '.json', FlxG.worldBounds.width);
        }


        createLevel(AssetPaths.raceSplitUpper0__json, FlxG.worldBounds.width);
        createLevel(AssetPaths.raceUpperFlat0__json, FlxG.worldBounds.width);
    }
}