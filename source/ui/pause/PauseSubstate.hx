package ui.pause;

import data.PlayerSettings;
import ui.BitmapText;
import ui.Controls;
import ui.pause.PausePage;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

enum PausePageType
{
    Main;
    Ready;
    Controls;
    Settings;
}

class PauseSubstate extends flixel.FlxSubState
{
    var screen1:PauseScreen;
    var screen2:Null<PauseScreen>;
    var gamepadAlert:DeviceManager;
    
    public function new (settings1:PlayerSettings, ?settings2:PlayerSettings, ?startingPage:PausePageType)
    {
        super();
        
        add(screen1 = new PauseScreen(settings1, startingPage));
        screen1.cameras = [copyCamera(settings1.camera)];
        
        if (settings2 != null && settings2.avatar != null)
            addSecondPlayer(settings2, startingPage);
        else
            PlayerSettings.onAvatarAdd.add(addSecondPlayerLate);
        
        if (!screen1.paused && (screen2 == null || !screen2.paused))
            throw "Error: Started off in a ready to unpause state";
    }
    
    inline function addSecondPlayer(settings, startingPage)
    {
        add(screen2 = new PauseScreen(settings, startingPage));
        screen2.cameras = [copyCamera(settings.camera)];
    }
    
    function addSecondPlayerLate(settings)
    {
        addSecondPlayer(settings, Controls);
        PlayerSettings.onAvatarAdd.remove(addSecondPlayerLate);
    }
    
    inline function copyCamera(original:FlxCamera):FlxCamera
    {
        var camera = new FlxCamera(Std.int(original.x), Std.int(original.y), original.width, original.height, 0);
        FlxG.cameras.add(camera);
        camera.bgColor = 0;
        return camera;
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        final awaitingInput = screen1.awaitingInput() || (screen2 != null && screen2.awaitingInput());
        if (!awaitingInput && DeviceManager.alertPending())
        {
            if (gamepadAlert == null)
                showDeviceManager();
            return;
        }
        
        if (!screen1.paused && (screen2 == null || !screen2.paused))
            close();
    }
    
    function showDeviceManager()
    {
        gamepadAlert = new DeviceManager();
        gamepadAlert.closeCallback = onDeviceManagerClose;
        openSubState(gamepadAlert);
    }
    
    function onDeviceManagerClose()
    {
        gamepadAlert = null;
        screen1.redrawPage();
        if (screen2 != null)
            screen2.redrawPage();
    }
    
    override function close()
    {
        super.close();
        FlxG.cameras.remove(screen1.camera);
        
        if (screen2 != null)
            FlxG.cameras.remove(screen2.camera);
        else
            PlayerSettings.onAvatarAdd.remove(addSecondPlayerLate);
    }
}

class PauseScreen extends FlxGroup
{
    public var paused(get, never):Bool;
    
    final pages:Map<PausePageType, PausePage> = [];
    final settings:PlayerSettings;
    
    var pageType:PausePageType;
    var currentPage(get,never):PausePage;
    
    var pauseReleased = false;
    
    public function new(settings:PlayerSettings, ?startingPage:PausePageType)
    {
        this.settings = settings;
        super();
        
        addPage(Ready, new ReadyPage());
        addPage(Main, new MainPage(settings, setPage));
        addPage(Controls, new ControlsPage(settings, setPage));
        
        if (startingPage != null)
            setPage(startingPage);
        else
            setPage(settings.controls.PAUSE ? Main : Ready);
        
        PlayerSettings.onAvatarRemove.add(onAvatarRemove);
    }
    
    function addPage(type:PausePageType, page:PausePage):PausePage
    {
        add(pages[type] = page);
        if (type != pageType)
            page.kill();
        
        return page;
    }
    
    function setPage(type:PausePageType)
    {
        if (pageType != null)
            currentPage.kill();
        
        pageType = type;
        currentPage.revive();
    }
    
    function onAvatarRemove(settings:PlayerSettings)
    {
        if (settings == this.settings)
            kill();
        else
        {
            camera.width = this.settings.camera.width;
            currentPage.redraw();
        }
    }
    
    override function update(elapsed:Float)
    {
        var oldCameras = FlxCamera.defaultCameras;
        FlxCamera.defaultCameras = cameras;
        super.update(elapsed);
        FlxCamera.defaultCameras = oldCameras;
        
        if (!settings.controls.PAUSE)
            pauseReleased = true;
        
        if (!currentPage.allowUnpause() && settings.controls.PAUSE && pauseReleased)
            setPage(pageType == Ready ? Main : Ready);
    }
    
    inline public function redrawPage()
    {
        currentPage.redraw();
    }
    
    override function destroy()
    {
        super.destroy();
        
        pages.clear();
        PlayerSettings.onAvatarRemove.remove(onAvatarRemove);
    }
    
    inline public function awaitingInput():Bool
    {
        return currentPage.awaitingInput();
    }
    
    inline function get_paused() return pageType != Ready;
    inline function get_currentPage() return pages[pageType];
}