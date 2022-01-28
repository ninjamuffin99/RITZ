package states;

import ui.MinimapSubstate;
import ui.Minimap;
import props.Cheese;
import props.Checkpoint;
import props.Player;

import openfl.utils.Assets;

import haxe.Json;
import haxe.io.Path;

class AdventureState extends PlayState
{
    static var level = WorldWithStart("assets/data/ogmo/levelProject.ogmo", "blue0");
    
    #if debug
    static var debugLevel:LevelType =
        // Single("assets/data/ogmo/levels/ideas/giant.json")
        // Single("assets/data/ogmo/levels/ideas/springs.json")
        // Single("assets/data/ogmo/levels/old/dumbassLevel.json")
        // Single("assets/data/ogmo/levels/old/normassLevel.json")
        // Single("assets/data/ogmo/levels/old/smartassLevel.json")
        null
        ;
    #end
    
    var minimap:Minimap;
    
    override function create()
    {
        super.create();
        
        #if ENABLE_MAP
        minimap = new Minimap(level);
        #end
    }
    
    override function createInitialLevel()
    {
        #if debug
        if (debugLevel != null)
            level = debugLevel;
        #end
        
        switch(level)
        {
            case World(path): createWorld(path);
            case WorldWithStart(path, start): createWorld(path, start);
            case Single(path): createSection(path);
        }
    }
    
    function createWorld(ogmoPath:String, ?start:String)
    {
        var ogmo = Json.parse(Assets.getText(ogmoPath));
        var paths:Array<String> = cast ogmo.worldLevelPaths;
        
        if(paths == null)
            throw "No worldLevelpaths found in " + ogmoPath;
        
        var directory = Path.directory(ogmoPath);
        for (path in paths)
        {
            final id = Path.withoutExtension(Path.withoutDirectory(path));
            final removeSpawns = start != null && id != start;
            createSection(directory + "/" + path, removeSpawns);
        }
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        if (minimap != null)
        {
            updateMap(elapsed);
        }
    }
    
    function updateMap(elapsed:Float)
    {
        var pressedMap = false;
        for (player in avatars)
        {
            minimap.updateSeen(player.playCamera);
            
            if (!pressedMap && player.controls.MAP)
                openSubState(new MinimapSubstate(minimap, player, warpToCheckpointAt));
        }
    }
    
    override function handleCheckpoint(checkpoint:Checkpoint, player:Player)
    {
        super.handleCheckpoint(checkpoint, player);
        
        if (minimap != null)
            minimap.showCheckpointGet(checkpoint.ID);
    }
    
    override function onFeedCheese(cheese:Cheese)
    {
        super.onFeedCheese(cheese);
        
        if (minimap != null)
            minimap.showCheeseGet(cheese.ID);
    }
}

enum LevelType
{
    World(ogmoPath:String);
    WorldWithStart(ogmoPath:String, startLevel:String);
    Single(levelPath:String);
}