package data;

import props.Player;
import ui.Controls;

import flixel.FlxCamera;
import flixel.FlxG;

class PlayerSettings
{
    static public var numPlayers(default, null) = 0;
    static public var numAvatars(default, null) = 0;
    static public var player1(default, null):PlayerSettings;
    static public var player2(default, null):PlayerSettings;
    
    public var id(default, null):Int;
    
    public final controls:Controls;
    public var avatar:Player;
    public var camera:PlayCamera;
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
                player2 = new PlayerSettings(0, Duo(false));
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
        
        return settings;
    }
    
    static public function removeAvatar(avatar:Player):Void
    {
        if (player1 != null && player1.avatar == avatar)
            player1.avatar = null;
        else if(player2 != null && player2.avatar == avatar)
            player2.avatar = null;
        else
            throw "Cannot remove avatar that is not for a player";
        
        --numAvatars;
    }
    
    static public function reset()
    {
        player1 = null;
        player2 = null;
        numPlayers = 0;
    }
}