package states;

import data.PlayerSettings;
import ui.Controls;
import ui.BitmapText;
import ui.MenuItem;

import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSprite;
import flixel.effects.FlxFlicker;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;

class MenuBackend extends flixel.FlxSubState
{
    var textMenuItems:Array<String> = ['Master Volume', 'Sound Volume', 'Music Volume', 'DX OST'];
    var optionValues:Array<Dynamic> = [
        [
            1, 1, 1, true
        ],
        [
            0, 0, 0, 0
        ]
    ]; 
    
    var grpMenuItems:FlxTypedGroup<MenuItem>;
    var grpMenuBars:FlxTypedGroup<FlxSprite>;

    public var curSelected:Int = 0;
    var selected:Bool = false;
    
    var controls(get, never):Controls;
    inline function get_controls() return PlayerSettings.player1.controls;
    
    public function new(menuItems:Array<String>, ?optionItems:Array<Dynamic>)
    {
        super();

        if (menuItems != null)
            textMenuItems = menuItems;
        if (optionItems != null)
            optionValues = optionItems;

        grpMenuItems = new FlxTypedGroup<MenuItem>();
        
        var bullshit:Int = 0;
        for (text in textMenuItems)
        {
            addMenuItem(text, bullshit, optionValues[1][Std.int(bullshit * -1)]);

            bullshit--;
        }

        add(grpMenuItems);

        var overlay:FlxSprite = new FlxSprite().loadGraphic('assets/images/ui/main_menu/overlay.png');
        add(overlay);
    }

    public function addMenuItem(text:String, bullshit:Int, itemType:Int = 0):MenuItem
    {
        var menuItem:MenuItem = new MenuItem(0, 0, controls, text, itemType, optionValues[0][Std.int(bullshit * -1)]);
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

        if (controls.UP_P || controls.DOWN_P)
        {
            var randomSound:Int = 0;
    
            if (FlxG.random.bool())
                randomSound = 2;
    
            if (controls.UP_P)
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
    
        if (controls.ACCEPT && !selected && grpMenuItems.members[curSelected].itemType == MenuItem.SELECTION)
        {
            FlxG.sound.play('assets/sounds/startbleep' + BootState.soundEXT);
            FlxFlicker.flicker(grpMenuItems.members[curSelected], 0.5, 0.04, false, true, function(flic:FlxFlicker)
            {
                var daText:String = textMenuItems[curSelected];

                switch(daText)
                {
                    case 'Single Player':
                        stateShit(new AdventureState());
                    case 'Credits':
                        stateShit(new EndState());
                    case 'Race Mode':
                        stateShit(new RaceState());
                    case 'Gallery':
                        close();
                        FlxG.state.openSubState(new GalleryMenuState());
                    case 'Options':
                        close();
                        FlxG.state.openSubState(new OptionsSubState());
                    default:
                        trace('no UI item!');

                }

                // FlxG.sound.play('assets/sounds/ritzstartjingle' + BootState.soundEXT);
               
            });
        }
    
        
        super.update(elapsed);
    }

    private function stateShit(daState:FlxState):Void
    {
        FlxG.camera.fade(FlxColor.BLACK, 2, false, function()
            {
                FlxG.switchState(daState);
            });

    }
}