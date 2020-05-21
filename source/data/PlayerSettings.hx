package data;

import ui.Controls;

import flixel.FlxCamera;
import flixel.math.FlxRect;

class PlayerSettings
{
    static public var numPlayers(default, null) = 0;
    static public var player1(default, null):PlayerSettings;
    static public var player2(default, null):PlayerSettings;
    
    public final id:Int;
    
    public var camera(default, null):FlxCamera;
    public var controls(default, null):Controls;
    public var controlsType(default, null):ControlsType;
    
    public function new(id, controlsType, camera:FlxCamera)
    {
        this.id = id;
        this.camera = camera;
        setControlsType(controlsType);
        
        if (id == 0)
        {
            player1 = this;
            numPlayers = 1;
        }
        else
        {
            player2 = this;
            numPlayers = 2;
        }
    }
    
    public function setControlsType(type)
    {
        controlsType = type;
        controls = switch(controlsType)
        {
            case Solo: Controls.solo;
            case Duo(true): Controls.duo1;
            case Duo(false): Controls.duo2;
            case Custom: null;//TODO
        }
    }
}