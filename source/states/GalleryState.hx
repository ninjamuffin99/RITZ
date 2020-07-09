package states;

import lime.utils.Assets;
import haxe.Json;
import haxe.ds.ReadOnlyArray;

class GalleryState extends flixel.FlxSubState
{

    public function new() {
        super();
    }
    override function create() {
        
        var data:Array<Dynamic> = Json.parse(Assets.getText('assets/data/artMetadata.json'));

        trace(data.length);
        
        super.create();
    }
}