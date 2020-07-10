package ui;

import openfl.geom.Matrix;
import openfl.geom.Rectangle;
import openfl.display.BitmapData;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;

import flixel.addons.display.FlxSliceSprite;

private typedef FrameInfo = { rect:Rectangle, grid:Rectangle };

@:forward
abstract MouseButtonDrawer(BitmapData) from BitmapData to BitmapData
{
    static public final rects:Map<String, Array<FrameInfo>> =
    [
        "orange"=>
            [ { rect:new Rectangle( 0, 0, 7, 9), grid:new Rectangle(3, 3, 1, 1) }
            , { rect:new Rectangle( 7, 0, 7, 9), grid:new Rectangle(3, 3, 1, 1) }
            , { rect:new Rectangle(14, 0, 7, 9), grid:new Rectangle(3, 5, 1, 1) }
            ]
    ];
    
    public function new (width:Int, height:Int, type = "orange")
    {
        final key = generatekey(width, height, type);
        var graphic = FlxG.bitmap.get(key);
        
        if (graphic == null)
            graphic = create(width, height, type);
        
        this = graphic.bitmap;
    }
    
    static function create(width:Int, height:Int, type:String):FlxGraphic
    {
        var source = FlxG.bitmap.add('assets/images/ui/buttons/$type.png').bitmap;
        var dest = new FlxSprite().makeGraphic(width * 3, height, 0x0, generatekey(width, height, type));
        var destRect = new Rectangle(0, 0, width, height);
        for (frame in 0...3)
        {
            apply9GridTo
            (
                source,
                dest.graphic.bitmap,
                rects[type][frame].grid,
                rects[type][frame].rect,
                destRect
            );
            destRect.x += width;
        }
        
        return dest.graphic;
    }
    
    static inline function generatekey(width:Int, height:Int, type:String):String
    {
        return 'MouseButton:${type}_${width}x${height}';
    }
    
    static public function apply9GridTo
    (
        src:BitmapData,
        target:BitmapData,
        grid:Rectangle,
        ?srcRect:Rectangle,
        ?destRect:Rectangle
    ):BitmapData
    {
        if (srcRect == null) srcRect = src.rect;
        if (destRect == null) destRect = target.rect;
        
        var sampleRect = new Rectangle();
        var targetRect = new Rectangle();
        src.lock();
        
        // --- TOP LEFT
        sampleRect.x = srcRect.x;
        sampleRect.y = srcRect.y;
        targetRect.x = destRect.x;
        targetRect.y = destRect.y;
        sampleRect.width  = targetRect.width  = grid.x;
        sampleRect.height = targetRect.height = grid.y;
        drawTo(src, target, targetRect, sampleRect);
        
        // --- TOP
        sampleRect.x = srcRect.x + grid.x;
        sampleRect.width = grid.width;
        targetRect.x = destRect.x + grid.x;
        targetRect.width = destRect.width - srcRect.width + grid.width;
        drawTo(src, target, targetRect, sampleRect);
        
        // --- TOP RIGHT
        sampleRect.x = srcRect.x + grid.right;
        targetRect.width = sampleRect.width = srcRect.width - grid.right;
        targetRect.x = destRect.right - sampleRect.width;
        drawTo(src, target, targetRect, sampleRect);
        
        // --- RIGHT
        sampleRect.y = srcRect.y + grid.y;
        sampleRect.height = grid.height;
        targetRect.height = destRect.height - srcRect.height + grid.height;
        targetRect.y = destRect.y + grid.y;
        drawTo(src, target, targetRect, sampleRect);
        
        // --- BOTTOM RIGHT
        sampleRect.y = srcRect.y + grid.bottom;
        targetRect.height = sampleRect.height = srcRect.height - grid.bottom;
        targetRect.y = destRect.bottom - sampleRect.height;
        drawTo(src, target, targetRect, sampleRect);
        
        // --- BOTTOM
        sampleRect.width = grid.width;
        sampleRect.x = srcRect.x + grid.x;
        targetRect.x = destRect.x + grid.x;
        targetRect.width = destRect.width - srcRect.width + grid.width;
        drawTo(src, target, targetRect, sampleRect);
        
        // --- BOTTOM LEFT
        sampleRect.x = srcRect.x;
        targetRect.width = sampleRect.width = grid.x;
        targetRect.x = destRect.x;
        drawTo(src, target, targetRect, sampleRect);
        
        // --- LEFT
        sampleRect.y = srcRect.y + grid.y;
        sampleRect.height = grid.height;
        targetRect.height = destRect.height - srcRect.height + grid.height;
        targetRect.y = destRect.y + grid.y;
        drawTo(src, target, targetRect, sampleRect);
        
        // ---CENTER
        sampleRect.x = srcRect.x + grid.x;
        targetRect.x = destRect.x + grid.x;
        sampleRect.width = grid.width;
        targetRect.width = destRect.width - srcRect.width + grid.width;
        drawTo(src, target, targetRect, sampleRect);
        
        return target;
    }
    
    static public function drawTo(src:BitmapData, target:BitmapData, ?destRect:Rectangle, ?srcRect:Rectangle):Void
    {
        
        if (destRect == null)
            destRect = target.rect;
        
        if (srcRect == null)
            srcRect = src.rect;
        
        if (destRect.width == srcRect.width && destRect.height == srcRect.height)
        {
            target.copyPixels
            (
                src,
                srcRect,
                destRect.topLeft
            );
        }
        else
        {
            var mat:Matrix = new Matrix();
            mat.translate(-srcRect.x, -srcRect.y);
            mat.scale(destRect.width / srcRect.width, destRect.height / srcRect.height);
            mat.translate(destRect.x, destRect.y);
            target.draw(src, mat, null, null, destRect, false);
        }
    }
}