package ui;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.graphics.FlxGraphic;
import ui.BitmapText;
import ui.ButtonGroup;

import openfl.display.BitmapData;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.input.FlxPointer;
import flixel.input.IFlxInput;
import flixel.math.FlxPoint;
import flixel.ui.FlxButton;

import flixel.addons.display.FlxSliceSprite;

using StringTools;

@:noCompletion typedef SimpleMouseButton = TypedMouseButton<BitmapText>;

@:forward
abstract MouseButton(SimpleMouseButton) from SimpleMouseButton to SimpleMouseButton
{
    inline static var emptyBgKey = "MouseButton-empty";
    
    public var lineHeight(get, never):Int;
    inline function get_lineHeight() return this.label.lineHeight;
    
    public var text(get, set):String;
    inline function get_text() return this.label.text;
    inline function set_text(value:String)
    {
        this.label.text = value;
        recenterLabels();
        return value;
    }
    
    inline public function new (x, y, text, type:MouseButtonType = Orange8, ?onClick)
    {
        type = switch (type)
        {
            case Orange8: Nokia8("orange");
            case InputGrid: Nokia8("orange", 23);
            default: type;
        }
        
        var label:BitmapText;
        var graphicType:String;
        var graphicWidth:Int;
        var graphicHeight:Int;
        switch (type)
        {
            case Nokia8(type, width, height):
                label = new Nokia8Text(0, 0, text, 0x0);
                graphicType = type;
                graphicWidth = width == null ? Std.int(label.width) + 4 : width;
                graphicHeight = height == null ? Std.int(label.lineHeight) + 6 : height;
            case Nokia16(type, width, height):
                label = new Nokia16Text(0, 0, text, 0x0);
                graphicType = type;
                graphicWidth = width == null ? Std.int(label.width) + 4 : width;
                graphicHeight = height == null ? Std.int(label.lineHeight) + 6 : height;
            case _: throw "Unhandled type:" + type.getName();
        }
        
        this = new SimpleMouseButton(x, y, label, onClick);
        var graphic:BitmapData = new MouseButtonDrawer(graphicWidth, graphicHeight, graphicType);
        this.loadGraphic(graphic, true, graphicWidth, graphicHeight);
        
        for (i in 0...3)
            this.labelAlphas[i] = 1;
        
        recenterLabels();
    }
    
    public function recenterLabels():Void
    {
        var offset = FlxPoint.get
        (
            Math.round((this.width - this.label.width + 1) / 2),
            Math.ceil((this.height - 2 - this.label.textHeight) / 2)
        );
        
        this.labelOffsets[0].copyFrom(offset);
        this.labelOffsets[1].copyFrom(offset);
        this.labelOffsets[2].copyFrom(offset);
        this.labelOffsets[2].y += 2;
        
        offset.put();
    }
}

class MouseButtonGroup extends TypedMouseButtonGroup<MouseButton>
{
    var buttonType:MouseButtonType;
    
    public function new(controls, buttonType:MouseButtonType = Orange8)
    {
        this.buttonType = buttonType;
        super(controls);
    }
    
    public function addNewButton(x, y, text, ?onClick):MouseButton
    {
        var button = new MouseButton(x, y, text, buttonType);
        addButton(button, onClick);
        return button;
    }
}

class TypedMouseButton<T:FlxSprite> extends FlxTypedButton<T>
{
    public function new(x, y, ?label:T, ?onClick)
    {
        super(x, y, onClick);
        
        if (label != null)
            this.label = label;
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        label.color = color;
    }
    
    override function onOutHandler()
    {
        // super.onOutHandler();
    }
    
    inline function setAnimation(frame:Int)
    {
        status = frame;
        animation.play(statusAnimations[frame]);
        updateLabelPosition();
        
        var scale = frame == FlxButton.HIGHLIGHT ? 1.4 : 1;
        var angle = frame == FlxButton.HIGHLIGHT ? FlxG.random.int(-10, 10) : 0;
        FlxTween.tween
        (
            this,
            { "scale.x":scale, "scale.y":scale, angle:angle },
            0.15,
            { ease: FlxEase.backOut }
        );
        FlxTween.tween
        (
            this.label,
            { "scale.x":scale, "scale.y":scale, angle:angle },
            0.15,
            { ease: FlxEase.backOut }
        );
    }
    
    public function deselect() setAnimation(FlxButton.NORMAL);
    public function select() setAnimation(FlxButton.HIGHLIGHT);
    public function press() setAnimation(FlxButton.PRESSED);
    inline public function release() select();
    
    override function updateButton()
    {
        if (FlxG.mouse.justMoved)
            super.updateButton();
    }
}

class TypedMouseButtonGroup<T:TypedMouseButton<Dynamic>> extends TypedButtonGroup<T>
{
    public function new (controls)
    {
        super(controls);
        colorDefault = 0xFFffffff;
        colorHilite = 0xFFffffff;
    }
    
    override function addButton(button:T, callback:() -> Void):TypedButtonGroup<T>
    {
        button.onUp.callback = choose.bind(button);
        button.onOver.callback = hilite.bind(button);
        
        return super.addButton(button, callback);
    }
    
    override function set_selected(value:Int):Int
    {
        if (selected != -1 && members[value] != null)
            members[selected].deselect();
        
        super.set_selected(value);
        
        if (value != -1 && members[value] != null)
            members[value].select();
        
        return value;
    }
    
    override function onSelect()
    {
        super.onSelect();
        
        members[selected].press();
    }
    
    override function onSelectAnimComplete()
    {
        super.onSelectAnimComplete();
        members[selected].release();
    }
    override function draw()
    {
        super.draw();
        
        if (selected != -1)
            members[selected].draw();
    }
}