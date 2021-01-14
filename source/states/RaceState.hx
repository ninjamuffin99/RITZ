package states;

class RaceState extends PlayState
{
    override function create()
    {
        super.create();
    }
    
    override function createInitialLevel()
    {
        createLevel("assets/data/raceStart0.json");
    }
}