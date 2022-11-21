package common;

import flixel.FlxG;
import lime.ui.MouseCursor;
import openfl.ui.MouseCursor;

class Mouse {
    
    static var current:MouseCursor = MouseCursor.ARROW;
    static var oneFrame:Bool = false; //give it one frame buffer time so it's not ping-ponging from default to special every frame

    public static function reset() {
        if(!FlxG.mouse.useSystemCursor) return;
        
        if(current != ARROW){
            if(oneFrame){
                current = ARROW;
                openfl.ui.Mouse.cursor = "arrow"; //only reset if one frame has elapsed with this set to true.
                oneFrame = false; //reset it once set to default just in case.
            }
            else{
                oneFrame = true;
            }
        } 
    }

    public static function setAs(type:MouseCursor) {
        if(!FlxG.mouse.useSystemCursor) return;
        
        if(current != type){
            current = type;
            openfl.ui.Mouse.cursor = type;
        }
        oneFrame = false;
    }

    

    public static inline function show() {
        if(!FlxG.mouse.useSystemCursor) FlxG.mouse.visible = true;
        else openfl.ui.Mouse.show();
    }

    public static inline function hide() {
        if(!FlxG.mouse.useSystemCursor) FlxG.mouse.visible = false;
        else openfl.ui.Mouse.hide();
    }
}