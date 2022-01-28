package ui;

import data.OgmoTilemap;
import states.AdventureState;

import flixel.FlxCamera;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.tile.FlxBaseTilemap;
import flixel.tile.FlxTilemap;

import zero.flixel.utilities.FlxOgmoUtils;

import openfl.utils.Assets;

import haxe.Json;
import haxe.io.Path;

using zero.utilities.OgmoUtils;
using zero.flixel.utilities.FlxOgmoUtils;

inline var OLD_TILE_SIZE = 32;
inline var TILE_SIZE = 8;

class MapPositionData
{
    public final map:MiniTilemap;
    public final x:Int;
    public final y:Int;
    
    public function new (map:MiniTilemap, x:Int, y:Int)
    {
        this.map = map;
        this.x = x;
        this.y = y;
    }
    
    inline public function setTile(tile:Int)
    {
        map.setTile(x, y, tile);
    }
    
    inline static public function fromEntity(map:MiniTilemap, entity:EntityData)
    {
        return new MapPositionData(map, Math.floor(entity.x / OLD_TILE_SIZE), Math.floor(entity.y / OLD_TILE_SIZE));
    }
}

abstract PositionMap(Map<Int, MapPositionData>)
{
    inline public function new ()
    {
        this = new Map<Int, MapPositionData>();
    }
    
    inline function add(id:Int, data:MapPositionData)
    {
        this.set(id, data);
        return data;
    }
    
    inline public function addSimple(id:Int, map:MiniTilemap, x:Int, y:Int)
    {
        return add(id, new MapPositionData(map, x, y));
    }
    
    inline public function addEntity(map:MiniTilemap, entity:EntityData)
    {
        return add(entity.id, MapPositionData.fromEntity(map, entity));
    }
    
    inline public function setTile(id:Int, tile:Int)
    {
        this[id].setTile(tile);
    }
    
    inline public function assert(id:Int)
    {
        #if debug
        if (!this.exists(id))
            throw 'Non-existent id:$id';
        else if (this[id] == null)
            throw 'Null id:$id';
        #end
    }
    
    inline public function destroy()
    {
        this.clear();
    }
}

class Minimap extends flixel.group.FlxGroup
{
    // forward from map
    public var bounds(default, null) = FlxRect.get();
    public var leftIndex = 0;
    public var topIndex = 0;
    
    public final checkpoints = new PositionMap();
    public final cheese = new PositionMap();
    final maps = new FlxTypedGroup<MiniTilemap>();
    final fog:FlxTilemap;
    
    public function new (level:LevelType)
    {
        super(2);
        
        add(maps);
        switch(level)
        {
            case Single(path):
                addSection(path);
            case World(ogmoPath) | WorldWithStart(ogmoPath, _):
                
                var ogmo = Json.parse(Assets.getText(ogmoPath));
                var paths:Array<String> = cast ogmo.worldLevelPaths;
                
                if(paths == null)
                    throw "No worldLevelpaths found in " + ogmoPath;
                
                var directory = Path.directory(ogmoPath);
                for (path in paths)
                    addSection(directory + "/" + path);
        }
        
        // Determine fog map size. pad 1 on all sides
        leftIndex = Math.round(bounds.x / TILE_SIZE) - 1;
        topIndex = Math.round(bounds.y / TILE_SIZE) - 1;
        var widthInTiles  = Math.round(bounds.width  / TILE_SIZE) + 2;
        var heightInTiles = Math.round(bounds.height / TILE_SIZE) + 2;
        
        add(fog = new FlxTilemap());
        fog.x = bounds.x - TILE_SIZE;
        fog.y = bounds.y - TILE_SIZE;
        fog.loadMapFromArray
            ( [for (i in 0...widthInTiles * heightInTiles) 1]
            , widthInTiles, heightInTiles
            , 'assets/images/minimap_fog$TILE_SIZE.png'
            , TILE_SIZE, TILE_SIZE
            , FlxTilemapAutoTiling.AUTO
            , 0//startIndex
            , 0//drawIndex
            );
    }
    
    public function addSection(path:String)
    {
        var map = maps.add(new MiniTilemap(path, cheese, checkpoints));
        
        // extend bounds
        if (bounds.left > map.x) bounds.left = map.x;
        if (bounds.top  > map.y) bounds.top  = map.y;
        if (bounds.right  < map.x + map.width ) bounds.right  = map.x + map.width;
        if (bounds.bottom < map.y + map.height) bounds.bottom = map.y + map.height;
    }
    
    public function updateSeen(camera:FlxCamera)
    {
        var shape = FlxRect.get
            ( Math.floor(camera.scroll.x / OLD_TILE_SIZE)
            , Math.floor(camera.scroll.y / OLD_TILE_SIZE)
            , Math.ceil (camera.width    / OLD_TILE_SIZE)
            , Math.ceil (camera.height   / OLD_TILE_SIZE)
            );
        
        shape.x -= leftIndex;
        shape.y -= topIndex;
        
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
        cheese.assert(id);
        #end
        cheese.setTile(id, CHEESE);
    }
    
    inline public function showCheckpointGet(id:Int)
    {
        #if debug
        checkpoints.assert(id);
        #end
        checkpoints.setTile(id, RAT);
    }
    
    public function getMapTile(x:Int, y:Int):Int
    {
        var tile = 0;
        var pos = FlxPoint.get(x * TILE_SIZE, y * TILE_SIZE);
        for (map in maps)
        {
            if (map.overlapsPoint(pos))
            {
                tile = map.getTileByIndex(map.getTileIndexByCoords(pos));
                break;
            }
        }
        pos.put();
        
        return tile;
    }
    
    inline public function isFog(x, y):Bool 
    {
        return fog.getTile(x - leftIndex, y - topIndex) > 0;
    }
    
    inline public function canHaveCursor(x:Int, y:Int):Bool
    {
        return x >= leftIndex && y >= topIndex
            && x < fog.widthInTiles + leftIndex && y < fog.heightInTiles + topIndex
            && !isFog(x, y);
    }
}

@:forward
abstract MiniTilemap(OgmoTilemap) to FlxTilemap from OgmoTilemap
{
    inline public function new(levelPath:String, cheese:PositionMap, checkpoints:PositionMap):MiniTilemap
    {
        var ogmo = FlxOgmoUtils.get_ogmo_package("assets/data/ogmo/levelProject.ogmo", levelPath);
        // -- replace map tiles with minimap
        ogmo = Reflect.copy(ogmo);
        for (tileset in ogmo.project.tilesets)
            if (tileset.label == "Tiles")
            {
                tileset.path = '../../images/minimap$TILE_SIZE.png';
                if (tileset.tileWidth != OLD_TILE_SIZE || tileset.tileHeight != OLD_TILE_SIZE)
                    throw 'Unexpected tile size in ogmo file.'
                        + ' expected:($OLD_TILE_SIZE x $OLD_TILE_SIZE)'
                        + ' actual:(${tileset.tileWidth} x ${tileset.tileHeight})';
                tileset.tileWidth = tileset.tileHeight = TILE_SIZE;
            }
        
        this = new OgmoTilemap(ogmo, 'tiles');
        this.x = (ogmo.level.offsetX / OLD_TILE_SIZE) * TILE_SIZE;
        this.y = (ogmo.level.offsetY / OLD_TILE_SIZE) * TILE_SIZE;
        ogmo.level.get_entity_layer('BG entities').load_entities(stampEntities.bind(_, cheese, checkpoints, false));
        ogmo.level.get_entity_layer('FG entities').load_entities(stampEntities.bind(_, cheese, checkpoints, true));
    }
    
    public function stampEntities(entity:EntityData, cheese:PositionMap, checkpoints:PositionMap, fg:Bool)
    {
        switch(entity.name)
        {
            case "coins" | "cheese":
                var data = cheese.addEntity(this, entity);
                stampMap(this, data.x, data.y, CHEESE_X, fg);
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
            case 'spring':
                var graphic = 0;
                switch(entity.rotation)
                {
                    case 0:
                        graphic = SPRING_U;
                    case 90:
                        graphic = SPRING_R;
                        entity.x -= OLD_TILE_SIZE;
                    case 180:
                        graphic = SPRING_D;
                        entity.x -= OLD_TILE_SIZE;
                        entity.y -= OLD_TILE_SIZE;
                    case -90 | 270:
                        graphic = SPRING_L;
                        entity.y -= OLD_TILE_SIZE;
                }
                stampMapOf(this, entity, graphic, fg);
            case "balloon":
                stampMapOf(this, entity, BALLOON, fg);
            case "checkpoint":
                var data = checkpoints.addEntity(this, entity);
                stampMap(this, data.x, data.y, RAT_X, fg);
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
            case "player" | "debugPlayer" | "spider"
                | "musicTrigger" | "secretTrigger"
                | "hook" | "powerUp":
                //unusued
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
    var SPRING_U = 64;
    var SPRING_R = 65;
    var SPRING_D = 66;
    var SPRING_L = 67;
    var DOOR     = 68;
    var BALLOON  = 70;
    var PLATFORM = 35;
    var CLOUD    = 43;
}