package ui;

import data.PlayerSettings;
import states.BootState;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

class DialogueSubstate extends flixel.FlxSubState
{
    public var dialogueText:TypeTextTwo;
    public var blackBarTop:FlxSprite;
    public var blackBarBottom:FlxSprite;
    public var uiCamera:FlxCamera;
    public var controls:Controls = null;

    public function new(dialogue:String, controls:Null<Controls>, ?playerCamera:PlayCamera, startNow = true) {
        super();
        this.controls = controls;
        
        uiCamera = new FlxCamera();
        uiCamera.x = playerCamera.x;
        uiCamera.y = playerCamera.y;
        uiCamera.width = playerCamera.width;
        uiCamera.height = playerCamera.height;
        uiCamera.bgColor = 0;
        cameras = [uiCamera];
        FlxG.cameras.add(uiCamera);
        
        var textSize = 16;//uiCamera.width < FlxG.width ? 8 : 16;
        dialogueText = new TypeTextTwo(0, 0, uiCamera.width, parseDialogue(dialogue), textSize);
        dialogueText.sounds = [FlxG.sound.load('assets/sounds/talksound' + BootState.soundEXT), FlxG.sound.load('assets/sounds/talksound1' + BootState.soundEXT)];
        dialogueText.finishSounds = true;
        dialogueText.skipKeys = [];
        dialogueText.visible = false;
        
        blackBarBottom = new FlxSprite();
        blackBarBottom.makeGraphic(uiCamera.width, Std.int(uiCamera.height * 0.22), FlxColor.BLACK);
        blackBarBottom.y = uiCamera.height;
        
        blackBarTop = new FlxSprite();
        final height = Math.max(blackBarBottom.height, dialogueText.finalHeight);
        blackBarTop.makeGraphic(uiCamera.width, Std.int(height), FlxColor.BLACK);
        blackBarTop.y = -blackBarTop.height;
        
        add(blackBarBottom);
        add(blackBarTop);
        add(dialogueText);
        
        FlxTween.tween(blackBarTop, {y: 0}, 0.25, {ease:FlxEase.quadIn});
        FlxTween.tween(blackBarBottom, {y: Std.int(uiCamera.height - blackBarBottom.height)}, 0.25, {ease:FlxEase.quadIn});
        
        if (startNow)
            start(0.25);
    }
    
    function parseDialogue(d:String):String
    {
        if (~/\{.+\}/.match(d))
        {
            var start = d.indexOf("{");
            while(start != -1)
            {
                var end = d.indexOf("}", start);
                if (end == -1)
                    throw '"{" token found with no matching "}" token';
                var inputName = d.substring(start + 1, end);
                trace('token $inputName');
                d = d.split('{$inputName}')
                    .join(controls.getDialogueNameFromToken(inputName));
                start = d.indexOf("{", end + 1);
            }
        }
        return d;
    }
    
    inline public function start(delay = 0.05):Void
    {
        dialogueText.visible = true;
        dialogueText.start(delay);
    }

    override function update(elapsed:Float) {

        if (dialogueText.visible
        && controls != null && (controls.BACK || controls.ACCEPT || controls.TALK))
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
        
        closeCallback();
    }
    
    function startClose():Void
    {
        FlxTween.tween(blackBarTop, {y:-blackBarTop.height}, 0.25, {ease:FlxEase.quadIn});
        FlxTween.tween(blackBarBottom, {y: FlxG.height}, 0.25,
            { ease:FlxEase.quadIn, onComplete: (_)->close() }
        );
        dialogueText.visible = false;
        controls = null;
    }
}

@:forward
abstract ZoomDialogueSubstate(DialogueSubstate) to DialogueSubstate
{
    inline public function new(dialogue:String, focalPoint:FlxPoint, settings:PlayerSettings, onComplete:()->Void)
    {
        final camera = settings.camera;
        final oldZoom = camera.zoom;
        final oldCamPos = camera.scroll.copyTo();
        this = new DialogueSubstate(dialogue, settings.controls, camera, false);
        
        final zoomAmount = 2;
        final yOffset = (this.blackBarTop.height - this.blackBarBottom.height) / 2 / zoomAmount;
        tweenCamera(camera, 0.25, oldZoom * zoomAmount,
            focalPoint.x - camera.width / 2,
            focalPoint.y - camera.height / 2 - yOffset,
            (_)->this.start()
        );
        focalPoint.putWeak();
        
        this.closeCallback = function ()
        {
            tweenCamera(camera, 0.3, oldZoom, oldCamPos.x, oldCamPos.y, (_)->onComplete());
            oldCamPos.put();
        };
    }
    
    inline function tweenCamera(camera:FlxCamera, time:Float, zoom:Float, x:Float, y:Float, onComplete:(FlxTween)->Void):FlxTween
    {
        return FlxTween.tween(camera, { zoom: zoom, "scroll.x":x, "scroll.y":y }, time, { onComplete:onComplete });
    }
    
    public function getViewRect(?rect:FlxRect):FlxRect
    {
        if (rect == null)
            rect = new FlxRect();
        
        rect.y = this.blackBarTop.height;
        rect.width = this.uiCamera.width;
        rect.height = this.uiCamera.height - this.blackBarBottom.height;
        return rect;
    }
}