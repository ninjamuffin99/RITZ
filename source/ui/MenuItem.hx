package ui;

import flixel.math.FlxAngle;
import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;

class MenuItem extends FlxSpriteGroup
{
    public var daAngle:Float = 0;
    public var daAngleOffset:Float = 30;
    public function new(x:Float, y:Float, title:String)
    {
        super(x, y);
        var textBG:FlxSprite = new FlxSprite().makeGraphic(Std.int(FlxG.width / 2), 22, FlxColor.RED);

        textBG.alpha = 0.4;
        add(textBG);

        var coolText:FlxText = new FlxText(0, 0, 0, title, 16);
        coolText.color = FlxColor.BLACK;
        coolText.alignment = FlxTextAlign.CENTER;
        coolText.x = textBG.x;
        coolText.y = textBG.y;
        add(coolText);
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        x = 330 + Math.cos(FlxAngle.asRadians((daAngle * daAngleOffset) + 180)) * 330;
        y = 140 + Math.sin(FlxAngle.asRadians((daAngle * daAngleOffset)+ 180)) * 100;

    }
}