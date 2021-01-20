package states;

import openfl.utils.Assets;
import ui.MinimapSubstate;
import ui.Minimap;
import props.Cheese;
import props.Checkpoint;
import props.Player;

class AdventureState extends PlayState
{
    inline static var LEVEL_PREFIX = 
        "blue";
    
    // inline static var LEVEL_PATH = 
        // "assets/data/ogmo/levels/old/dumbassLevel.json";
        // "assets/data/ogmo/levels/old/normassLevel.json";
        // "assets/data/ogmo/levels/old/smartassLevel.json";
    
	// var minimap:Minimap;
    
    override function create()
    {
        super.create();
        
        // minimap = new Minimap(LEVEL_PATH);
    }
    
    override function createInitialLevel()
    {
        // createLevel(LEVEL_PATH);
        
        createSectionsByPrefix(LEVEL_PREFIX);
    }
    
    function createSectionsByPrefix(prefix:String)
    {
        var i = 0;
        var levelPath = 'assets/data/ogmo/levels/$prefix$i.json';
        while (Assets.exists(levelPath))
        {
            var level = createSection(levelPath);
            
            // if (i > 0)
            //     level.kill();
            i++;
            levelPath = 'assets/data/ogmo/levels/$prefix$i.json';
        }
    }
    
    // override function update(elapsed:Float)
    // {
    //     super.update(elapsed);
        
    //     var pressedMap = false;
    //     grpPlayers.forEach
    //     (
    //         player->
    //         {
    //             minimap.updateSeen(player.playCamera);
                
    //             if (!pressedMap && player.controls.MAP)
    //                 openSubState(new MinimapSubstate(minimap, player, warpTo));
    //         }
    //     );
    // }
    
    // override function handleCheckpoint(checkpoint:Checkpoint, player:Player)
    // {
    //     super.handleCheckpoint(checkpoint, player);
    //     minimap.showCheckpointGet(checkpoint.ID);
    // }
    
    // override function onFeedCheese(cheese:Cheese)
    // {
    //     super.onFeedCheese(cheese);
        
    //     minimap.showCheeseGet(cheese.ID);
    // }
}