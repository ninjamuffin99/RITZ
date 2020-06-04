package states;

import flixel.FlxSprite;
import flixel.addons.display.FlxTiledSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.FlxG;

class MainMenuState extends flixel.FlxState
{
    var cheese:FlxTiledSprite;
    override function create() {
        FlxG.sound.playMusic('assets/music/ultracheddar' + BootState.soundEXT);

        var cheeseBG:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFFf2a348);
        add(cheeseBG);

        cheese = new FlxTiledSprite(AssetPaths.cheeseSpaced__png, FlxG.width, FlxG.height);
        cheese.scrollX = 10;
        cheese.scrollY = 10;
        
        add(cheese);

        var overlay:FlxSprite = new FlxSprite().loadGraphic('assets/images/menuOverlay.png');
        add(overlay);

        super.create();
    }

    override function update(elapsed:Float) {
        if (FlxG.keys.justPressed.ONE)
            FlxG.switchState(new AdventureState());
        if (FlxG.keys.justPressed.TWO)
            FlxG.switchState(new RaceState());
        
        super.update(elapsed);

        var scrollShit:Float = FlxG.height * 0.3 * 0.25 * FlxG.elapsed;
        cheese.alpha = 0.1;
        cheese.scrollX -= scrollShit;
        cheese.scrollY += scrollShit;
    }
}