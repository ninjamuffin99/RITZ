package ui;

import ui.Inputs;

import flixel.FlxCamera;
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
    private var uiCamera:FlxCamera;

    public function new(d:String, startNow = true) {
        super();
        
        uiCamera = new FlxCamera();
        uiCamera.scroll.x -= uiCamera.width * 2;//showEmpty
        uiCamera.bgColor = 0;
        FlxG.cameras.add(uiCamera);
        
        blackBarTop = new FlxSprite();
        blackBarTop.makeGraphic(FlxG.width, Std.int(FlxG.height * 0.22), FlxColor.BLACK);
        blackBarTop.scrollFactor.set();
        blackBarTop.y = -blackBarTop.height;
        blackBarTop.camera = uiCamera;
        add(blackBarTop);

        blackBarBottom = new FlxSprite();
        blackBarBottom.makeGraphic(FlxG.width, Std.int(FlxG.height * 0.22), FlxColor.BLACK);
        blackBarBottom.scrollFactor.set();
        blackBarBottom.y = FlxG.height;
        blackBarBottom.camera = uiCamera;
        add(blackBarBottom);

        FlxTween.tween(blackBarTop, {y: 0}, 0.25, {ease:FlxEase.quadIn});
        FlxTween.tween(blackBarBottom, {y: Std.int(FlxG.height - blackBarBottom.height)}, 0.25, {ease:FlxEase.quadIn});

        dialogueText = new TypeTextTwo(0, 0, FlxG.width, d, 16);
        dialogueText.scrollFactor.set();
        dialogueText.sounds = [FlxG.sound.load('assets/sounds/talksound' + BootState.soundEXT), FlxG.sound.load('assets/sounds/talksound1' + BootState.soundEXT)];
        dialogueText.finishSounds = true;
        dialogueText.skipKeys = [];
        dialogueText.camera = uiCamera;
        dialogueText.visible = false;
        add(dialogueText);

        if (startNow)
            start(0.25);
    }
    
    inline public function start(delay = 0.05):Void
    {
        dialogueText.visible = true;
        dialogueText.start(delay);
    }

    override function update(elapsed:Float) {

        if (dialogueText.visible
        && (Inputs.justPressed.BACK || Inputs.justPressed.ACCEPT || Inputs.justPressed.TALK))
        {
            if (dialogueText.isFinished)
                startClose();
            else
                dialogueText.skip();
        }
        
        super.update(elapsed);
    }
    
    override function close()
    {
        FlxG.cameras.remove(uiCamera);
        
        super.close();
    }
    
    function startClose():Void
    {
        FlxTween.tween(blackBarTop, {y:-blackBarTop.height}, 0.25, {ease:FlxEase.quadIn});
        FlxTween.tween(blackBarBottom, {y: FlxG.height}, 0.25,
            { ease:FlxEase.quadIn, onComplete: (_)->close() }
        );
        dialogueText.visible = false;
    }
}