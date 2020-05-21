package ui;

import data.PlayerSettings;
import ui.BitmapText;
import ui.Controls;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;

class PauseSubstate extends flixel.FlxSubState
{
    var screen1:PauseScreen;
    var screen2:Null<PauseScreen>;
    
    public function new (settings1:PlayerSettings, ?settings2:PlayerSettings)
    {
        super();
        
        add(screen1 = new PauseScreen(settings1));
        screen1.cameras = [copyCamera(settings1.camera)];
        
        if (settings2 != null)
        {
            add(screen2 = new PauseScreen(settings2));
            screen2.cameras = [copyCamera(settings2.camera)];
        }
    }
    
    inline function copyCamera(original:FlxCamera):FlxCamera
    {
        var camera = new FlxCamera(Std.int(original.x), Std.int(original.y), original.width, original.height, 0);
        FlxG.cameras.add(camera);
        camera.bgColor = 0;
        return camera;
    }
    
    // function addControls()
    // {
    //     var controls = new ControlsData();
    //     controls.add("Action", "Keyboard", "Gamepad");
    //     controls.add("------", "----------", "---------");
    //     controls.add("Move", "Arrows WASD", "D-Pad L-Stick");
    //     controls.addFromInput(ACCEPT);
    //     controls.addFromInput(BACK  );
    //     controls.addFromInput(JUMP  );
    //     controls.addFromInput(TALK  );
    //     controls.addFromInput(MAP   );
    //     controls.addFromInput(RESET );
        
    //     inline function addColumn()
    //     {
    //         var column = new BitmapText();
    //         column.scrollFactor.set();
    //         add(column);
    //         return column;
    //     }
        
    //     var actionsColumn = addColumn();
    //     var    keysColumn = addColumn();
    //     var buttonsColumn = addColumn();
    //     for (input in (controls:RawControlsData))
    //     {
    //         actionsColumn.text += input.action + "\n";
    //         keysColumn.text += input.keys + "\n";
    //         buttonsColumn.text += input.buttons + "\n";
    //     }
    //     // remove last \n
    //     actionsColumn.text = actionsColumn.text.substr(0, actionsColumn.text.length - 1);
    //        keysColumn.text =    keysColumn.text.substr(0,    keysColumn.text.length - 1);
    //     buttonsColumn.text = buttonsColumn.text.substr(0, buttonsColumn.text.length - 1);
    //     final gap = 32;
    //     final width = actionsColumn.width + gap + keysColumn.width + gap + buttonsColumn.width;
    //     // X margin
    //     var margin = (FlxG.width - width) / 2;
    //     actionsColumn.x = margin;
    //     keysColumn.x = actionsColumn.x + actionsColumn.width + gap;
    //     buttonsColumn.x = keysColumn.x + keysColumn.width + gap;
    //     // Y margin
    //     // margin = (FlxG.height - (buttons.y + buttons.length * buttons.group.members[0].lineHeight + actionsColumn.height)) / 2;
    //     // trace(margin, buttons.y + buttons.length * buttons.group.members[0].lineHeight);
    //     actionsColumn.y = FlxG.height - actionsColumn.height - margin;
    //        keysColumn.y = FlxG.height -    keysColumn.height - margin;
    //     buttonsColumn.y = FlxG.height - buttonsColumn.height - margin;
    // }
    
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
    }
}

class PauseScreen extends FlxGroup
{
    public var paused(default, null) = true;
    
    var pauseReleased = false;
    var mainPage:MainPage;
    var readyPage:ReadyPage;
    var currentPage:Page;
    var settings:PlayerSettings;
    
    public function new(settings:PlayerSettings)
    {
        this.settings = settings;
        this.paused = settings.controls.PAUSE;
        super();
        
        add(readyPage = new ReadyPage()).kill();
        add(mainPage = new MainPage(settings, showReady)).kill();
        
        selectPage(paused ? mainPage : readyPage);
    }
    
    function selectPage(page:Page)
    {
        if (currentPage != null)
            currentPage.kill();
        
        currentPage = page;
        page.revive();
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        if (!settings.controls.PAUSE)
            pauseReleased = true;
        
        if (currentPage.allowUnpause() && (settings.controls.BACK || (settings.controls.PAUSE && pauseReleased)))
        {
            if (paused) showReady();
            else showMenu();
        }
    }
    
    inline function showReady()
    {
        paused = false;
        selectPage(readyPage);
    }
    
    inline function showMenu()
    {
        paused = true;
        selectPage(mainPage);
    }
}

class Page extends FlxGroup
{
    public function new(maxSize:Int = 0)
    {
        super(maxSize);
    }
    
    public function allowUnpause() return true;
}

abstract ReadyPage(Page) to Page
{
    public function new ()
    {
        this = new Page(1);
        
        var title = new BitmapText(0, 4, "Waiting for player");
        title.x = (FlxG.camera.width - title.width) / 2;
        title.y = (FlxG.camera.height - title.height) / 2;
        title.scrollFactor.set();
        this.add(title);
    }
}

class MainPage extends Page
{
    var buttons:ButtonGroup;
    var settings:PlayerSettings;
    
    public function new (settings:PlayerSettings, onContinue:()->Void)
    {
        this.settings = settings;
        super();
        
        var title = new BitmapText(0, 4, "PAUSED");
        title.x = (settings.camera.width - title.width) / 2;
        title.scrollFactor.set();
        add(title);
        
        buttons = new ButtonGroup(3, settings.controls, false);
        inline function addButton(text, callback)
        {
            var button:BitmapText;
            button = buttons.addNewButton(0, 0, text, callback);
            button.y += (buttons.length - 1) * button.lineHeight;
            button.x = (settings.camera.width - button.width) / 2;
            button.scrollFactor.set();
        }
        
        addButton("CONTINUE", onContinue);
        addButton("MUTE", ()->FlxG.sound.muted = !FlxG.sound.muted);
        addButton("RESTART", onSelectRestart);
        buttons.y = title.y + title.lineHeight * 2;
        add(buttons);
    }
    
    function onSelectRestart():Void
    {
        buttons.active = false;
        var prompt = new Prompt(settings.controls);
        add(prompt);
        prompt.setup
            ( "Restart game?\n(Lose all progress)"
            , FlxG.resetState
            , ()->buttons.active = true
            , remove.bind(prompt)
            );
    }
    
    override function allowUnpause():Bool
    {
        return buttons.active;
    }
}

typedef RawControlsData = Array<{ action:String, keys:String, buttons:String }>;

// @:forward
// abstract ControlsData(RawControlsData) from RawControlsData to RawControlsData
// {
//     inline public function new () this = [];
    
//     inline public function add(action, keys, buttons)
//         this.push({ action:action, keys:keys, buttons:buttons });
    
//     inline public function addFromInput(input:Input, name:String = null)
//     {
//         this.push(
//             { action : name == null ? toTitleCase(input.getName()) : name
//             , keys   : keysTitleCase(input)
//             , buttons: buttonsTitleCase(input)
//             }
//         );
//     }
    
//     inline function keysTitleCase(input:Input)
//     {
//         var strList = "";
//         var list = Inputs.getKeys(input);
//         for (i in 0...list.length)
//         {
//             strList += toTitleCase(list[i]);
//             if (i < list.length)
//                 strList += " ";
//         }
//         return strList;
//     }
    
//     inline function buttonsTitleCase(input:Input)
//     {
//         var strList = "";
//         var list = Inputs.getPadButtons(input);
//         for (i in 0...list.length)
//         {
//             strList += toTitleCase(list[i]);
//             if (i < list.length)
//                 strList += " ";
//         }
//         return strList;
//     }
    
//     inline function toTitleCase(str:String)
//     {
//         return str.charAt(0) + str.substr(1).toLowerCase();
//     }
// }