package states;

class RaceState extends PlayState
{
    override function create()
    {
        super.create();
    }
    
    override function createInitialLevel()
    {
        createLevel(AssetPaths.raceStart0__json);
    }
}