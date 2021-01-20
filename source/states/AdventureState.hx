package states;

import ui.MinimapSubstate;
import ui.Minimap;
import props.Cheese;
import props.Checkpoint;
import props.Player;

class AdventureState extends PlayState
{
    inline static var LEVEL_PATH = 
        // "assets/data/ogmo/levels/old/dumbassLevel.json";
        // "assets/data/ogmo/levels/old/normassLevel.json";
        // "assets/data/ogmo/levels/old/smartassLevel.json";
        "assets/data/ogmo/levels/blue0.json";
    
	var minimap:Minimap;
    
    override function create()
    {
        super.create();
        
        minimap = new Minimap(LEVEL_PATH);
    }
    
    override function createInitialLevel()
    {
		createLevel(LEVEL_PATH);
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        var pressedMap = false;
        grpPlayers.forEach
        (
            player->
            {
                minimap.updateSeen(player.playCamera);
                
                if (!pressedMap && player.controls.MAP)
                    openSubState(new MinimapSubstate(minimap, player, warpTo));
            }
        );
    }
    
    override function handleCheckpoint(checkpoint:Checkpoint, player:Player)
    {
        super.handleCheckpoint(checkpoint, player);
        minimap.showCheckpointGet(checkpoint.ID);
    }
    
    override function onFeedCheese(cheese:Cheese)
    {
        super.onFeedCheese(cheese);
        
		minimap.showCheeseGet(cheese.ID);
    }
}