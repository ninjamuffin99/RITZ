package states;

import ui.BitmapText;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.effects.FlxFlicker;
import ui.MenuItem;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxSubState;

class MenuBackend extends FlxSubState
{
    var textMenuItems:Array<String> = ['Single Player', 'Race Mode', 'Options', 'Credits', 'Battle Royale', 'Competitive', "Arms Race", 'Kart Racing']; 
    var grpMenuItems:FlxTypedGroup<MenuItem>;
    var grpMenuBars:FlxTypedGroup<FlxSprite>;

    var curSelected:Int = 0;
    var selected:Bool = false;

    public function new(menuItems:Array<String>)
    {
        super();

        if (menuItems != null)
            textMenuItems = menuItems;

        grpMenuItems = new FlxTypedGroup<MenuItem>();
        
        var bullshit:Int = 0;
        for (text in textMenuItems)
        {
            addMenuItem(text, bullshit, 1);

            bullshit--;
        }

        add(grpMenuItems);

        var overlay:FlxSprite = new FlxSprite().loadGraphic('assets/images/menuOverlay.png');
        add(overlay);
    }

    public function addMenuItem(text:String, bullshit:Int, itemType:Int = 0):MenuItem
    {
        var menuItem:MenuItem = new MenuItem(0, 0, text, itemType);
        menuItem.daAngle = bullshit;
        menuItem.targetAngle = bullshit;
        grpMenuItems.add(menuItem);

        return menuItem;
    }

    override function update(elapsed:Float) 
    {

        for (i in 0...grpMenuItems.members.length)
        {
            if (i == curSelected)
            {
                grpMenuItems.members[i].isSelected = true;
            }
            else
                grpMenuItems.members[i].isSelected = false;
        }


        if (FlxG.keys.anyJustPressed(['DOWN', 'UP']))
        {
            var randomSound:Int = 0;
    
            if (FlxG.random.bool())
                randomSound = 2;
    
            if (FlxG.keys.justPressed.UP)
            {
                curSelected -= 1;
                FlxG.sound.play('assets/sounds/Munchsound' + Std.string(2 + randomSound) + BootState.soundEXT);
            }  
            else
            {
    
                curSelected += 1;
                FlxG.sound.play('assets/sounds/Munchsound' + Std.string(1 + randomSound) + BootState.soundEXT);
            }
        }
                
            
            if (curSelected < 0)
                curSelected = textMenuItems.length - 1;
            if (curSelected >= textMenuItems.length)
                curSelected = 0;
    
    
            var bullshit:Int = 0;
            for (item in grpMenuItems.members)
            {
                item.targetAngle = bullshit + curSelected;
                bullshit--;
            }
    
            // 281 58
    
        if (FlxG.keys.justPressed.SPACE && !selected)
        {
            FlxG.sound.play('assets/sounds/startbleep' + BootState.soundEXT);
            FlxFlicker.flicker(grpMenuItems.members[curSelected], 0.5, 0.04, false, true, function(flic:FlxFlicker)
            {
                // FlxG.sound.play('assets/sounds/ritzstartjingle' + BootState.soundEXT);
                FlxG.camera.fade(FlxColor.BLACK, 2, false, function()
                {
    
                    var daText:String = textMenuItems[curSelected];
    
                    switch(daText)
                    {
                        case 'Single Player':
                            FlxG.switchState(new AdventureState());
                        case 'Credits':
                            FlxG.switchState(new EndState());
                        case 'Race Mode':
                            FlxG.switchState(new RaceState());
                        default:
                            trace('no UI item!');
    
                    }
                });
            });
        }
    
        
        super.update(elapsed);
    }
}