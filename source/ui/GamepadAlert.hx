package ui;

import states.PlayState;
import data.PlayerSettings;
import ui.Controls;

import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.FlxSubState;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.math.FlxPoint;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;

class GamepadAlert extends FlxSubState
{
    // @:allow(ui.GamepadAlert.Controller)
    static public inline var DISTANCE = 100;
    var title:BitmapText;
    var p1:BitmapText;
    var p2:BitmapText;
    var controllers = new FlxTypedGroup<Controller>();
    var state:State;
    
    override function create()
    {
        super.create();
        state = Intro;
        
        camera = new FlxCamera();
        camera.bgColor = 0x0;
        FlxG.cameras.add(camera);
        
        title = new BitmapText(0, 0, "GAMEPAD CONNECTED");
        title.screenCenter(X);
        title.y = -title.lineHeight;
        add(title);
        
        controllers.kill();
        FlxTween.tween(title, { y: 8 }, 0.25, { ease:FlxEase.backOut, onComplete:(_)->onAlertIn() });
    }
    
    function onAlertIn()
    {
        state = Selecting;
        add(controllers).revive();
        
        inline function createPlayerSlot(alignment:Int, text:String)
        {
            var field = new BitmapText
            (
                title.x + title.width / 2 + alignment * DISTANCE,
                title.y + title.height + 8,
                text
            );
            field.offset.set(Std.int(field.width / 2), Std.int(field.height / 2));
            field.scale.set(0, 0);
            scaleToInTime(field, 1, 0.15);
            add(field);
            return field;
        }
        
        p1 = createPlayerSlot(-1, "P1");
        p2 = createPlayerSlot(1, "P2");
        createPlayerSlot(0, "NONE");
        
        var rowY = p1.y + p1.height;
        var keysSprite = new Controller(0, rowY, null, P1);
        controllers.add(keysSprite);
        rowY += keysSprite.height * 1.5;
        
        for (i in 0...newGamepads.length)
        {
            var padSprite = new Controller(0, rowY, newGamepads[i]);
            controllers.add(padSprite);
            rowY += padSprite.height * 1.5;
        }
    }
    
    override function update(elapsed:Float)
    {
        var prevUnlocked:Array<Controller> = null;
        if (state == Selecting)
            prevUnlocked = controllers.members.filter((controller)->!controller.locked);
        
        controllers.alive = state == Selecting;
        super.update(elapsed);
        
        if (state == Selecting)
        {
            var allLocked = true;
            for (i=>controller in controllers.members)
            {
                if (!controller.locked)
                {
                    allLocked = false;
                    break;
                }
            }
            
            p1.borderColor = BitmapText.DEFAULT_BORDER_COLOR;
            p2.textColor = BitmapText.DEFAULT_BORDER_COLOR;
            if (allLocked)
            {
                // check valid selection
                var p1Devices = new Array<Controller>();
                var p2Devices = new Array<Controller>();
                for (controller in controllers.members)
                {
                    switch (controller.player)
                    {
                        case P1: p1Devices.push(controller);
                        case P2: p2Devices.push(controller);
                        case None:
                    }
                }
                
                var isValid = true;
                var wiggleTime = 0.5;
                if (p1Devices.length == 0)
                {
                    isValid = false;
                    p1.borderColor = 0xFFac3232;
                    wiggleX(p1, 16, wiggleTime);
                }
                
                if (PlayerSettings.numAvatars == 2 && p2Devices.length == 0)
                {
                    isValid = false;
                    p2.borderColor = 0xFFac3232;
                    wiggleX(p2, 16, wiggleTime);
                }
                
                if (isValid)
                {
                    if (PlayerSettings.numAvatars == 1 && p2Devices.length > 0)
                    {
                        showConfirmationPrompt
                        (
                            p2Devices,
                            "Join in? (P2)",
                            confirmDeviceSelections,
                            ()->
                            {
                                for (controller in p2Devices)
                                    controller.unlock();
                            }
                        );
                    }
                    else
                    {
                        showConfirmationPrompt
                        (
                            p1Devices,
                            "Confirm selection? (P1)",
                            confirmDeviceSelections,
                            ()->
                            {
                                for (controller in prevUnlocked)
                                    controller.unlock();
                            }
                        );
                    }
                }
                else
                {
                    state = Invalid;
                    
                    for (controller in prevUnlocked)
                        controller.unlock();
                    
                    new FlxTimer().start(wiggleTime, (_)-> state = Selecting);
                }
            }
        }
    }
    
    function showConfirmationPrompt(controlsList:Array<Controller>, msg, onYes, ?onNo, ?onChoose)
    {
        if(state != Selecting)
            throw "Going to State.Selection from State." + state.getName();
        
        state = Confirming;
        
        var controls:Controls;
        if (controlsList.length == 1)
            controls = controlsList[0].controls;
        else
        {
            controls = new Controls("prompt-combo");
            for (controller in controllers.members)
                controls.copyFrom(controller.controls);
        }
        
        var prompt = new Prompt(controls);
        prompt.setup
        (
            msg,
            onYes,
            ()->
            {
                state = Selecting;
                if (onNo != null)
                    onNo();
                
                if (controlsList.length > 1)
                    controls.destroy();
                
                prompt.kill();
                remove(prompt);
            },
            onChoose
        );
        add(prompt);
    }
    
    function confirmDeviceSelections()
    {
        state = Outro;
        
        if (PlayerSettings.numAvatars < 2)
        {
            var hasP2Devices = false;
            for (controller in controllers.members)
            {
                if (controller.player == P2)
                {
                    hasP2Devices = true;
                    break;
                }
            }
            
            if (hasP2Devices)
                cast (FlxG.state, PlayState).createSecondPlayer();
        }
        
        for (controller in controllers.members)
        {
            if (controller.player != controller.initialPlayer)
            {
                switch (controller.initialPlayer)
                {
                    case None:
                    case P1: PlayerSettings.player1.controls.removeDevice(controller.getDevice());
                    case P2: PlayerSettings.player2.controls.removeDevice(controller.getDevice());
                }
                
                switch (controller.player)
                {
                    case P1: PlayerSettings.player1.controls.copyFrom(controller.controls);
                    case P2: PlayerSettings.player2.controls.copyFrom(controller.controls);
                    case None:
                        if (oldGamepads.indexOf(controller.gamepad) == -1)
                            oldGamepads.push(controller.gamepad);
                }
            }
        }
        
        newGamepads.resize(0);
        
        close();
    }
    
    static var newGamepads:Array<FlxGamepad> = [];
    static var oldGamepads:Array<FlxGamepad> = [];
    static public function hasNewGamepads():Bool
    {
        return newGamepads.length > 0;
    }
    
    static public function init():Void
    {
        FlxG.gamepads.deviceConnected.add(onDeviceConnected);
        FlxG.gamepads.deviceDisconnected.add(onDeviceDisconnected);
    }
    
    static function onDeviceConnected(gamepad:FlxGamepad):Void
    {
        if (oldGamepads.length < 4)
            newGamepads.push(gamepad);
    }
    
    static function onDeviceDisconnected(gamepad:FlxGamepad):Void
    {
    }
    
    inline static public function scaleToInTime(sprite:FlxSprite, scaleFactor:Float, duration:Float, ?onComplete:()->Void)
    {
        var options:TweenOptions = { ease:FlxEase.backOut };
        if (onComplete != null)
            options.onComplete = (_)->onComplete();
        return FlxTween.tween(sprite.scale, {x:scaleFactor, y:scaleFactor}, duration, options);
    }
    
    static function wiggleX(target, ?distance, duration = 0.5, ?onComplete, numWiggles = 5)
        inline wiggle(target, distance, true, duration, onComplete);
    
    static function wiggleY(target, ?distance, duration = 0.5, ?onComplete, numWiggles = 5)
        inline wiggle(target, distance, false, duration, onComplete);
    
    @:noCompletion
    static function wiggle(target:FlxSprite, ?distance:Float, horizontal = true, duration = 0.5, ?onComplete:()->Void, numWiggles = 5)
    {
        if (distance == null)
            distance = horizontal ? target.width : target.height;
        
        var start = horizontal ? target.x : target.y;
        function end(_)
        {
            if (horizontal)
                target.x = start;
            else
                target.y = start;
            if (onComplete != null)
                onComplete();
        }
        
        FlxTween.num(0, 1, duration, { onComplete:end }, 
            function (n)
            {
                final tSin = Math.sin(n * Math.PI * numWiggles);
                final strength = 1 - FlxEase.quadIn(n);
                
                if (horizontal)
                    target.x = start + distance * tSin * strength;
                else
                    target.y = start + distance * tSin * strength;
            }
        );
    }
}

private class Controller extends FlxSpriteGroup
{
    inline static var BLINK_TIME_S = 1.0;
    inline static var BLINK_TIME = Std.int(BLINK_TIME_S * 1000);
    
    inline static var DISTANCE = GamepadAlert.DISTANCE;
    inline static var GAMEPAD_IMAGE = "assets/images/ui/gamepad.png";
    inline static var KEYBOARD_IMAGE = "assets/images/ui/keyboard.png";
    inline static var ARROW_IMAGE = "assets/images/ui/deviceArrow.png";
    inline static var UNLOCK_SCALE = 1.5;
    
    public final gamepad:Null<FlxGamepad>;
    public final initialPlayer:SelectedPlayer;
    public final controls:Controls;
    public var player(default, null):SelectedPlayer;
    public var locked(default, null) = false;
    
    final deviceSprite:FlxSprite;
    final arrowRight:FlxSprite;
    final arrowLeft:FlxSprite;
    public function new (x = 0.0, y = 0.0, ?gamepad:FlxGamepad, player:SelectedPlayer = None)
    {
        final graphic = gamepad == null ? KEYBOARD_IMAGE : GAMEPAD_IMAGE;
        deviceSprite = new FlxSprite(0, 0, graphic);
        deviceSprite.loadGraphic(graphic, true, Std.int(deviceSprite.width / 2), Std.int(deviceSprite.height));
        deviceSprite.offset.x = Std.int(deviceSprite.origin.x);
        deviceSprite.animation.add("locked", [0]);
        deviceSprite.animation.add("unlocked", [1]);
        
        final arrowDistance = deviceSprite.width / 2 * 1.5;
        arrowRight = new FlxSprite(arrowDistance, deviceSprite.height / 2, ARROW_IMAGE);
        arrowRight.offset.y = arrowRight.origin.y;
        arrowLeft = new FlxSprite(-arrowDistance, deviceSprite.height / 2, ARROW_IMAGE);
        arrowLeft.offset.y = arrowLeft.origin.y;
        arrowLeft.offset.x = arrowLeft.width;
        arrowLeft.flipX = true;
        
        this.gamepad = gamepad;
        super();
        this.x = x;
        this.y = y;
        add(deviceSprite);
        add(arrowLeft);
        add(arrowRight);
        
        initialPlayer = player;
        setPlayer(player, false);
        locked = player != None;
        if (locked)
            lock(false);
        else
            unlock(false);
        
        var playerControls = switch(initialPlayer)
        {
            case P1:PlayerSettings.player1.controls;
            case P2:PlayerSettings.player2.controls;
            case None:null;
        }
        
        if (gamepad != null)
        {
            controls = new Controls("device:gamepad" + gamepad.id);
            if (playerControls != null)
                controls.copyFrom(playerControls, Gamepad(gamepad.id));
            else
                controls.addDefaultGamepad(gamepad.id);
        }
        else
        {
            controls = new Controls("device:keys");
            if (playerControls != null)
                controls.copyFrom(playerControls, Keys);
            else
                controls.setKeyboardScheme(Solo);
        }
        
        showIntro(0.25);
    }
    
    function showIntro(duration:Float)
    {
        active = false;
        deviceSprite.scale.set(0,0);
        scaleDeviceToInTime(locked ? 1 : UNLOCK_SCALE, duration, ()->active = true);
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        if (!active)
            return;
        
        if (locked)
        {
            if (controls.BACK)
                unlock();
        }
        else
        {
            if (player != P1 && controls.LEFT_P)
                setPlayer(player == None ? P1 : None);
            else if (player != P2 && controls.RIGHT_P)
                setPlayer(player == None ? P2 : None);
            
            if (controls.ACCEPT)
                lock();
        }
    }
    
    override function draw()
    {
        final blinkOn = active && (FlxG.game.ticks % BLINK_TIME) * 2 > BLINK_TIME;
        arrowLeft.visible = blinkOn && !locked && player != P1;
        arrowRight.visible = blinkOn && !locked && player != P2;
        
        super.draw();
    }
    
    function setPlayer(value:SelectedPlayer, animate = true)
    {
        if (value != player)
        {
            var newX = switch (value)
            {
                case P1: FlxG.width / 2 - DISTANCE;
                case P2: FlxG.width / 2 + DISTANCE;
                case None: FlxG.width / 2;
            }
            
            if (animate)
                FlxTween.tween(this, {x:newX}, 0.15, { ease:FlxEase.quadOut });
            else
                x = newX;
        }
        
        return player = value;
    }
    
    public function lock(animate = true):Void
    {
        deviceSprite.animation.play("locked");
        
        if (animate && !locked)
            scaleDeviceToInTime(1, 0.15);
        else
            deviceSprite.scale.set(1, 1);
        
        locked = true;
    }
    
    public function unlock(animate = true):Void
    {
        deviceSprite.animation.play("unlocked");
        
        if (animate && locked)
            scaleDeviceToInTime(UNLOCK_SCALE, 0.15);
        else
            deviceSprite.scale.set(UNLOCK_SCALE, UNLOCK_SCALE);
        
        locked = false;
    }
    
    inline function scaleDeviceToInTime(scaleFactor, duration, ?onComplete)
    {
        return GamepadAlert.scaleToInTime(deviceSprite, scaleFactor, duration, onComplete);
    }
    
    override function destroy()
    {
        super.destroy();
        controls.destroy();
    }
    
    public function getDevice():Device
    {
        return gamepad == null ? Keys : Gamepad(gamepad.id);
    }
}

private enum SelectedPlayer
{
    P1;
    P2;
    None;
}

private enum State
{
    Intro;
    Selecting;
    Invalid;
    Confirming;
    Outro;
}