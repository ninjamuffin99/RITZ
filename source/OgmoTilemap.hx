package;

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
	inline public function new
		( ogmo     :OgmoPackage
		, layerName:String
		, path         = 'assets/data/'
		, drawIndex    = 0
		, collideIndex = 1
		)
	{
		this = new FlxTilemap();
		var layer = ogmo.level.get_tile_layer(layerName);
		var tileset = ogmo.project.get_tileset_data(layer.tileset);
		@:privateAccess//get_export_mode
		switch layer.get_export_mode() {
			case CSV    : loadOgmoCSVMap(layer, tileset, path, 0, drawIndex, collideIndex);
			case ARRAY  : loadOgmoArrayMap(layer, tileset, path, 0, drawIndex, collideIndex);
			case ARRAY2D: loadOgmo2DArrayMap(layer, tileset, path, 0, drawIndex, collideIndex);
		}
	}
	
	function loadOgmoCSVMap
		( layer  :TileLayer
		, tileset:ProjectTilesetData
		, path   :String
		, startingIndex = 0
		, drawIndex     = 0
		, collideIndex  = 1
		)
	{
		return this.loadMapFromCSV
			( layer.dataCSV
			, getPaddedTileset(tileset, path)
			, tileset.tileWidth
			, tileset.tileHeight
			, OFF
			, startingIndex
			, drawIndex
			, collideIndex
			);
	}
	
	function loadOgmoArrayMap
		( layer  :TileLayer
		, tileset:ProjectTilesetData
		, path   :String
		, startingIndex = 0
		, drawIndex     = 0
		, collideIndex  = 1
		)
	{
		return this.loadMapFromArray
			( layer.data
			, layer.gridCellsX
			, layer.gridCellsY
			, getPaddedTileset(tileset, path)
			, tileset.tileWidth
			, tileset.tileHeight
			, OFF
			, startingIndex
			, drawIndex
			, collideIndex
			);
	}
	
	function loadOgmo2DArrayMap
		( layer  :TileLayer
		, tileset:ProjectTilesetData
		, path   :String
		, startingIndex = 0
		, drawIndex     = 0
		, collideIndex  = 1
		)
	{
		return this.loadMapFrom2DArray
			( layer.data2D
			, getPaddedTileset(tileset, path)
			, tileset.tileWidth
			, tileset.tileHeight
			, OFF
			, startingIndex
			, drawIndex
			, collideIndex
			);
	}
	
	inline function getPaddedTileset(tileset:ProjectTilesetData, path, padding = 2)
	{
		return FlxTileFrames.fromBitmapAddSpacesAndBorders
			( tileset.get_tileset_path(path)
			, FlxPoint.get(tileset.tileWidth, tileset.tileHeight)
			, FlxPoint.get(tileset.tileSeparationX, tileset.tileSeparationY)
			, FlxPoint.get(padding)
			);
	}
}

@:forward
abstract CameraTilemap(OgmoTilemap) to FlxTilemap
{
	public function new(ogmo:OgmoPackage)
	{
		this = new OgmoTilemap(ogmo, 'CameraView');
	}
	
	public function getTileTypeAt(x:Float, y:Float):CameraTileType
	{
		return switch(this.getTileByIndex(this.getTileIndexByCoords(FlxPoint.weak(x, y))))
		{
			case  0: Up;
			case  1: Down;
			case  2: MoreDown;
			case -1,_: None;
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