package ui;

import openfl.geom.Rectangle;

import flixel.FlxG;
import flixel.FlxSprite;

@:forward
abstract SliceBg(FlxSprite) to FlxSprite
{
    inline static var PATH = "assets/images/ui/";
    inline static var SUFFIX = "Bg.png";
    
    static final grids = 
        [ "prompt" => new Rectangle(3, 3, 1, 1)
        , "alert"  => new Rectangle(3, 3, 1, 1)
        ];
    
    inline public function new(x = 0.0, y = 0.0, type = "prompt")
    {
        this = new FlxSprite(x, y);
        this.loadGraphic(PATH + type + SUFFIX, type);
        this.graphic.destroyOnNoUse = false;
    }
    
    inline public function setSize(width:Int, height:Int)
    {
        if (this.graphic.key.indexOf(":") != -1)
        {
            final type = this.graphic.key.split(":")[0];
            this.loadGraphic(PATH + type + SUFFIX, type);
        }
        
        final source = this.graphic.bitmap;
        final type = this.graphic.key;
        final key = type + ':${width}x${height}';
        var existingGraphic = FlxG.bitmap.get(key);
        if (existingGraphic != null)
            this.loadGraphic(existingGraphic, key);
        else
        {
            this.makeGraphic(width, height, 0, true, key);
            MouseButtonDrawer.apply9GridTo(source, this.graphic.bitmap, grids[type]);
        }
    }
    
    static public function prompt(x = 0.0, y = 0.0) return new SliceBg(x, y, "prompt");
    static public function alert(x = 0.0, y = 0.0) return new SliceBg(x, y, "alert");
    
}