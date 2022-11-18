package;

import openfl.Lib;
import openfl.display.MovieClip;
import openfl.ui.Keyboard;
#if USING_DCONSOLE
import pgr.dconsole.DC;
import pgr.dconsole.DCThemes;
import pgr.dconsole.ui.DCOpenflInterface;
#end

class Console {

    public static final DEFAULT:Int = -1;
    public static final REPLY_METRIC:Int = 0xFF3ED2FF;

    public static final FUNCTION_REPLY:Int = 0xFFA0A0A0;
    public static final FUNCTION_REPLY_ERROR:Int = 0xFF9B1717;
    public static final FUNCTION_REPLY_WARN:Int = 0xFFA38E16;

    public static final CONSOLE_COLOR_1:Int = 0xFFA4D38E;
    public static final CONSOLE_COLOR_2:Int = 0xFFC58ED3;
    public static final CONSOLE_COLOR_3:Int = 0xFF8E95D3;

    public static function init(?font:String = null) {
        if(Main.DEBUG){
            #if USING_DCONSOLE
            DC.init();

            if(font != null) DC.setFont(font);

            DC.setConsoleKey(Keyboard.F1, false, false, false);
            DC.setProfilerKey(Keyboard.F1, false, true, false);
            DC.setMonitorKey(Keyboard.F1, true, false, false);
            #end
        }
    }

    public static function bringToFront() {
        if(Main.DEBUG){
            #if USING_DCONSOLE
            DC.toFront();
            #end
        }
    }

    //----------------------------------------------------------------------------------------------------------------------------------------------------
    //-------------------------------------------------------------------------------PROFILING------------------------------------------------------------
    //----------------------------------------------------------------------------------------------------------------------------------------------------

    public static function beginProfile(sampleName:String) {
        if(Main.DEBUG){
            #if USING_DCONSOLE
            DC.beginProfile(sampleName);
            #end
        }
    }

    public static function endProfile(sampleName:String) {
        if(Main.DEBUG){
            #if USING_DCONSOLE
            DC.endProfile(sampleName);
            #end
        }
    }


    //----------------------------------------------------------------------------------------------------------------------------------------------------
    //--------------------------------------------------------------------------------LOGGING-------------------------------------------------------------
    //----------------------------------------------------------------------------------------------------------------------------------------------------
    
    public static function log(data:Dynamic, ?color:Int = -1) {
        if(Main.DEBUG){
            #if USING_DCONSOLE
            DC.log(data, color);
            #end
        }
    }

    public static function logConfirmation(data:Dynamic) {
        if(Main.DEBUG){
            #if USING_DCONSOLE
            DC.logConfirmation(data);
            #end
        }
    }

    public static function logError(data:Dynamic) {
        if(Main.DEBUG){
            #if USING_DCONSOLE
            DC.logError(data);
            #end
        }
    }

    public static function logInfo(data:Dynamic) {
        if(Main.DEBUG){
            #if USING_DCONSOLE
            DC.logInfo(data);
            #end
        }
    }

    public static function logWarning(data:Dynamic) {
        if(Main.DEBUG){
            #if USING_DCONSOLE
            DC.logWarning(data);
            #end
        }
    }

    static public function registerCommand(Function:Array<String>->Void, alias:String,  shortcut:String = "", description:String = "", help:String = "") 
    {
        if(Main.DEBUG){
            #if USING_DCONSOLE
            DC.registerCommand(Function, alias, shortcut, description, help);
            #end
        }
    }

    //----------------------------------------------------------------------------------------------------------------------------------------------------
    //---------------------------------------------------------------------------------MISC---------------------------------------------------------------
    //----------------------------------------------------------------------------------------------------------------------------------------------------

    public static function setFont(font:String) {
        if(Main.DEBUG){
            #if USING_DCONSOLE
            DC.setFont(font);
            //DC.setConsoleFont(font);
            #end
        }
    }

    public static function getDefaultTheme() {
        if(Main.DEBUG){
            #if USING_DCONSOLE
            return DCThemes.current;
            //DC.setConsoleFont(font);
            #end
        }
        else{
            return null;
        }
    }

    @:access(pgr.dconsole.ui.DCOpenflInterface)
    public static function overlaps() {
        if(Main.DEBUG){
            #if USING_DCONSOLE
            return Lib.current.stage.focus == cast(DC.instance.interfc, DCOpenflInterface).txtPrompt;
            #else
            return false;
            #end
        }
        else{
            return false;
        }
    }

}

class ConsoleStringTools {
    public static inline function toFunctionReply(s:String):String{
        return "    - "+s;
    }
}