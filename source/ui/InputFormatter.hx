package ui;

import ui.Controls;

import flixel.FlxG;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;

using flixel.util.FlxStringUtil;

class InputFormatter
{
    static public function format(id:Int, device:Device):String
    {
        return switch (device)
        {
            case Keys: getKeyName(id);
            case Gamepad(gamepadID): getButtonName(id, FlxG.gamepads.getByID(gamepadID));
        }
    }
    
    static public function getKeyName(id:Int):String
    {
        return switch(id)
        {
            case ZERO          : "0";
            case ONE           : "1";
            case TWO           : "2";
            case THREE         : "3";
            case FOUR          : "4";
            case FIVE          : "5";
            case SIX           : "6";
            case SEVEN         : "7";
            case EIGHT         : "8";
            case NINE          : "9";
            case PAGEUP        : "PgU";
            case PAGEDOWN      : "PgD";
            case HOME          : "Hm";
            case END           : "End";
            case INSERT        : "Ins";
            case ESCAPE        : "Esc";
            case MINUS         : "-";
            case PLUS          : "+";
            case DELETE        : "Del";
            case BACKSPACE     : "Bck";
            case LBRACKET      : "[";
            case RBRACKET      : "]";
            case BACKSLASH     : "\\";
            case CAPSLOCK      : "Cap";
            case SEMICOLON     : ";";
            case QUOTE         : "'";
            case ENTER         : "Ent";
            case SHIFT         : "Shf";
            case COMMA         : ",";
            case PERIOD        : ".";
            case SLASH         : "/";
            case GRAVEACCENT   : "`";
            case CONTROL       : "Ctl";
            case ALT           : "Alt";
            case SPACE         : "Spc";
            case UP            : "Up";
            case DOWN          : "Dn";
            case LEFT          : "Lf";
            case RIGHT         : "Rt";
            case TAB           : "Tab";
            case PRINTSCREEN   : "Prt";
            case NUMPADZERO    : "#0";
            case NUMPADONE     : "#1";
            case NUMPADTWO     : "#2";
            case NUMPADTHREE   : "#3";
            case NUMPADFOUR    : "#4";
            case NUMPADFIVE    : "#5";
            case NUMPADSIX     : "#6";
            case NUMPADSEVEN   : "#7";
            case NUMPADEIGHT   : "#8";
            case NUMPADNINE    : "#9";
            case NUMPADMINUS   : "#-";
            case NUMPADPLUS    : "#+";
            case NUMPADPERIOD  : "#.";
            case NUMPADMULTIPLY: "#*";
            default: titleCaseTrim(FlxKey.toStringMap[id]);
        }
    }
    
    static var dirReg = ~/^(l|r).?-(left|right|down|up)$/;
    inline static public function getButtonName(id:Int, gamepad:FlxGamepad):String
    {
        return switch(gamepad.getInputLabel(id))
        {
            // case null | "": shortenButtonName(FlxGamepadInputID.toStringMap[id]);
            case label: shortenButtonName(label);
        }
    }
    
    static function shortenButtonName(name:String)
    {
        return switch (name == null ? "" : name.toLowerCase())
        {
            case "": "[?]";
            case "square"  : "[]";
            case "circle"  : "()";
            case "triangle": "/\\";
            case "plus"    : "+";
            case "minus"   : "-";
            case "home"    : "Hm";
            case "guide"   : "Gd";
            case "back"    : "Bk";
            case "select"  : "Bk";
            case "start"   : "St";
            case "left"    : "Lf";
            case "right"   : "Rt";
            case "down"    : "Dn";
            case "up"      : "Up";
            case dir if (dirReg.match(dir)):
                dirReg.matched(1).toUpperCase() + "-"
                + switch (dirReg.matched(2))
                {
                    case "left" : "L";
                    case "right": "R";
                    case "down" : "D";
                    case "up"   : "U";
                    default: throw "Unreachable exaustiveness case";
                };
            case label: titleCaseTrim(label);
        }
    }
    
    inline static function titleCaseTrim(str:String, length = 3)
    {
        return str.charAt(0).toUpperCase() + str.substr(1, length - 1).toLowerCase();
    }
    
    static public function getPadName(name:String):String
    {
        name = name.toLowerCase().remove("-").remove("_");
        return if (name.contains("ouya"))
                "Ouya"; // "OUYA Game Controller"
            else if (name.contains("wireless controller") || name.contains("ps4"))
                "PS4"; // "Wireless Controller" or "PS4 controller"
            else if (name.contains("logitech"))
                "Logi";
            else if (name.contains("xbox"))
                "XBox"
            else if (name.contains("xinput"))
                "XInput";
            else if (name.contains("nintendo rvlcnt01tr") || name.contains("nintendo rvlcnt01"))
                "Wii"; // WiiRemote w/o  motion plus
            else if (name.contains("mayflash wiimote pc adapter"))
                "Wii"; // WiiRemote paired to MayFlash DolphinBar (with or w/o motion plus)
            else if (name.contains("pro controller"))
                "Pro_Con";
            else if (name.contains("joycon l+r"))
                "Joycons";
            else if (name.contains("joycon (l)"))
                "Joycon_L";
            else if (name.contains("joycon (r)"))
                "Joycon_R";
            else if (name.contains("mfi"))
                "MFI";
            else
                "Pad";
    }
}