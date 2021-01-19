package ui;

import data.OgmoTilemap;

import flixel.FlxCamera;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.tile.FlxBaseTilemap;
import flixel.tile.FlxTilemap;

import zero.flixel.utilities.FlxOgmoUtils;
import zero.utilities.OgmoUtils;

using zero.utilities.OgmoUtils;
using zero.flixel.utilities.FlxOgmoUtils;

typedef PositionMap = Map<Int, FlxPoint>;

class Minimap extends flixel.group.FlxGroup
{
    inline public static var OLD_TILE_SIZE = 32;
    inline public static var TILE_SIZE = 8;
    
    // forward from map
    public var x     (get, never):Float; inline function get_x     () return map.x     ;
    public var y     (get, never):Float; inline function get_y     () return map.y     ;
    public var width (get, never):Float; inline function get_width () return map.width ;
    public var height(get, never):Float; inline function get_height() return map.height;
    
    public final checkpoints:PositionMap = [];
    public final cheese:PositionMap = [];
    final map:MiniTilemap;
    final fog:FlxTilemap;
    
    public function new (levelPath:String)
    {
        super(2);
        add(map = new MiniTilemap(levelPath, cheese, checkpoints));
        add(fog = new FlxTilemap());
        fog.loadMapFromArray
            ( [for (i in 0...map.totalTiles) 1]
            , map.widthInTiles, map.heightInTiles
            , "assets/images/minimap_fog.png"
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
        #if debug
        if (!cheese.exists(id))
            throw 'Non-existent cheese id:$id';
        else if (cheese[id] == null)
            throw 'Null cheese id:$id';
        #end
        map.setTile(Std.int(cheese[id].x), Std.int(cheese[id].y), CHEESE);
    }
    
    inline public function showCheckpointGet(id:Int)
    {
        #if debug
        if (!checkpoints.exists(id))
            throw 'Non-exentist checkpoint id:$id';
        else if (checkpoints[id] == null)
            throw 'Null checkpoint id:$id';
        #end
        map.setTile(Std.int(checkpoints[id].x), Std.int(checkpoints[id].y), RAT);
    }
    
    inline public function getMapTile(x, y):Int return map.getTile(x, y);
    inline public function isFog(x, y):Bool return fog.getTile(x, y) > 0;
    inline public function canHaveCursor(x:Int, y:Int):Bool
    {
        return x >= 0 && y >= 0
            && x < map.widthInTiles && y < map.heightInTiles
            && !isFog(x, y);
    }
}

@:forward
abstract MiniTilemap(OgmoTilemap) to OgmoTilemap
{
    inline static var OLD_TILE_SIZE = Minimap.OLD_TILE_SIZE;
    inline static var TILE_SIZE = Minimap.TILE_SIZE;
    
    inline public function new(levelPath:String, cheese:PositionMap, checkpoints:PositionMap):MiniTilemap
    {
        var ogmo = FlxOgmoUtils.get_ogmo_package("assets/data/ogmo/levelProject.ogmo", levelPath);
        // -- replace map tiles with minimap
        ogmo = Reflect.copy(ogmo);
        for (tileset in ogmo.project.tilesets)
            if (tileset.label == "Tiles")
            {
                tileset.path = "../../images/minimap.png";
                if (tileset.tileWidth != OLD_TILE_SIZE || tileset.tileHeight != OLD_TILE_SIZE)
                    throw 'Unexpected tile size in ogmo file.'
                        + ' expected:($OLD_TILE_SIZE x $OLD_TILE_SIZE)'
                        + ' actual:(${tileset.tileWidth} x ${tileset.tileHeight})';
                tileset.tileWidth = tileset.tileHeight = TILE_SIZE;
            }
        
        this = new OgmoTilemap(ogmo, 'tiles');
        ogmo.level.get_entity_layer('BG entities').load_entities(stampEntities.bind(_, cheese, checkpoints, false));
        ogmo.level.get_entity_layer('FG entities').load_entities(stampEntities.bind(_, cheese, checkpoints, true));
    }
    
    public function stampEntities(entity:EntityData, cheese:PositionMap, checkpoints:PositionMap, fg:Bool)
    {
        switch(entity.name)
        {
            case "coins" | "cheese":
                var p = new FlxPoint(Math.floor(entity.x / OLD_TILE_SIZE), Math.floor(entity.y / OLD_TILE_SIZE));
                cheese[entity.id] = p;
                stampMap(this, Std.int(p.x), Std.int(p.y), CHEESE_X, fg);
            case "spike":
                var graphic = 0;
                switch(entity.rotation)
                {
                    case 0:
                        graphic = SPIKE_U;
                    case 90:
                        graphic = SPIKE_R;
                        entity.x -= OLD_TILE_SIZE;
                    case 180:
                        graphic = SPIKE_D;
                        entity.x -= OLD_TILE_SIZE;
                        entity.y -= OLD_TILE_SIZE;
                    case -90 | 270:
                        graphic = SPIKE_L;
                        entity.y -= OLD_TILE_SIZE;
                }
                stampMapOf(this, entity, graphic, fg);
            case "checkpoint":
                var p = new FlxPoint(Math.floor(entity.x / OLD_TILE_SIZE), Math.floor(entity.y / OLD_TILE_SIZE));
                checkpoints[entity.id] = p;
                stampMap(this, Std.int(p.x), Std.int(p.y), RAT_X, fg);
            case "moving_platform"|"blinking_platform":
                if (entity.values.graphic != "none")
                    stampAllMapOf(this, entity, entity.values.oneWayPlatform ? CLOUD : PLATFORM, fg);
            case "solid_moving_platform"|"solid_blinking_platform":
                if (entity.values.graphic != "none")
                    stampAllMapOf(this, entity, PLATFORM, fg);
            case "cloud_moving_platform"|"cloud_blinking_platform":
                if (entity.values.graphic != "none")
                    stampAllMapOf(this, entity, CLOUD, fg);
            case 'locked' | 'locked_tall':
                stampAllMapOf(this, entity, DOOR, fg);
            case "player" | "spider" | "musicTrigger" | "secretTrigger" | "hook"://unusued
            case type: throw 'Unhandled entity type: $type';
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
    
    static function stampAllMapOf(map:OgmoTilemap, entity:EntityData, index:Int, fg:Bool):Void
    {
        var shape = getStampShapeOf(entity);
        
        for(x in Std.int(shape.left)...Std.int(shape.right))
        {
            for(y in Std.int(shape.top)...Std.int(shape.bottom))
                stampMap(map, x, y, index, fg);
        }
        shape.put();
    }
    
    static function stampMapOf(map:OgmoTilemap, entity:EntityData, index:Int, fg:Bool):Void
    {
        stampMap(map, Math.floor(entity.x / OLD_TILE_SIZE), Math.floor(entity.y / OLD_TILE_SIZE), index, fg);
    }
    
    inline static function stampMap(map:OgmoTilemap, x:Int, y:Int, index:Int, fg:Bool):Void
    {
        if (fg || map.getTile(x, y) == -1)
            map.setTile(x, y, index);
    }
}

enum abstract EntityTile(Int) from Int to Int
{
    var SPIKE_U  = 56;
    var SPIKE_R  = 57;
    var SPIKE_D  = 58;
    var SPIKE_L  = 59;
    var CHEESE   = 60;
    var CHEESE_X = 61;
    var RAT      = 62;
    var RAT_X    = 63;
    var DOOR     = 64;
    var PLATFORM = 35;
    var CLOUD    = 43;
}