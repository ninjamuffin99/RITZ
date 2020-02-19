package ui;

import input.Inputs;
import ui.Minimap;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;

class MinimapSubstate extends flixel.FlxSubState
{
    final map:Minimap;
    final mapCamera:FlxCamera;
    final cursor:MapCursor;
    final travelCallback:(x:Float, y:Float)->Void;
    
    public function new (map:Minimap, player:Player, travelCallback)
    {
        this.map = map;
        this.travelCallback = travelCallback;
        super();
        
        var bg = new FlxSprite().makeGraphic(FlxG.camera.width, FlxG.camera.height, 0xFFaad6e6);
        bg.scrollFactor.set();
        add(bg);
        add(map);
        add(cursor = new MapCursor(player.x, player.y));
        
        mapCamera = new FlxCamera(0, 0, FlxG.camera.width, FlxG.camera.height, FlxG.camera.zoom);
        mapCamera.bgColor = 0xFFaad6e6;
        mapCamera.minScrollX = mapCamera.minScrollY = 0;
        mapCamera.maxScrollX = map.width;
        mapCamera.maxScrollY = map.height;
        mapCamera.follow(cursor, TOPDOWN);
        FlxG.cameras.add(mapCamera);
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        if (Inputs.justPressed.BACK)
            close();
        else if (Inputs.justPressed.ACCEPT && map.getMapTile(cursor.tileX, cursor.tileY) == EntityTile.Checkpoint)
        {
            travelCallback(cursor.tileX * Minimap.OLD_TILE_SIZE, cursor.tileY * Minimap.OLD_TILE_SIZE);
            close();
        }
    }
    
    override function close()
    {
        FlxG.cameras.remove(mapCamera);
        remove(map);//prevent destroy
        
        super.close();
    }
}

class MapCursor extends flixel.FlxSprite
{
    static inline var TILE_SIZE = Minimap.TILE_SIZE;
    static inline var BLINK_RATE = 0.5;
    static inline var SPEED = 8;// tiles per second
    static inline var MOVE_RATE = 1 / SPEED;
    
    public var tileX(default, null):Int;
    public var tileY(default, null):Int;
    
    var timer = 0.0;
    
    public function new (x = 0.0, y = 0.0)
    {
        tileX = Math.floor(x / Minimap.OLD_TILE_SIZE);
        tileY = Math.floor(y / Minimap.OLD_TILE_SIZE);
        
        super(tileX * TILE_SIZE, tileY * TILE_SIZE, "assets/images/mapCursor.png");
        
        width = TILE_SIZE;
        height = TILE_SIZE;
        offset.x = (frameWidth  - width ) / 2;
        offset.y = (frameHeight - height) / 2;
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        timer += elapsed;
        
        var moved = false;
        final xPressed = (Inputs.pressed.RIGHT ? 1 : 0) - (Inputs.pressed.LEFT ? 1 : 0);
        final yPressed = (Inputs.pressed.DOWN ? 1 : 0) - (Inputs.pressed.UP ? 1 : 0);
        // check if direction chosen
        if (xPressed != 0)
        {
            // Always Move if just pressed
            if (Inputs.justPressed.LEFT || Inputs.justPressed.RIGHT)
            {
                moved = true;
                tileX += xPressed;
            }
        }
        
        if (yPressed != 0)
        {
            // Always Move if just pressed
            if (Inputs.justPressed.UP || Inputs.justPressed.DOWN)
            {
                moved = true;
                tileY += yPressed;
            }
        }
        
        // Move if the button was held long enough without the the cursor moving
        if (!moved && (xPressed != 0 || yPressed != 0) && timer > MOVE_RATE)
        {
            moved = true;
            tileX += xPressed;
            tileY += yPressed;
        }
        
        if (moved)
        {
            timer = 0;
            x = tileX * TILE_SIZE;
            y = tileY * TILE_SIZE;
        }
        
        visible = timer % BLINK_RATE < BLINK_RATE / 2;
    }
}