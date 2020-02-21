package ui;

import js.lib.Error;
import flixel.FlxCamera;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.tile.FlxBaseTilemap;
import flixel.tile.FlxTilemap;

import zero.flixel.utilities.FlxOgmoUtils;
import zero.utilities.OgmoUtils;

using zero.utilities.OgmoUtils;
using zero.flixel.utilities.FlxOgmoUtils;

class Minimap extends flixel.group.FlxGroup
{
    inline public static var OLD_TILE_SIZE = 32;
    inline public static var TILE_SIZE = 8;
    
    // forward from map
    public var x     (get, never):Float; inline function get_x     () return map.x     ;
    public var y     (get, never):Float; inline function get_y     () return map.y     ;
    public var width (get, never):Float; inline function get_width () return map.width ;
    public var height(get, never):Float; inline function get_height() return map.height;
    
    final map:MiniTilemap;
    final fog:FlxTilemap;
    final cheese:Array<FlxPoint> = [];
    final checkpoints:Array<FlxPoint> = [];
    
    public function new (levelPath:String)
    {
        super(2);
        add(map = new MiniTilemap(levelPath, cheese, checkpoints));
        add(fog = new FlxTilemap());
        fog.loadMapFromArray
            ( [for (i in 0...map.totalTiles) 1]
            , map.widthInTiles, map.heightInTiles
            , "assets/data/minimapFog.png"
            , TILE_SIZE, TILE_SIZE
            , FlxTilemapAutoTiling.AUTO
            , 0//startIndex
            , 0//drawIndex
            );
    }
    
    public function updateSeen(camera:FlxCamera)
    {
        var shape = FlxRect.get
            ( Math.floor(camera.scroll.x / OLD_TILE_SIZE)
            , Math.floor(camera.scroll.y / OLD_TILE_SIZE)
            , Math.ceil (camera.width    / OLD_TILE_SIZE)
            , Math.ceil (camera.height   / OLD_TILE_SIZE)
            );
        
        if (shape.right > fog.widthInTiles)
            shape.right = fog.widthInTiles;
        
        if (shape.bottom > fog.heightInTiles)
            shape.bottom = fog.heightInTiles;
        
        for(x in Std.int(shape.left)...Std.int(shape.right))
        {
            for(y in Std.int(shape.top)...Std.int(shape.bottom))
            {
                if (fog.getTile(x, y) != 0)
                    fog.setTile(x, y, 0);//, false);
            }
        }
        
        //redraw all
        // fog.setTileByIndex(0, fog.getTileByIndex(0));
        shape.put();
    }
    
    inline public function showCheeseGet(id:Int)
    {
        map.setTile(Std.int(cheese[id].x), Std.int(cheese[id].y), Cheese);
    }
    
    inline public function showCheckpointGet(id:Int)
    {
        map.setTile(Std.int(checkpoints[id].x), Std.int(checkpoints[id].y), Checkpoint);
    }
    
    inline public function getMapTile(x, y):Int return map.getTile(x, y);
    inline public function isFog(x, y):Bool return fog.getTile(x, y) > 0;
}

@:forward
abstract MiniTilemap(OgmoTilemap) to OgmoTilemap
{
    inline static var OLD_TILE_SIZE = Minimap.OLD_TILE_SIZE;
    inline static var TILE_SIZE = Minimap.TILE_SIZE;
    
    inline public function new(levelPath:String, cheese:Array<FlxPoint>, checkpoints:Array<FlxPoint>):MiniTilemap
    {
        var ogmo = FlxOgmoUtils.get_ogmo_package(AssetPaths.levelProject__ogmo, levelPath);
        // -- replace map tiles with minimap
        ogmo = Reflect.copy(ogmo);
        for (tileset in ogmo.project.tilesets)
            if (tileset.label == "digitiles")
            {
                tileset.path = "minimap.png";
                if (tileset.tileWidth != OLD_TILE_SIZE || tileset.tileHeight != OLD_TILE_SIZE)
                    throw 'Unexpected tile size in ogmo file.'
                        + ' expected:($OLD_TILE_SIZE x $OLD_TILE_SIZE)'
                        + ' actual:(${tileset.tileWidth} x ${tileset.tileHeight})';
                tileset.tileWidth = tileset.tileHeight = TILE_SIZE;
            }
        
        this = new OgmoTilemap(ogmo, 'tiles');
        ogmo.level.get_entity_layer('entities').load_entities(stampEntities.bind(_, cheese, checkpoints));
    }
    
    public function stampEntities(entity:EntityData, cheese:Array<FlxPoint>, checkpoints:Array<FlxPoint>)
    {
        switch(entity.name)
        {
            case "coins" | "cheese":
                var p = new FlxPoint(Math.floor(entity.x / OLD_TILE_SIZE), Math.floor(entity.y / OLD_TILE_SIZE));
                cheese.push(p);
                stampMap(this, Std.int(p.x), Std.int(p.y), Cheese_X);
            case "spike":
                var graphic = 0;
                switch(entity.rotation)
                {
                    case 0:
                        graphic = Spike_U;
                    case 90:
                        graphic = Spike_R;
                        entity.x -= OLD_TILE_SIZE;
                    case 180:
                        graphic = Spike_D;
                        entity.x -= OLD_TILE_SIZE;
                        entity.y -= OLD_TILE_SIZE;
                    case -90 | 270:
                        graphic = Spike_L;
                        entity.y -= OLD_TILE_SIZE;
                }
                stampMapOf(this, entity, graphic);
            case "checkpoint":
                var p = new FlxPoint(Math.floor(entity.x / OLD_TILE_SIZE), Math.floor(entity.y / OLD_TILE_SIZE));
                checkpoints.push(p);
                stampMap(this, Std.int(p.x), Std.int(p.y), Checkpoint_X);
            case "movingPlatform":
                if (entity.values.graphic != "none")
                    stampAllMapOf(this, entity, Platform);
            case 'locked' | 'locked_tall':
                stampAllMapOf(this, entity, Door);
            case "player" | "spider" | "musicTrigger" | "secretTrigger"://unusued
            case type: throw 'Unhandled entirty type: $type';
        }
    }
    
    inline static function getStampShapeOf(entity:EntityData)
    {
        return FlxRect.get
            ( Math.floor(entity.x      / OLD_TILE_SIZE)
            , Math.floor(entity.y      / OLD_TILE_SIZE)
            , Math.floor(entity.width  / OLD_TILE_SIZE)
            , Math.floor(entity.height / OLD_TILE_SIZE)
            );
    }
    
    static function stampAllMapOf(map:OgmoTilemap, entity:EntityData, index:Int):Void
    {
        var shape = getStampShapeOf(entity);
        
        for(x in Std.int(shape.left)...Std.int(shape.right))
        {
            for(y in Std.int(shape.top)...Std.int(shape.bottom))
                stampMap(map, x, y, index);
        }
        shape.put();
    }
    
    static function stampMapOf(map:OgmoTilemap, entity:EntityData, index:Int):Void
    {
        stampMap(map, Math.floor(entity.x / OLD_TILE_SIZE), Math.floor(entity.y / OLD_TILE_SIZE), index);
    }
    
    inline static function stampMap(map:OgmoTilemap, x:Int, y:Int, index:Int):Void
    {
        if (map.getTile(x, y) == -1)
            map.setTile(x, y, index);
    }
}

enum abstract EntityTile(Int) from Int to Int
{
    var Spike_U      = 56;
    var Spike_R      = 57;
    var Spike_D      = 58;
    var Spike_L      = 59;
    var Cheese       = 60;
    var Cheese_X     = 61;
    var Checkpoint   = 62;
    var Checkpoint_X = 63;
    var Door         = 64;
    var Platform     = 43;
}