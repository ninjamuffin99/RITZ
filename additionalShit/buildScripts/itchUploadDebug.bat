@echo off
color 0e
cd ..
cd ..
@echo on
lime build html5 -release
butler push ./export/release/html5/bin ninja-muffin24/pixel-day-2020:html5 
butler status ninja-muffin24/pixel-day-2020:html5
pause