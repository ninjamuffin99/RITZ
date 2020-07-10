package states;

import ui.Controls;
import ui.BitmapText;

import flixel.FlxG;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.text.FlxText;
import flixel.system.FlxSound;

import lime.utils.Assets;
import haxe.Json;

class MusicGalleryState extends flixel.FlxSubState
{
    private var selectedSong:String = '';
    private var curSong:String = '';
    private var curSelected:Int = 0;
    private var songList:Array<String> = [];

    private var txtSelectedSong:BitmapText;
    private var txtCurSong:BitmapText;
    private var txtDescription:BitmapText;
    
    var data:Array<Dynamic>;
    var songLengths:Array<String> = [];
    var isPlaying:Bool = false;
    final controls:Controls;

    public function new(controls)
    {
        this.controls = controls;
        super();
        

        data = Json.parse(Assets.getText('assets/data/musicMetadata.json'));

        txtSelectedSong = new BitmapText(20, 20, "Song");
        add(txtSelectedSong);

        txtDescription = new BitmapText(20, 60);
        txtDescription.fieldWidth = Std.int(FlxG.width - 100);
        txtDescription.autoSize = false;
        add(txtDescription);
        

        txtCurSong = new BitmapText(20, FlxG.height - 20);
        add(txtCurSong);


        for (i in data)
        {
            var daSound:FlxSound = new FlxSound().loadEmbedded(i.path + BootState.soundEXT);
            var totalS:Int = Math.round(daSound.length / 1000);
            var seconds:Int = totalS % 60;
            var minutes:Int = Math.floor(totalS / 60); 

            var zeroInsert:String = '';

            if (seconds < 10)
                zeroInsert = '0';

            songLengths.push(minutes + ":" + zeroInsert + seconds);
            // Math.floor(Std.parseInt(songLengths[curSelected]) / 60) + ":" + Math.round(songLengths[curSelected]);
            trace(daSound.length / 1000);
        }

    }

    override function update(elapsed:Float) {
        
        if (controls.LEFT_P || controls.RIGHT_P)
        {
            if (controls.LEFT_P)
                curSelected -= 1;
            if (controls.RIGHT_P)
                curSelected += 1;
    
            if (curSelected < 0)
                curSelected = data.length - 1;
            if (curSelected >= data.length)
                curSelected = 0;

            trace(data[curSelected].description);

        }

        if (controls.BACK)
        {
            close();
            FlxG.state.openSubState(new GalleryMenuState());
        }
        
        


        txtDescription.text = data[curSelected].description;
        txtSelectedSong.text = Std.string(curSelected + 1) + ". " + data[curSelected].title + " - " + songLengths[curSelected];

        if (controls.ACCEPT)
        {
            FlxG.sound.playMusic(data[curSelected].path + BootState.soundEXT);
            
            if (!isPlaying)
            {
                txtCurSong.y += 20;
                FlxTween.tween(txtCurSong, {y: txtCurSong.y - 20}, 0.8, {ease:FlxEase.quadOut});
            }

            isPlaying = true;
            curSong = data[curSelected].title;
        }

        if (isPlaying)
        {
            txtCurSong.text = "Currently Playing: " + curSong;
        }

        super.update(elapsed);
    }
}