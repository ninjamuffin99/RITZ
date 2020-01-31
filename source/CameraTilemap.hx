package;

import flixel.math.FlxPoint;
import flixel.tile.FlxTilemap;

import zero.flixel.utilities.FlxOgmoUtils;
import zero.utilities.OgmoUtils;

using zero.utilities.OgmoUtils;
using zero.flixel.utilities.FlxOgmoUtils;

class CameraTilemap extends FlxTilemap
{
	public function new(ogmo:OgmoPackage)
	{
		super();
		
		var path = 'assets/data/';
		var layer = ogmo.level.get_tile_layer('CameraView');
		var tileset = ogmo.project.get_tileset_data(layer.tileset);
		@:privateAccess//get_export_mode
		switch layer.get_export_mode() {
			case CSV    : loadMapFromCSV(layer.dataCSV, tileset.get_tileset_path(path), tileset.tileWidth, tileset.tileHeight);
			case ARRAY  : loadMapFromArray(layer.data, layer.gridCellsX, layer.gridCellsY, tileset.get_tileset_path(path), tileset.tileWidth, tileset.tileHeight);
			case ARRAY2D: loadMapFrom2DArray(layer.data2D, tileset.get_tileset_path(path), tileset.tileWidth, tileset.tileHeight);
		}
	}
	
	public function getTileTypeAt(x:Float, y:Float):CameraTileType
	{
		return getTileByIndex(getTileIndexByCoords(FlxPoint.weak(x, y))) == 0 ? Up : Down;
	}
}

enum CameraTileType
{
	Up;
	Down;
}