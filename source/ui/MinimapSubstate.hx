package ui;

import ui.Minimap;
import ui.Prompt;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;

class MinimapSubstate extends flixel.FlxSubState
{
    var pauseReleased = false;
    var state:MinimapMenuState = SelectingTile;
    
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
        
        if (!pauseReleased)
            pauseReleased = Inputs.justReleased.PAUSE;
        
        switch (state)
        {
            case SelectingTile:
                if (Inputs.justPressed.BACK || (pauseReleased && Inputs.justPressed.PAUSE))
                    close();
                else if (Inputs.justPressed.ACCEPT && map.getMapTile(cursor.tileX, cursor.tileY) == EntityTile.Checkpoint)
                {
                    state = ConfirmingCheckpoint;
                    cursor.active = false;
                    var prompt = new Prompt();
                    add(prompt);
                    prompt.setup
                        ( "Warp to this checkpoint?\n(Lose all trailing cheese)"
                        ,   function onYes()
                            {
                                travelCallback(cursor.tileX * Minimap.OLD_TILE_SIZE, cursor.tileY * Minimap.OLD_TILE_SIZE);
                                close();
                            }
                        ,   function onNo()
                            {
                                state = SelectingTile;
                                cursor.active = true;
                            }
                        , remove.bind(prompt)
                        );
                }
            case ConfirmingCheckpoint://nothing
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
    static inline var SPEED = 12;// tiles per second
    static inline var MOVE_RATE = 1 / SPEED;
    
    public var tileX(default, set):Int;
    inline function set_tileX(value:Int)
    {
        x = value * TILE_SIZE;
        return tileX = value;
    }
    public var tileY(default, set):Int;
    inline function set_tileY(value:Int)
    {
        y = value * TILE_SIZE;
        return tileY = value;
    }
    
    var timer = 0.0;
    
    public function new (x = 0.0, y = 0.0)
    {
        
        super("assets/images/mapCursor.png");
        tileX = Math.floor(x / Minimap.OLD_TILE_SIZE);
        tileY = Math.floor(y / Minimap.OLD_TILE_SIZE);
        
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

enum MinimapMenuState
{
    SelectingTile;
    ConfirmingCheckpoint;
}