package;

import common.HscriptTimer;
import saving.SaveManager;
import JsonDefinitions;
import assets.AssetCache;
import common.BasicHscript;
import flixel.FlxBasic;
import haxe.DynamicAccess;
import hscript.Expr;
import hscript.Interp;
import hscript.Parser;
import utility.LogFile;
import utility.Utils;


typedef PluginSavedata = {
    public var scriptSaveables:DynamicAccess<ScriptVariable>;

    public var timers:Array<HscriptTimerSave>;
}

class CorePlugin extends BasicHscript {

    public var savedata:PluginSavedata;

    public var name:String;

    public var saveTimers:Bool = false;

    override public function new(scriptPath:String, id:String) {
        savedata = {
            scriptSaveables: new DynamicAccess(),

            timers: null
        }

        name = id;

        super(scriptPath);
    }

    override private function compile(fullScript:String) {
        if(!exists) return;

        //Parse and compile
		try
        {
            program = parser.parseString(fullScript);
            interpreter.execute(program);

            ready = true;
        }
        catch (e)
        {
            // All exceptions will be caught here
            LogFile.error("Plugin error! |[ " + e.message + " ]| :" + parser.line+"\n",true);
        }
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------

    override function save() {
        if(!exists || !ready) return;
        
        doFunction("OnSave");

        if(saveTimers && timers != null) savedata.timers = timers.saveTimers();

        SaveManager.curSaveData.pluginSavedata.set(name, savedata);
    }

    override function load() {
        if(!exists || !ready) return;

        //load custom savedata from cur save data
        if(SaveManager.curSaveData.pluginSavedata.exists(name))
        savedata = SaveManager.curSaveData.pluginSavedata.get(name);

        if(saveTimers && savedata.timers != null) loadTimers(savedata.timers);

        doFunction("OnLoad");
    }

    public function gameStart() {
        if(!exists || !ready) return;
        
        doFunction("OnGameStart");
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------

    override public function AddVariables() {
        super.AddVariables();
		//BASICS
        AddGeneral("import", _import);

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
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------

    static final blacklist:Array<String> = []; //add keywords that cannot be imported for whatever reason.

    function _import(what:String, as:String) {
        if(!exists || (Utils.matchesAny(what, blacklist) || Utils.matchesAny(as, blacklist))) return;

        //ADD SPECIAL CASES HERE
        var special:Bool = true;
        switch (what.toLowerCase()){
            default: special = false;
            case "log", "logfile":
                AddGeneral(as, LogFile);
            case "con", "console":
                AddGeneral(as, Console);
        }
        if(special)
            return;

        //Otherwise, let this figure it out
        var c = Type.resolveClass(what);
        if(c == null) {LogFile.error("No class exists with the name "+what+"!"); return;}
        AddGeneral(as,c);
    }

    //-------------------------------------------------------------------------------------------------------------
    //--------------------------------------------------LOCAL VARS-------------------------------------------------
    //-------------------------------------------------------------------------------------------------------------

    public function initializeLocalString(name:String, value:String):Null<String> {
        var s = savedata.scriptSaveables.get(name);
        if(s == null){
            savedata.scriptSaveables.set(name,value);
        }

        return savedata.scriptSaveables.get(name);
    }

    public function initializeLocalInt(name:String, value:Int):Null<Int> {
        var s = savedata.scriptSaveables.get(name);
        if(s == null){
            savedata.scriptSaveables.set(name,value);
        }

        return savedata.scriptSaveables.get(name);
    }

    public function initializeLocalFloat(name:String, value:Float):Null<Float> {
        var s = savedata.scriptSaveables.get(name);
        if(s == null){
            savedata.scriptSaveables.set(name,value);
        }

        return savedata.scriptSaveables.get(name);
    }

    public function initializeLocalBool(name:String, value:Bool):Null<Bool> {
        var s = savedata.scriptSaveables.get(name);
        if(s == null){
            savedata.scriptSaveables.set(name,value);
        }

        return savedata.scriptSaveables.get(name);
    }

    public function getLocalString(name:String):Null<String> {
        var s = savedata.scriptSaveables.get(name);
        if(s != null){
            if(Std.isOfType(s,String)){
                return s;
            }
        }

        LogFile.error("Local STRING "+name+" Doesn't exist or is not a STRING type!");
        return null;
    }

    public function getLocalInt(name:String):Null<Int> {
        var i = savedata.scriptSaveables.get(name);
        if(i != null){
            if(Std.isOfType(i,Int)){
                return i;
            }
        }

        LogFile.error("Local INT "+name+" Doesn't exist or is not an INT type!");
        return null;
    }

    public function getLocalFloat(name:String):Null<Float> {
        var f = savedata.scriptSaveables.get(name);
        if(f != null){
            if(Std.isOfType(f,Float)){
                return f;
            }
        }

        LogFile.error("Local FLOAT "+name+" Doesn't exist or is not a FLOAT type!");
        return null;
    }

    public function getLocalBool(name:String):Null<Bool> {
        var b = savedata.scriptSaveables.get(name);
        if(b != null){
            if(Std.isOfType(b,Bool)){
                return b;
            }
        }

        LogFile.error("Local BOOL "+name+" Doesn't exist or is not a BOOL type!");
        return null;
    }

    public function setLocalBool(name:String,b:Bool):Null<Bool> {
        return savedata.scriptSaveables.set(name,b);
    }

    public function setLocalFloat(name:String,f:Float):Null<Float> {
        return savedata.scriptSaveables.set(name,f);
    }

    public function setLocalInt(name:String,i:Int):Null<Int> {
        return savedata.scriptSaveables.set(name,i);
    }

    public function setLocalString(name:String,s:String):Null<String> {
        return savedata.scriptSaveables.set(name,s);
    }
}