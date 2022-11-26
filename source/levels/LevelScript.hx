package levels;

import saving.SaveManager;
import utility.LogFile;
import common.BasicHscript;
import flixel.FlxBasic;

class LevelScript extends BasicHscript {

    //class for level script.
    //this script cannot import anything, and has to have everything imported by some superior script like a plugin or main script

    public static var levelImports:Map<String,Array<{value:Dynamic, name:String}>> = new Map();

    public static function addLevelImportPack(name:String, pack:Array<{value:Dynamic, name:String}>) {
        levelImports.set(name,pack);
    }

    public static function getLevelImportPack(name:String) {
        return levelImports.get(name);
    }

    public static function removeLevelImportPack(name:String) {
        if(!levelImports.exists(name)) return;
        levelImports.remove(name);
    }

    //----------------------------------------------------------------------------------------


    public var level:Level;
    
    override public function new(owner:Level, scriptPath:String) {
        level = owner;
        super(scriptPath);
    }

    override function AddVariables() {
        super.AddVariables();

        //SAVEABLE VARS

        //initializers
        AddGeneral("initializeLocalString",initializeLocalString);
        AddGeneral("initializeLocalInt",initializeLocalInt);
        AddGeneral("initializeLocalFloat",initializeLocalFloat);
        AddGeneral("initializeLocalBool",initializeLocalBool);

        //getters
        AddGeneral("getLocalString",getLocalString);
        AddGeneral("getLocalInt",getLocalInt);
        AddGeneral("getLocalFloat",getLocalFloat);
        AddGeneral("getLocalBool",getLocalBool);

        //setters
        AddGeneral("setLocalBool",setLocalBool);
        AddGeneral("setLocalFloat",setLocalFloat);
        AddGeneral("setLocalInt",setLocalInt);
        AddGeneral("setLocalString",setLocalString);

        for (pack in levelImports) {
            for (imp in pack) {
                AddGeneral(imp.name,imp.value);
            }
        }
    }

    //----------------------------------------------------------------------------------------

    public function onLeave() 
    {if(!exists || !ready) return;

        if(getFunction("OnLeave") != null)
            doFunction("OnLeave");
    }

    public function onEnter()
    {if(!exists || !ready) return;

        if(getFunction("OnEnter") != null)
            doFunction("OnEnter");
    }

    //-------------------------------------------------------------------------------------------------------------
    //-----------------------------------------------GLOBAL/LOCAL VARS---------------------------------------------
    //-------------------------------------------------------------------------------------------------------------

    public function initializeLocalString(name:String, value:String):Null<String> {
        var s = level.saveables.scriptSaveables.get(name);
        if(s == null){
            level.saveables.scriptSaveables.set(name,value);
        }

        return level.saveables.scriptSaveables.get(name);
    }

    public function initializeLocalInt(name:String, value:Int):Null<Int> {
        var s = level.saveables.scriptSaveables.get(name);
        if(s == null){
            level.saveables.scriptSaveables.set(name,value);
        }

        return level.saveables.scriptSaveables.get(name);
    }

    public function initializeLocalFloat(name:String, value:Float):Null<Float> {
        var s = level.saveables.scriptSaveables.get(name);
        if(s == null){
            level.saveables.scriptSaveables.set(name,value);
        }

        return level.saveables.scriptSaveables.get(name);
    }

    public function initializeLocalBool(name:String, value:Bool):Null<Bool> {
        var s = level.saveables.scriptSaveables.get(name);
        if(s == null){
            level.saveables.scriptSaveables.set(name,value);
        }

        return level.saveables.scriptSaveables.get(name);
    }

    public function getLocalString(name:String):Null<String> {
        var s = level.saveables.scriptSaveables.get(name);
        if(s != null){
            if(Std.isOfType(s,String)){
                return s;
            }
        }

        LogFile.error("Local STRING "+name+" Doesn't exist or is not a STRING type!");
        return null;
    }

    public function getLocalInt(name:String):Null<Int> {
        var i = level.saveables.scriptSaveables.get(name);
        if(i != null){
            if(Std.isOfType(i,Int)){
                return i;
            }
        }

        LogFile.error("Local INT "+name+" Doesn't exist or is not an INT type!");
        return null;
    }

    public function getLocalFloat(name:String):Null<Float> {
        var f = level.saveables.scriptSaveables.get(name);
        if(f != null){
            if(Std.isOfType(f,Float)){
                return f;
            }
        }

        LogFile.error("Local FLOAT "+name+" Doesn't exist or is not a FLOAT type!");
        return null;
    }

    public function getLocalBool(name:String):Null<Bool> {
        var b = level.saveables.scriptSaveables.get(name);
        if(b != null){
            if(Std.isOfType(b,Bool)){
                return b;
            }
        }

        LogFile.error("Local BOOL "+name+" Doesn't exist or is not a BOOL type!");
        return null;
    }

    public function setLocalBool(name:String,b:Bool):Null<Bool> {
        return level.saveables.scriptSaveables.set(name,b);
    }

    public function setLocalFloat(name:String,f:Float):Null<Float> {
        return level.saveables.scriptSaveables.set(name,f);
    }

    public function setLocalInt(name:String,i:Int):Null<Int> {
        return level.saveables.scriptSaveables.set(name,i);
    }

    public function setLocalString(name:String,s:String):Null<String> {
        return level.saveables.scriptSaveables.set(name,s);
    }

    //---------------------------------------------------------------------------------------------------

}