package data;

import props.Player;
import ui.Controls;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.util.FlxSignal;

class PlayerSettings
{
    static public var numPlayers(default, null) = 0;
    static public var numAvatars(default, null) = 0;
    static public var player1(default, null):PlayerSettings;
    static public var player2(default, null):PlayerSettings;
    
    static public final onAvatarAdd = new FlxTypedSignal<PlayerSettings->Void>();
    
    public var id(default, null):Int;
    
    public final controls:Controls;
    public var avatar:Player;
    public var camera(get, never):PlayCamera;
    inline function get_camera() return avatar.playCamera;
    
    function new(id, scheme)
    {
        this.id = id;
        this.controls = new Controls('player$id', scheme);
    }
    
    public function setKeyboardScheme(scheme)
    {
        controls.setKeyboardScheme(scheme);
    }
    
    function loadSettings():Void
    {
        //Todo:
    }
    
    static public function addAvatar(avatar:Player):PlayerSettings
    {
        var settings:PlayerSettings;
        
        if (player1 == null)
        {
            player1 = new PlayerSettings(0, Solo);
            ++numPlayers;
        }
        
        if (player1.avatar == null)
            settings = player1;
        else
        {
            if (player2 == null)
            {
                player1.setKeyboardScheme(Duo(true));
                player2 = new PlayerSettings(1, Duo(false));
                ++numPlayers;
            }
            
            if (player2.avatar == null)
                settings = player2;
            else
                throw throw 'Invalid number of players: ${numPlayers+1}';
        }
        ++numAvatars;
        settings.avatar = avatar;
        avatar.settings = settings;
        
        splitCameras();
        
        onAvatarAdd.dispatch(settings);
        
        return settings;
    }
    
    static public function removeAvatar(avatar:Player):Void
    {
        if (player1 != null && player1.avatar == avatar)
            player1.avatar = null;
        else if(player2 != null && player2.avatar == avatar)
        {
            player2.avatar = null;
            if (player1.controls.keyboardScheme.match(Duo(_)))
                player1.setKeyboardScheme(Solo);
        }
        else
            throw "Cannot remove avatar that is not for a player";
        
        --numAvatars;
        
        splitCameras();
    }
    
    static function splitCameras()
    {
        switch(PlayerSettings.numAvatars)
        {
            case 1:
                var cam:PlayCamera = cast player1.camera;
                cam.width = FlxG.width;
                cam.resetDeadZones();
            case 2:
                var cam:PlayCamera;
                cam = cast player1.camera;
                cam.width = Std.int(FlxG.width / 2);
                cam.resetDeadZones();
                cam = cast player2.camera;
                cam.width = Std.int(FlxG.width / 2);
                cam.x = cam.width;
                cam.resetDeadZones();
        }
    }
    
    static public function reset()
    {
        player1 = null;
        player2 = null;
        numPlayers = 0;
    }
}