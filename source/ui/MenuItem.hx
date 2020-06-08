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
    public var targetAngle:Float = 0;
    var angleSpeed:Float = 0;
    public function new(x:Float, y:Float, title:String)
    {
        super(x, y);
        var textBG:FlxSprite = new FlxSprite().loadGraphic('assets/images/menuBar.png');

        textBG.alpha = 0.4;
        add(textBG);

        var coolText:BitmapText = new BitmapText(0, 0, title);
        coolText.alignment = FlxTextAlign.CENTER;
        coolText.x = textBG.x + 5;
        coolText.y = textBG.y;
        add(coolText);

        angleSpeed = 11 * 0.0166;
    }

    
    override function update(elapsed:Float) {
        super.update(elapsed);

        x = 330 + Math.cos(FlxAngle.asRadians((daAngle * daAngleOffset) + 180)) * 330;
        y = 140 + Math.sin(FlxAngle.asRadians((daAngle * daAngleOffset)+ 180)) * 140;

        
        if (targetAngle > daAngle)
            daAngle += angleSpeed;
        if (targetAngle < daAngle)
            daAngle -= angleSpeed;

    }
}