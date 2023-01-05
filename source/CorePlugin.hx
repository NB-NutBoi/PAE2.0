package;

import files.HXFile;
import common.HscriptTimer;
import saving.SaveManager;
import JsonDefinitions;
import assets.AssetCache;
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

class CorePluginBackend extends HaxeScriptBackend {

    public var savedata:PluginSavedata;

    public var name:String;

    public var saveTimers:Bool = false;

    override public function new(frontend:HaxeScript) {
        super(frontend);

        savedata = {
            scriptSaveables: new DynamicAccess(),

            timers: null
        }
    }

    override function AddVariables() {
        super.AddVariables();
        //BASICS
        importPerms = true;
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

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public function save() {
        if(!exists || !ready) return;
        
        doFunction("OnSave");

        if(saveTimers && timers != null) savedata.timers = timers.saveTimers();

        SaveManager.curSaveData.pluginSavedata.set(name, savedata);
    }

    public function load() {
        if(!exists || !ready) return;

        //load custom savedata from cur save data
        if(SaveManager.curSaveData.pluginSavedata.exists(name))
        savedata = SaveManager.curSaveData.pluginSavedata.get(name);

        if(saveTimers && savedata.timers != null) loadTimers(savedata.timers);

        doFunction("OnLoad");
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
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