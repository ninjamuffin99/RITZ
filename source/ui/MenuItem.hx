package ui;

import flixel.math.FlxMath;
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

    public var itemType:Int = 0;

    public static var SELECTION:Int = 0;
    public static var PERCENTAGE:Int = 1;
    public static var TOGGLE:Int = 2;

    public var isOn:Bool = false;
    public var percentage:Float = 100;

    public var txtPercentage:BitmapText;
    public var isSelected:Bool = false;
    public function new(x:Float, y:Float, title:String, itemType:Int = 0)
    {
        super(x, y);
        var textBG:FlxSprite = new FlxSprite().loadGraphic('assets/images/menuBar.png');

        this.itemType = itemType;

        textBG.alpha = 0.4;
        add(textBG);

        var coolText:BitmapText = new BitmapText(0, 0, title);
        coolText.alignment = FlxTextAlign.CENTER;
        coolText.x = textBG.x + 5;
        coolText.y = textBG.y;
        add(coolText);

        if (itemType == PERCENTAGE)
        {
            txtPercentage = new BitmapText(170, 0, "100%");
		    add(txtPercentage);
        }


        angleSpeed = 11 * 0.0166;
    }

    
    override function update(elapsed:Float) {
        super.update(elapsed);

        if (isSelected)
        {
            if (itemType == PERCENTAGE)
            {
                if (FlxG.keys.justPressed.LEFT)
                    percentage -= 5;
                if (FlxG.keys.justPressed.RIGHT)
                    percentage += 5;
                
                percentage = FlxMath.bound(percentage, 0, 100);

                txtPercentage.text = percentage + "%";
            }
        }
        

        x = 330 + Math.cos(FlxAngle.asRadians((daAngle * daAngleOffset) + 180)) * 330;
        y = 140 + Math.sin(FlxAngle.asRadians((daAngle * daAngleOffset)+ 180)) * 140;

        
        if (targetAngle > daAngle)
            daAngle += angleSpeed;
        if (targetAngle < daAngle)
            daAngle -= angleSpeed;

    }
}