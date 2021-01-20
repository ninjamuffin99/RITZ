package states;

class RaceState extends PlayState
{
    override function create()
    {
        super.create();
    }
    
    override function createInitialLevel()
    {
        createSection("assets/data/ogmo/levels/raceStart0.json");
    }
}