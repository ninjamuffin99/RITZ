package ui.pause;

import data.PlayerSettings;
import ui.BitmapText;
import ui.Controls;
import ui.pause.PausePage;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;

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
    
    public function new (settings1:PlayerSettings, ?settings2:PlayerSettings, ?startingPage:PausePageType)
    {
        super();
        
        add(screen1 = new PauseScreen(settings1, startingPage));
        screen1.cameras = [copyCamera(settings1.camera)];
        
        if (settings2 != null)
            addSecondPlayer(settings2, startingPage);
        else
            PlayerSettings.onAvatarAdd.add(addSecondPlayerLate);
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
        
        if (!screen1.paused && (screen2 == null || !screen2.paused))
            close();
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
        
        add(pages[Ready] = new ReadyPage()).kill();
        add(pages[Main] = new MainPage(settings, setPage)).kill();
        add(pages[Controls] = new ControlsPage(settings, setPage)).kill();
        
        if (startingPage != null)
            setPage(startingPage);
        else
            setPage(settings.controls.PAUSE ? Main : Ready);
    }
    
    function setPage(type:PausePageType)
    {
        if (pageType != null)
            currentPage.kill();
        
        pageType = type;
        currentPage.revive();
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        if (!settings.controls.PAUSE)
            pauseReleased = true;
        
        if (currentPage.allowUnpause() && settings.controls.PAUSE && pauseReleased)
            setPage(pageType == Ready ? Main : Ready);
    }
    
    override function destroy()
    {
        super.destroy();
        
        pages.clear();
    }
    
    inline function get_paused() return pageType != Ready;
    inline function get_currentPage() return pages[pageType];
}