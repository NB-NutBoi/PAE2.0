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

    public static var x(get,null):Int;
    static function get_x():Int {return FlxG.mouse.x;}

    public static var y(get,null):Int;
    static function get_y():Int {return FlxG.mouse.y;}

    //click functions

    public static var justPressed(get,null):Bool;
    public static function get_justPressed():Bool {return FlxG.mouse.justPressed;}

    public static var pressed(get,null):Bool;
    static function get_pressed():Bool {return FlxG.mouse.pressed;}

    public static var justReleased(get,null):Bool;
    static function get_justReleased():Bool {return FlxG.mouse.justReleased;}

    public static var justPressedRight(get,null):Bool;
    static function get_justPressedRight():Bool {return FlxG.mouse.justPressedRight;}

    public static var pressedRight(get,null):Bool;
    static function get_pressedRight():Bool {return FlxG.mouse.pressedRight;}

    public static var justReleasedRight(get,null):Bool;
    static function get_justReleasedRight():Bool {return FlxG.mouse.justReleasedRight;}

    public static var justPressedMiddle(get,null):Bool;
    static function get_justPressedMiddle():Bool {return FlxG.mouse.justPressedMiddle;}

    public static var pressedMiddle(get,null):Bool;
    static function get_pressedMiddle():Bool {return FlxG.mouse.pressedMiddle;}

    public static var justReleasedMiddle(get,null):Bool;
    static function get_justReleasedMiddle():Bool {return FlxG.mouse.justReleasedMiddle;}

    //other functions

    public static var visible(get,set):Bool;
    static function get_visible():Bool {return FlxG.mouse.visible;}
    static function set_visible(value:Bool):Bool {return FlxG.mouse.visible = value;}

    public static var justMoved(get,null):Bool;
    static function get_justMoved():Bool {return FlxG.mouse.justMoved;}

    public static var wheel(get,null):Int;
    static function get_wheel():Int {return FlxG.mouse.wheel;}
    
}