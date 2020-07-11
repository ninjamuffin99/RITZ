package states;

import ui.MenuItem;

import flixel.FlxG;
import flixel.effects.FlxFlicker;
import flixel.FlxSubState;

class GalleryMenuState extends MenuBackend
{
    public function new():Void
    {
        super(["Art Gallery", "Music Gallery", "Sound Test", "Back"]);
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        if (controls.ACCEPT && !selected && grpMenuItems.members[curSelected].itemType == MenuItem.SELECTION)
        {
            FlxG.sound.play('assets/sounds/startbleep' + BootState.soundEXT);
            FlxFlicker.flicker(grpMenuItems.members[curSelected], 0.5, 0.04, false, true, function(flic:FlxFlicker)
            {
                close();
                
                var daText:String = textMenuItems[curSelected];
                switch (daText)
                {
                    case 'Back':
						FlxG.state.openSubState(new MenuBackend(MainMenuState.textMenuItems));
					case 'Art Gallery':
						FlxG.state.openSubState(new GalleryState());
					case 'Music Gallery':
						FlxG.state.openSubState(new MusicGalleryState(controls));

                }
                if (daText == 'Back')
                {
                    
                }

            });
        }
    }
}