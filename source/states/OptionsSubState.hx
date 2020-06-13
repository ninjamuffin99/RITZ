package states;

import flixel.effects.FlxFlicker;
import flixel.FlxG;
import ui.BitmapText;
import ui.MenuItem;
import flixel.FlxSubState;

class OptionsSubState extends MenuBackend
{
	public static var masterVol:Float = 100;
	public static var musicVol:Float = 100;
	public static var soundVol:Float = 100;
	public static var DXmusic:String = "DX";

    public function new()
    {
		var isDX:Bool = false;
		if (DXmusic != '')
			isDX = true;

		super(['Master Volume', 'Music Volume', 'SFX Volume', 'DX OST', 'Back'], [[masterVol * 100, musicVol * 100, soundVol * 100, isDX], [1, 1, 1, 2, 0]]);

	}

	override function update(elapsed:Float) {
		masterVol = grpMenuItems.members[0].percentage / 100;
		musicVol = grpMenuItems.members[1].percentage / 100;
		soundVol = grpMenuItems.members[2].percentage / 100;


		var curDX:String = DXmusic;

		if (grpMenuItems.members[3].isOn)
			DXmusic = 'DX';
		else
			DXmusic = "";

		if (curDX != DXmusic)
		{
			// Change so can dynamically switch music in-game
			// FlxG.sound.playMusic('assets/music/fluffydream' + OptionsSubState.DXmusic + BootState.soundEXT);
		}
	
		FlxG.watch.addQuick('masterVol', masterVol);


		if (FlxG.sound.music != null)
			FlxG.sound.music.volume = masterVol * musicVol;

		super.update(elapsed);

		if (FlxG.keys.justPressed.SPACE && !selected && grpMenuItems.members[curSelected].itemType == MenuItem.SELECTION)
		{
			FlxG.sound.play('assets/sounds/startbleep' + BootState.soundEXT);
			FlxFlicker.flicker(grpMenuItems.members[curSelected], 0.5, 0.04, false, true, function(flic:FlxFlicker)
			{
				var daText:String = textMenuItems[curSelected];
				
				if (daText == 'Back')
				{
					close();
					FlxG.state.openSubState(new MenuBackend(MainMenuState.textMenuItems));
				}
			});
		}
	}
}