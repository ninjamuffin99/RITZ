package ui;

import ui.Controls;

import flixel.FlxG;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;

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
            default: 
                var input = FlxKey.toStringMap[id];
                return input.charAt(0) + input.substr(1, 2).toLowerCase();
        }
    }
    
    static var dirReg = ~/^(l|r).?-(left|right|down|up)$/;
    static public function getButtonName(id:Int, gamepad:FlxGamepad):String
    {
        return switch (gamepad.getInputLabel(id))
        {
            case null: "";
            case "square"  : "[]";
            case "circle"  : "()";
            case "triangle": "/\\";
            case "plus"    : "+";
            case "minus"   : "-";
            case "home"    : "Hm";
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
            case label: label.charAt(0).toUpperCase() + label.substr(1, 2).toLowerCase();
        }
    }
}