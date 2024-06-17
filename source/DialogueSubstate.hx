package;

import flixel.system.FlxAssets;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.FlxSubState;

class DialogueSubstate extends FlxSubState
{

    private var dialogueText:TypeTextTwo;
    private var blackBarTop:FlxSprite;
    private var blackBarBottom:FlxSprite;

    public function new(d:String) {
        super();

        blackBarTop = new FlxSprite();
        blackBarTop.makeGraphic(FlxG.width, Std.int(FlxG.height * 0.22), FlxColor.BLACK);
        blackBarTop.scrollFactor.set();
        blackBarTop.y -= blackBarTop.height;
        add(blackBarTop);

        blackBarBottom = new FlxSprite();
        blackBarBottom.makeGraphic(FlxG.width, Std.int(FlxG.height * 0.22), FlxColor.BLACK);
        blackBarBottom.scrollFactor.set();
        blackBarBottom.y = FlxG.height;
        add(blackBarBottom);

        FlxTween.tween(blackBarTop, {y: -1}, 0.25, {ease:FlxEase.quadIn});
        FlxTween.tween(blackBarBottom, {y: Std.int(FlxG.height - blackBarBottom.height)}, 0.25, {ease:FlxEase.quadIn});

        dialogueText = new TypeTextTwo(0, 0, FlxG.width, d, 16);
        dialogueText.scrollFactor.set();
        dialogueText.sounds = [FlxG.sound.load('assets/sounds/talksound' + BootState.soundEXT), FlxG.sound.load('assets/sounds/talksound1' + BootState.soundEXT)];
        dialogueText.finishSounds = true;
        dialogueText.skipKeys = ["E", "F", 'X', 'SPACE', 'Z', 'W', "UP"];
		add(dialogueText);

		dialogueText.start();
    }

    override function update(elapsed:Float) {

        var gamepad = FlxG.gamepads.lastActive;
        if (gamepad != null)
        {
            if (gamepad.justPressed.ANY)
            {
                if (dialogueText.isFinished)
                    close();
                dialogueText.skip();
            }
        }
        
        if (FlxG.keys.anyJustPressed(dialogueText.skipKeys) && dialogueText.isFinished)
            close();
        
        super.update(elapsed);
    }
}