package ui;

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
    
    inline public function new (x, y, text, bg = "orange38x17", ?onClick)
    {
        if (bg.endsWith("x17"))
            this = new SimpleMouseButton(x, y, new Nokia8Text(0, 0, text, 0x0), onClick);
        else if (bg.endsWith("x22"))
            this = new SimpleMouseButton(x, y, new Nokia16Text(0, 0, text, 0x0), onClick);
        else
            throw "Unhandled height: " + bg.split("x").pop();
        
        if (bg == null)
        {
            this.makeGraphic(1, 1, 0x0, false, emptyBgKey);
            this.width = this.label.width;
            this.height = this.label.height;
        }
        else
        {
            bg = 'assets/images/ui/buttons/$bg.png';
            this.loadGraphic(bg);
            this.loadGraphic(bg, true, Std.int(this.width / 3), Std.int(this.height));
        }
        
        for (i in 0...3)
            this.labelAlphas[i] = 1;
        
        recenterLabels();
    }
    
    public function recenterLabels():Void
    {
        if (this.graphic.key == emptyBgKey)
        {
            for (i in 0...3)
                this.labelOffsets[i].set(0, 0);
        }
        else
        {
            var offset = FlxPoint.get
            (
                (this.width - this.label.width) / 2,
                (this.height - 2 - lineHeight) / 2
            );
            
            switch this.height
            {
                case 17: offset.add(1, 2);
                case 22: offset.add(2, 0);
            }
            
            this.labelOffsets[0].copyFrom(offset);
            this.labelOffsets[1].copyFrom(offset);
            this.labelOffsets[2].copyFrom(offset);
            this.labelOffsets[2].y += 2;
            
            offset.put();
        }
    }
}

class MouseButtonGroup extends TypedMouseButtonGroup<MouseButton>
{
    var buttonType:String;
    
    public function new(controls, buttonType = "orange25x17")
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
    }
    
    public function deselect() setAnimation(FlxButton.NORMAL);
    public function select() setAnimation(FlxButton.HIGHLIGHT);
    public function press() setAnimation(FlxButton.PRESSED);
    inline public function release() select();
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
}