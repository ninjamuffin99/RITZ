package ui;

import data.PlayerSettings;
import states.PlayState;
import ui.BitmapText;
import ui.Controls;
import ui.InputFormatter;
import utils.SpriteEffects;

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

class DeviceManager extends FlxSubState
{
    // @:allow(ui.DeviceManager.Controller)
    static public inline var DISTANCE = 100;
    
    var title:BitmapText;
    var confirmMsg:BitmapText;
    var bg:SliceBg;
    var p1:BitmapText;
    var p2:BitmapText;
    var none:BitmapText;
    var controllers = new FlxTypedGroup<Controller>();
    var state:State;
    
    var lastLocked:Controller = null;
    
    override function create()
    {
        super.create();
        state = Intro;
        
        final camera = new FlxCamera(0, 0, FlxG.width, FlxG.height);
        camera.bgColor = 0x0;
        FlxG.cameras.add(camera);
        cameras = [camera];
        
        final border = 8;
        bg = SliceBg.alert();
        bg.setSize(Std.int(FlxG.width - border * 2), Std.int(FlxG.height - border * 2));
        bg.screenCenter(XY);
        add(bg);
        
        title = new BitmapText(0, bg.y + 8, newGamepads.length > 0 ? "GAMEPAD CONNECTED" : "DEVICES");
        title.screenCenter(X);
        add(title);
        
        add(confirmMsg = new Nokia8Text("(P1) PAUSE to confirm"));
        confirmMsg.y = bg.y + bg.height - confirmMsg.height - 8;
        confirmMsg.x = bg.x + (bg.width - confirmMsg.width) / 2;
        
        controllers.kill();
        final tweenTime = 0.5;
        bg.scale.set(0,0);
        SpriteEffects.scaleToInTime(bg, 1, tweenTime, { ease:FlxEase.quartOut });
        title.scale.set(0,0);
        SpriteEffects.scaleToInTime(title, 1, tweenTime, { ease:FlxEase.quartOut });
        new FlxTimer().start(0.2, (_)->onAlertIn());
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
                title.y + title.height + 16,
                text
            );
            field.offset.set(Std.int(field.width / 2), Std.int(field.height / 2));
            field.scale.set(0, 0);
            SpriteEffects.scaleToInTime(field, 1, 0.15);
            add(field);
            return field;
        }
        
        p1 = createPlayerSlot(-1, "P1");
        p2 = createPlayerSlot(1, "P2" + (PlayerSettings.numAvatars == 1 ? "(Join?)" : ""));
        none = createPlayerSlot(0, "NONE");
        
        final requestingPlayer = DeviceManager.requestingPlayer;
        var keysSprite = new Controller(0, p1.y + p1.height, null, requestingPlayer == None);
        controllers.add(keysSprite);
        if (keysSprite.initialPlayer != requestingPlayer && requestingPlayer != None)
            keysSprite.lock(false);
        
        for (i in 0...oldGamepads.length)
        {
            final sprite = addGamepad(oldGamepads[i], false);
            if (sprite.initialPlayer != requestingPlayer)
                sprite.lock(false);
        }
        
        for (i in 0...newGamepads.length)
            addGamepad(newGamepads[i]);
    }
    
    function addGamepad(gamepad:FlxGamepad, autoLock = true)
    {
        final bottom = controllers.members[controllers.length - 1].y + controllers.members[0].height;
        var padSprite = new Controller(0, bottom * Controller.UNLOCK_SCALE, gamepad, autoLock);
        controllers.add(padSprite);
        return padSprite;
    }
    
    override function update(elapsed:Float)
    {
        var prevUnlocked:Array<Controller> = null;
        if (state == Selecting)
        {
            prevUnlocked = controllers.members.filter((controller)->!controller.locked);
            
            checkActiveGamepads();
            while (newGamepads.length > controllers.length - 1)// - keys
                addGamepad(newGamepads[controllers.length - 1]);
        }
        
        controllers.active = state == Selecting;
        super.update(elapsed);
        
        if (state == Selecting)
        {
            // track last locked
            for (controller in prevUnlocked)
                if (controller.locked)
                    lastLocked = controller;
        }
        
        confirmMsg.visible = false;
        if (state.match(Selecting | Animating))
        {
            // get controller states;
            var p1Confirming = false;
            var noneAnimating = true;
            for (controller in controllers.members)
            {
                if (!p1Confirming && controller.player == P1 && controller.confirming)
                    p1Confirming = true;
                
                if (controller.animating)
                    noneAnimating = false;
            }
            
            if (p1Confirming && !noneAnimating)
                state = Animating;// wait for animation to finish
            else if (p1Confirming && noneAnimating)
            {
                // check valid selection
                var p1Devices = new Array<Controller>();
                var p2Devices = new Array<Controller>();
                for (controller in controllers.members)
                {
                    if (controller.locked)
                    {
                        switch (controller.player)
                        {
                            case P1: p1Devices.push(controller);
                            case P2: p2Devices.push(controller);
                            case None:
                        }
                    }
                }
                
                var isValid = true;
                var wiggleTime = 0.5;
                if (p1Devices.length == 0)
                {
                    isValid = false;
                    p1.borderColor = 0xFFac3232;
                    SpriteEffects.wiggleX(p1, 16, wiggleTime);
                }
                
                if (PlayerSettings.numAvatars == 2 && p2Devices.length == 0)
                {
                    isValid = false;
                    p2.borderColor = 0xFFac3232;
                    SpriteEffects.wiggleX(p2, 16, wiggleTime);
                }
                
                if (isValid)
                    confirmDeviceSelections();
                else
                {
                    state = Invalid;
                    
                    unlockLast();
                    
                    new FlxTimer().start(wiggleTime,
                        (_)->
                        {
                            state = Selecting;
                            p1.borderColor = BitmapText.DEFAULT_BORDER_COLOR;
                            p2.borderColor = BitmapText.DEFAULT_BORDER_COLOR;
                        }
                    );
                }
            }
            else
            {
                var hasP1Devices = false;
                var hasP2Devices = false;
                for (controller in controllers.members)
                {
                    if (controller.locked)
                    {
                        switch (controller.player)
                        {
                            case P1: hasP1Devices = true;
                            case P2: hasP2Devices = true;
                            case None:
                        }
                    }
                }
                
                if (hasP1Devices && (hasP2Devices || PlayerSettings.numAvatars == 1))
                    confirmMsg.visible = SpriteEffects.blinkTicks(Controller.BLINK_TIME);
            }
        }
    }
    
    function unlockLast()
    {
        if (lastLocked != null)
            lastLocked.unlock();
    };
    
    function showConfirmationPrompt(controlsList:Array<Controller>, msg, onYes, ?onNo, ?onChoose)
    {
        if(!state.match(Selecting|Animating))
            throw "Going to State.Selecting from State." + state.getName();
        
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
        prompt.camera = camera;
        prompt.setup
        (
            msg,
            onYes,
            ()->
            {
                state = Selecting;
                if (onNo != null)
                    onNo();
            },
            ()->
            {
                prompt.kill();
                remove(prompt);
                
                if (onChoose != null)
                    onChoose();
            }
        );
        add(prompt);
    }
    
    function confirmDeviceSelections()
    {
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
            {
                cast (FlxG.state, PlayState).createSecondPlayer();
                // bring to front
                FlxG.cameras.remove(camera, false);
                FlxG.cameras.add(camera);
            }
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
                    case None:
                    case P1: PlayerSettings.player1.controls.copyFrom(controller.controls);
                    case P2: PlayerSettings.player2.controls.copyFrom(controller.controls);
                }
                
            }
            
            if (controller.gamepad != null)
            {
                oldGamepads.remove(controller.gamepad);
                
                if (controller.player == None)
                    connectedGamepads.push(controller.gamepad);
                else
                    oldGamepads.push(controller.gamepad);
            }
        }
        
        requestingPlayer = -1;
        newGamepads.resize(0);
        
        startOutro();
    }
    
    function startOutro()
    {
        state = Outro;
        
        FlxTween.num(1, 0, 0.25, { ease: FlxEase.backIn },
            (value)->
            {
                p1.scale.set(value, value);
                p2.scale.set(value, value);
                none.scale.set(value, value);
                for (controller in controllers.members)
                    controller.scale.set(value, value);
            }
        );
        
        final tweenTime = 0.5;
        SpriteEffects.scaleToInTime(bg, 0, tweenTime, { ease:FlxEase.quartIn });
        SpriteEffects.scaleToInTime(title, 0, tweenTime, close, { ease:FlxEase.quartIn });
    }
    
    override function close()
    {
        super.close();
        FlxG.cameras.remove(camera);
    }
    
    /** The device Used to bring up the */
    static var requestingPlayer:Int = -1;
    static var connectedGamepads:Array<FlxGamepad> = [];
    static var newGamepads:Array<FlxGamepad> = [];
    static var oldGamepads:Array<FlxGamepad> = [];
    
    static public function totalDevices()
    {
        return 1 + connectedGamepads.length + oldGamepads.length;
    }
    
    static public function alertPending():Bool
    {
        checkActiveGamepads();
        return newGamepads.length > 0
            || requestingPlayer != -1;
    }
    
    static function checkActiveGamepads()
    {
        var i = 0;
        while (i < connectedGamepads.length && newGamepads.length + oldGamepads.length < 4)
        {
            final gamepad = connectedGamepads[i];
            if (gamepad.pressed.ANY)
            {
                newGamepads.push(gamepad);
                connectedGamepads.remove(gamepad);
            }
            else
                i++;
        }
    }
    
    static public function init():Void
    {
        FlxG.gamepads.deviceConnected.add(onDeviceConnected);
        FlxG.gamepads.deviceDisconnected.add(onDeviceDisconnected);
    }
    
    static public function requestAlert(player:SelectedPlayer)
    {
        requestingPlayer = player;
    }
    
    static function onDeviceConnected(gamepad:FlxGamepad):Void
    {
        if (PlayerSettings.numAvatars < 2 && connectedGamepads.length + newGamepads.length + oldGamepads.length == 0)
        {
            // First gamepad goes to P1 if there is no P2
            PlayerSettings.player1.controls.addDefaultGamepad(gamepad.id);
            oldGamepads.push(gamepad);
        }
        else
            connectedGamepads.push(gamepad);
    }
    
    static function onDeviceDisconnected(gamepad:FlxGamepad):Void
    {
        trace("Disconnected: " + gamepad.name);
    }
    
    static public function releaseGamepad(gamepad:FlxGamepad):Void
    {
        if(oldGamepads.remove(gamepad))
            connectedGamepads.push(gamepad);
        else
            throw 'gamepad:${gamepad.id} is already released';
    }
}

private class Controller extends FlxSpriteGroup
{
    inline public static var UNLOCK_SCALE = 1.25;
    
    inline static var BLINK_TIME_S = 1.0;
    inline public static var BLINK_TIME = Std.int(BLINK_TIME_S * 1000);
    
    inline static var DISTANCE = DeviceManager.DISTANCE;
    inline static var GAMEPAD_IMAGE = "assets/images/ui/gamepad.png";
    inline static var KEYBOARD_IMAGE = "assets/images/ui/keyboard.png";
    inline static var ARROW_IMAGE = "assets/images/ui/deviceArrow.png";
    
    public final gamepad:Null<FlxGamepad>;
    public final initialPlayer:SelectedPlayer;
    public final controls:Controls;
    public var player(default, null):SelectedPlayer;
    public var locked(default, null) = false;
    public var animating(default, null) = false;
    public var confirming(default, null) = false;
    
    final deviceSprite:FlxSprite;
    final arrowRight:FlxSprite;
    final arrowLeft:FlxSprite;
    
    public function new (x = 0.0, y = 0.0, ?gamepad:FlxGamepad, autoLock = true)
    {
        final graphic = ControllerName.getAsset(gamepad);
        deviceSprite = new FlxSprite(0, 0, graphic);
        deviceSprite.loadGraphic(graphic, true, deviceSprite.graphic.width >> 1);
        deviceSprite.offset.x = Std.int(deviceSprite.origin.x);
        deviceSprite.animation.add("locked", [0]);
        deviceSprite.animation.add("unlocked", [1]);
        
        final arrowDistance = deviceSprite.width / 2 * UNLOCK_SCALE;
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
        
        initialPlayer = if (gamepad == null)
        {
            if (PlayerSettings.player1.controls.keyboardScheme != None)
                P1;
            else if (PlayerSettings.numPlayers > 1 && PlayerSettings.player2.controls.keyboardScheme != None)
                P2;
            else
                None;
        }
        else
        {
            if (PlayerSettings.player1.controls.gamepadsAdded.contains(gamepad.id))
                P1;
            else if (PlayerSettings.numPlayers > 1 && PlayerSettings.player2.controls.gamepadsAdded.contains(gamepad.id))
                P2;
            else
                None;
        }
        
        setPlayer(initialPlayer, false);
        locked = player != None && autoLock;
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
    
    function showOutro(duration:Float)
    {
        scaleDeviceToInTime(0, duration);
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        confirming = false;
        
        if (!active)
            return;
        
        if (locked)
        {
            confirming = controls.PAUSE;
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
        final blinkOn = active && SpriteEffects.blinkTicks(BLINK_TIME);
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
        animating = true;
        return SpriteEffects.scaleToInTime(deviceSprite, scaleFactor, duration,
            ()->
            {
                animating = false;
                
                if (onComplete != null)
                    onComplete();
            }
        );
    }
    
    public function getDevice():Device
    {
        return gamepad == null ? Keys : Gamepad(gamepad.id);
    }
}

private enum abstract SelectedPlayer(Int) from Int to Int
{
    var P1 = 0;
    var P2 = 1;
    var None = 2;
}

private enum State
{
    Intro;
    Selecting;
    Animating;
    Invalid;
    Confirming;
    Outro;
}