package beat;

import flixel.FlxG;
import flixel.FlxBasic;

class BeatGame extends flixel.FlxGame
{
    static public var beatsPerMinute = 110.0;
    static public var beatsPerSecond(get, never):Float;
    inline static function get_beatsPerSecond() return beatsPerMinute / 60;
    static public var prevMusicTime = 0.0;
    static public var beatTime(get, never):Float;
    inline static function get_beatTime() return 60 / beatsPerMinute;
    // Disabled because it might fuck everything up
    //
    // override function onEnterFrame(_):Void
    // {
    //     ticks = getTicks();
    //     _elapsedMS = ticks - _total;
    //     _total = ticks;
    //     
    //     #if FLX_SOUND_TRAY
    //     if (soundTray != null && soundTray.active)
    //         soundTray.update(_elapsedMS);
    //     #end
    //     
    //     if (!_lostFocus || !FlxG.autoPause)
    //     {
    //         if (FlxG.vcr.paused)
    //         {
    //             if (FlxG.vcr.stepRequested)
    //             {
    //                 FlxG.vcr.stepRequested = false;
    //             }
    //             else if (_state == _requestedState) // don't pause a state switch request
    //             {
    //                 #if FLX_DEBUG
    //                 debugger.update();
    //                 // If the interactive debug is active, the screen must
    //                 // be rendered because the user might be doing changes
    //                 // to game objects (e.g. moving things around).
    //                 if (debugger.interaction.isActive())
    //                 {
    //                     draw();
    //                 }
    //                 #end
    //                 return;
    //             }
    //         }
    //         
    //         if (FlxG.fixedTimestep)
    //         {
    //             var delta = 0.0;
    //             if (FlxG.sound != null && FlxG.sound.music != null && FlxG.sound.music.playing)
    //             {
    //                 final music = FlxG.sound.music;
    //                 if (music.time >= prevMusicTime)
    //                     delta = music.time - prevMusicTime;
    //                 else
    //                 {
    //                     delta = (music.time - music.loopTime) + (music.length - prevMusicTime);
    //                     if (delta > _maxAccumulation)
    //                         delta = 0;//TODO: figure out this shit
    //                 }
    //                 prevMusicTime = music.time;
    //             }
    //            
    //             if (delta > 0)
    //             {
    //                 // if (delta > _maxAccumulation)
    //                 //     trace('delta:$delta');
    //                 _accumulator += delta;
    //             }
    //             else
    //             {
    //                 _accumulator += _elapsedMS;
    //                 _accumulator = (_accumulator > _maxAccumulation) ? _maxAccumulation : _accumulator;
    //             }
    //            
    //             while (_accumulator >= _stepMS)
    //             {
    //                 step();
    //                 _accumulator -= _stepMS;
    //             }
    //         }
    //         else
    //         {
    //             step();
    //         }
    //         
    //         #if FLX_DEBUG
    //         FlxBasic.visibleCount = 0;
    //         #end
    //        
    //         draw();
    //         
    //         #if FLX_DEBUG
    //         debugger.stats.visibleObjects(FlxBasic.visibleCount);
    //         debugger.update();
    //         #end
    //     }
    // }
}