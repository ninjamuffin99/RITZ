package states;

import ui.MinimapSubstate;
import ui.Minimap;
import props.Cheese;
import props.Checkpoint;
import props.Player;

class AdventureState extends PlayState
{
    inline static var LEVEL_PATH = 
        // AssetPaths.dumbassLevel__json;
        // AssetPaths.normassLevel__json;
        AssetPaths.smartassLevel__json;
    
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
                minimap.updateSeen(playerCameras[player]);
                
                if (!pressedMap && player.controls.map)
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