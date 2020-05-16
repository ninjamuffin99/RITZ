package data;

import props.Player;
import data.OgmoTilemap;

import flixel.group.FlxGroup;

class Level extends FlxGroup
{
    public var map:OgmoTilemap;
    public var player:Player;
    public var cameraTiles:CameraTilemap;
}