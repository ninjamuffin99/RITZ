package states;

import flixel.FlxG;

class RaceState extends PlayState
{
    override function create()
    {
        super.create();
    }
    
    override function createInitialLevel()
    {
        createLevel(AssetPaths.raceStart0__json);
        createLevel(AssetPaths.raceSegment0__json, FlxG.worldBounds.width);
        createLevel(AssetPaths.raceSegment1__json, FlxG.worldBounds.width);
        createLevel(AssetPaths.raceSegment2__json, FlxG.worldBounds.width);
        createLevel(AssetPaths.raceSegment3__json, FlxG.worldBounds.width);
    }
}