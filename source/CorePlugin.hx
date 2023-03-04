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

class CorePluginBackend extends SaveableHaxeScriptBackend {

    public var name:String;
    public var saveTimers:Bool = false;

    override function logWarning(Message:String, ?Trace:Bool = false, ?Print:Bool = false) {
        trace(name);
        super.logWarning("[CorePlugin: "+name+"] "+Message, Trace, Print);
    }

    override function logError(Message:String, ?Trace:Bool = false, ?Print:Bool = false) {
        super.logError("[CorePlugin: "+name+"] "+Message, Trace, Print);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    override public function save() {
        trace(name);
        if(!exists || !ready) return;
        
        doFunction("OnSave");

        if(saveTimers && timers != null) state.timers = timers.saveTimers();

        SaveManager.curSaveData.pluginSavedata.set(name, state);
    }

    override public function load() {
        if(!exists || !ready) return;

        //load custom savedata from cur save data
        if(SaveManager.curSaveData.pluginSavedata.exists(name))
        state = SaveManager.curSaveData.pluginSavedata.get(name);

        if(saveTimers && state.timers != null) loadTimers(state.timers);

        doFunction("OnLoad");
    }
}