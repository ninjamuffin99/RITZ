package data;

import flixel.util.FlxArrayUtil;
import flixel.graphics.frames.FlxTileFrames;
import flixel.math.FlxPoint;
import flixel.tile.FlxTilemap;

import zero.flixel.utilities.FlxOgmoUtils;
import zero.utilities.OgmoUtils;

using zero.utilities.OgmoUtils;
using zero.flixel.utilities.FlxOgmoUtils;

@:forward
abstract OgmoTilemap(FlxTilemap) to FlxTilemap
{
	public function new
		( ogmo     :OgmoPackage
		, layerName:String
		, path         = 'assets/data/ogmo/'
		, drawIndex    = 0
		, collideIndex = 1
		, indexOffset  = 0
		)
	{
		this = new FlxTilemap();
		var layer = ogmo.level.get_tile_layer(layerName);
		var tileset = ogmo.project.get_tileset_data(layer.tileset);
		@:privateAccess//get_export_mode
		switch layer.get_export_mode() {
			case CSV    : throw "unsupported CSV export mode";
			case ARRAY  : loadOgmoArrayMap(layer, tileset, path, indexOffset, drawIndex, collideIndex);
			case ARRAY2D: loadOgmo2DArrayMap(layer, tileset, path, indexOffset, drawIndex, collideIndex);
		}
	}
	
	inline public function setTileCollisions(index:Int, allowCollisions:Int)
	{
		
		@:privateAccess
		this._tileObjects[index].allowCollisions = allowCollisions;
	}
	
	inline public function setTilesCollisions(startIndex:Int, num:Int, allowCollisions:Int)
	{
		for (i in startIndex...startIndex + num)
			setTileCollisions(i, allowCollisions);
	}
	
	inline function loadOgmoArrayMap
		( layer  :TileLayer
		, tileset:ProjectTilesetData
		, path   :String
		, indexOffset  = 0
		, drawIndex    = 0
		, collideIndex = 1
		)
	{
		return this.loadMapFromArray
			( getOffsetIndices(layer.data, indexOffset)
			, layer.gridCellsX
			, layer.gridCellsY
			, getPaddedTileset(tileset, path)
			, tileset.tileWidth
			, tileset.tileHeight
			, OFF
			, 0
			, drawIndex
			, collideIndex
			);
	}
	
	inline function loadOgmo2DArrayMap
		( layer  :TileLayer
		, tileset:ProjectTilesetData
		, path   :String
		, indexOffset  = 0
		, drawIndex    = 0
		, collideIndex = 1
		)
	{
		return this.loadMapFromArray
			( getOffsetIndices(FlxArrayUtil.flatten2DArray(layer.data2D), indexOffset)
			, layer.gridCellsX
			, layer.gridCellsY
			, getPaddedTileset(tileset, path)
			, tileset.tileWidth
			, tileset.tileHeight
			, OFF
			, 0
			, drawIndex
			, collideIndex
			);
	}
	
	inline function getOffsetIndices(data:Array<Int>, offset:Int):Array<Int>
	{
		return offset == 0 ? data : data.map(i->i+offset);
	}
	
	inline function getPaddedTileset(tileset:ProjectTilesetData, path, padding = 2)
	{
		return FlxTileFrames.fromBitmapAddSpacesAndBorders
			( getTilesetPath(tileset, path)
			, FlxPoint.get(tileset.tileWidth, tileset.tileHeight)
			, FlxPoint.get(tileset.tileSeparationX, tileset.tileSeparationY)
			, FlxPoint.get(padding, padding)
			);
	}
	
	public static function getTilesetPath(data:ProjectTilesetData, path:String):String
	{
		return haxe.io.Path.normalize(path + data.path);
	}
}

@:forward
abstract CameraTilemap(OgmoTilemap) to FlxTilemap
{
	public function new(ogmo:OgmoPackage)
	{
		this = new OgmoTilemap(ogmo, 'CameraView', "assets/data/ogmo/", 0, 1, 1);
	}
	
	public function getTileTypeAt(x:Float, y:Float):CameraTileType
	{
		return switch(this.getTileByIndex(this.getTileIndexByCoords(FlxPoint.weak(x, y))))
		{
			case 1: Up;
			case 2: Down;
			case 3: MoreDown;
			case 0,_: None;
		} 
	}
}

@:using(OgmoTilemap.CameraTileTypeTools)
enum CameraTileType
{
	None;
	Up;
	Down;
	MoreDown;
}
@:noCompletion
class CameraTileTypeTools
{
	public static function getOffset(type:CameraTileType):Float
	{
		return switch (type)
		{
			case None    : -1;
			case Up      : -3;
			case Down    :  1;
			case MoreDown:  5;
		}
	}
}