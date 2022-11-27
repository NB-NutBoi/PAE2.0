package;

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
}

class CorePlugin extends BasicHscript {

    public var savedata:PluginSavedata;

    public var name:String;

    override public function new(scriptPath:String, id:String) {
        savedata = {
            scriptSaveables: new DynamicAccess()
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

        SaveManager.curSaveData.pluginSavedata.set(name, savedata);
    }

    override function load() {
        if(!exists || !ready) return;

        //load custom savedata from cur save data
        if(SaveManager.curSaveData.pluginSavedata.exists(name))
        savedata = SaveManager.curSaveData.pluginSavedata.get(name);

        doFunction("OnLoad");
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------

    override public function AddVariables() {
		//BASICS
        AddGeneral("trace", _trace);

        AddGeneral("import", _import);
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

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
}