package ui;

import ui.Minimap;
import ui.Prompt;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.math.FlxVector;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

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
        add(cursor = new MapCursor(player.x, player.y, map));
        
        mapCamera = new FlxCamera(0, 0, FlxG.camera.width, FlxG.camera.height, FlxG.camera.zoom);
        mapCamera.bgColor = 0xFFaad6e6;
        mapCamera.minScrollX = mapCamera.minScrollY = 0;
        mapCamera.maxScrollX = map.width;
        mapCamera.maxScrollY = map.height;
        mapCamera.follow(cursor, TOPDOWN);
        FlxG.cameras.add(mapCamera);
        
        var help = new InputHelp();
        help.scrollFactor.set();
        add(help);
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
    static inline var SPEED = 16;// tiles per second
    static inline var MOVE_RATE = 1 / SPEED;
    static inline var FIRST_MOVE_RATE = 0.25;
    
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
    
    final map:Minimap;
    
    public function new (x = 0.0, y = 0.0, map:Minimap)
    {
        this.map = map;
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
        
        timer -= elapsed;
        
        var moveX = 0;
        var moveY = 0;
        final pressedX = (Inputs.pressed.RIGHT ? 1 : 0) - (Inputs.pressed.LEFT ? 1 : 0);
        final pressedY = (Inputs.pressed.DOWN ? 1 : 0) - (Inputs.pressed.UP ? 1 : 0);
        
        // Always Move if just pressed
        if (pressedX != 0 && Inputs.justPressed.LEFT || Inputs.justPressed.RIGHT)
        {
            timer = FIRST_MOVE_RATE;
            moveX = pressedX;
        }
        
        // Always Move if just pressed
        if (pressedY != 0 && Inputs.justPressed.UP || Inputs.justPressed.DOWN)
        {
            timer = FIRST_MOVE_RATE;
            moveY = pressedY;
        }
        
        // Move if the button was held long enough without the the cursor moving
        if (moveX == 0 && moveY == 0 && timer <= 0)
        {
            timer = Math.max(timer, MOVE_RATE);
            moveX = pressedX;
            moveY = pressedY;
        }
        
        if ((moveX != 0 || moveY != 0) && map.canHaveCursor(tileX + moveX, tileY + moveY))
        {
            tileX += moveX;
            tileY += moveY;
            x = tileX * TILE_SIZE;
            y = tileY * TILE_SIZE;
        }
        
        visible = timer > MOVE_RATE || (MOVE_RATE - timer) % BLINK_RATE < BLINK_RATE / 2;
    }
}

class InputHelp extends FlxSprite
{
    inline static var MOVE_TIME = 0.5;
    inline static var HOLD_TIME = 2.0;
    inline static var LEAVE_TIME = HOLD_TIME + MOVE_TIME;
    inline static var TOTAL_TIME = LEAVE_TIME + MOVE_TIME;
    
    public var movement:FlxRect;
    public var showTimer = TOTAL_TIME;
    
    public function new (?movement:FlxRect):Void
    {
        super();
        autoLoadGraphic();
        
        if (movement == null)
            movement = FlxRect.get((FlxG.width - width) / 2, -height, 0, height);
        x = movement.x;
        y = movement.y;
        this.movement = movement;
        
        Inputs.onInputChange.add(onInputChange);
        showIntro();
    }
    
    function onInputChange():Void
    {
        autoLoadGraphic();
        showIntro();
    }
    
    inline function autoLoadGraphic()
    {
        loadGraphic("assets/images/ui/" + (Inputs.lastUsedKeyboard ? "keys" : "pad") + "_menu.png");
    }
    
    inline function showIntro():Void
    {
        if (showTimer < MOVE_TIME)
            return;// already animating
        if (showTimer > TOTAL_TIME)
            showTimer = 0;// start over
        else if (showTimer > LEAVE_TIME)
            showTimer = TOTAL_TIME - showTimer;// already leaving, reverse to intro equivalent
        else
            showTimer = MOVE_TIME;//Already showing, reset hold
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        if (showTimer < TOTAL_TIME)
        {
            showTimer += elapsed;
            if (showTimer > TOTAL_TIME)
                showTimer = TOTAL_TIME;
            
            var lerp = showTimer / MOVE_TIME;
            if (showTimer > LEAVE_TIME)
                lerp = (TOTAL_TIME - showTimer) / MOVE_TIME;
            else if(showTimer > MOVE_TIME)
                lerp = 1;
            lerp = FlxEase.backOut(lerp);
            trace(lerp);
            x = movement.x + lerp * movement.width;
            y = movement.y + lerp * movement.height;
        }
    }
    
    override function destroy()
    {
        super.destroy();
        
        Inputs.onInputChange.remove(onInputChange);
    }
}

enum MinimapMenuState
{
    SelectingTile;
    ConfirmingCheckpoint;
}