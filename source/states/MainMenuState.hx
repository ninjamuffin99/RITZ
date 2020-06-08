package states;

import flixel.math.FlxAngle;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxSprite;
import flixel.addons.display.FlxTiledSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.FlxG;
import ui.MenuItem;

class MainMenuState extends flixel.FlxState
{
    var cheese:FlxTiledSprite;

    var textMenuItems:Array<String> = ['Single Player', 'Race Mode', 'Options', 'Credits', 'Battle Royale', 'Competitive', "Arms Race", 'Kart Racing']; 
    var grpMenuItems:FlxTypedGroup<MenuItem>;
    var grpMenuBars:FlxTypedGroup<FlxSprite>;

    var curSelected:Int = 0;

    override function create() {
        FlxG.sound.playMusic('assets/music/ultracheddar' + BootState.soundEXT);

        var cheeseBG:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFFf2a348);
        add(cheeseBG);

        cheese = new FlxTiledSprite(AssetPaths.cheeseSpaced__png, FlxG.width, FlxG.height);
        cheese.scrollX = 10;
        cheese.scrollY = 10;
        add(cheese);

        grpMenuItems = new FlxTypedGroup<MenuItem>();
        
        var bullshit:Int = 0;
        for (text in textMenuItems)
        {
            var menuItem:MenuItem = new MenuItem(0, 0, text);
            menuItem.daAngle = bullshit;
            menuItem.targetAngle = bullshit;
            grpMenuItems.add(menuItem);

            bullshit--;
        }

        add(grpMenuItems);
        
        
        var overlay:FlxSprite = new FlxSprite().loadGraphic('assets/images/menuOverlay.png');
        add(overlay);

        super.create();
    }

    override function update(elapsed:Float) {
        if (FlxG.keys.justPressed.ONE)
            FlxG.switchState(new AdventureState());
        if (FlxG.keys.justPressed.TWO)
            FlxG.switchState(new RaceState());
        

        if (FlxG.keys.justPressed.UP)
            curSelected -= 1;
        if (FlxG.keys.justPressed.DOWN)
            curSelected += 1;
        
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


        if (FlxG.keys.justPressed.SPACE)
        {
            var daText:String = textMenuItems[curSelected];

            switch(daText)
            {
                case 'Single Player':
                    FlxG.switchState(new AdventureState());
                case 'Credits':
                    FlxG.switchState(new EndState());
                default:
                    trace('no UI item!');

            }
        }


        super.update(elapsed);

        var scrollShit:Float = FlxG.height * 0.3 * 0.25 * FlxG.elapsed;
        cheese.alpha = 0.1;
        cheese.scrollX -= scrollShit;
        cheese.scrollY += scrollShit;
    }
}