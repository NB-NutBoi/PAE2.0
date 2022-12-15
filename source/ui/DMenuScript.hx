package ui;

import Discord.DiscordClient;
import common.BasicHscript.HScriptable;
import hscript.Expr;
import hscript.Interp;
import hscript.Parser;
import sys.io.File;
import utility.LogFile;
import utility.Utils;

class DMenuScript implements HScriptable {

    public var owner:DMenu;

    public var exists:Bool;
    public var ready:Bool;
    public var compiling:Bool = false;

    public var parser:Parser;
	public var program:Expr;
	public var interpreter:Interp;
    
    public function new(file:String, owner:DMenu) {
        if(owner == null) return;
        this.owner = owner;
        exists = true;
        ready = false;

        if(!Utils.checkExternalHaxeFileValid(file)) return;

        parser = new hscript.Parser();
		parser.allowTypes = true;
        
        //set preprocesorValues
        parser.preprocesorValues.set("windows", #if windows true #else false #end);
        parser.preprocesorValues.set("mac", #if mac true #else false #end);
        parser.preprocesorValues.set("desktop", #if desktop true #else false #end);
        parser.preprocesorValues.set("telemetry", #if telemetry true #else false #end);
        parser.preprocesorValues.set("linux", #if linux true #else false #end);
        parser.preprocesorValues.set("discord", #if windows DiscordClient.active #else false #end);

		interpreter = new hscript.Interp();

        AddVariables();
        compile(File.getContent(file));

        if(!ready) return;

        awake();

        parser = null; //i don't think we need the parser at all anymore?
    }

    private function awake() {
        if(!exists || !ready) return;

        doFunction("OnAwake");
    }

    public function update(elapsed:Float) {
        if(!exists || !ready) return;

        //do update idk
        doFunction("OnUpdate", [elapsed]);
    }

    public function updateInputs(elapsed:Float) {
        if(!exists || !ready) return;
        doFunction("OnUpdateInputs", [elapsed]);
    }

    public function postUpdate(elapsed:Float) {
        if(!exists || !ready) return;
        doFunction("OnPostUpdate", [elapsed]);
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    
    public function AddVariables() {
		//BASICS
        AddGeneral("trace", _trace);
        AddGeneral("DMenu", owner);

        AddGeneral("import", _import);
    }

	public function AddGeneral(name:String,toAdd:Dynamic)
	{if(!exists) return;
        interpreter.variables.set(name, toAdd);
	}

    private function _trace(content:Dynamic) {
        trace(content);
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------

    public function getFunction(func:String):Dynamic {
		if (!ready || !exists)
			return null;

        final f = interpreter.variables[func];
		if(Reflect.isFunction(f))
			return f;

		return null;
    }

	public function doFunction(func:String, ?args:Array<Dynamic>):Dynamic {
        if (!ready || !exists) return null;
        
		final Function = getFunction(func);

		if (Function != null){
			if(args == null)
				args = [];

			
			var r = Reflect.callMethod(this,Function,args);
			return r;
		}
		else{
            //make sure the console isn't getting flooded because timmy forgot to add the OnUpdate function to his code, all of these are potentially unneeded.
            if(!Utils.matchesAny(func, Main.defaultFunctions))
                Console.logWarning("tried calling non-existing function "+ func+" of dmenu script!");
		}

		return null;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    
    private function compile(fullScript:String) {
        if(!exists) return;
        
        compiling = true;

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
            LogFile.error("Component error! |[ " + e.message + " ]| :" + parser.line+"\n",true);
        }

        compiling = false;
    }

    static final blacklist:Array<String> = ["DMenu"]; //add keywords that cannot be imported for whatever reason.

    function _import(what:String, as:String) {
        if(!exists || (Utils.matchesAny(what, blacklist) || Utils.matchesAny(as, blacklist))) return;

        //ADD SPECIAL CASES HERE
        var special:Bool = false;
        switch (what.toLowerCase()){
            case "log", "logfile":
                AddGeneral(as, LogFile);
                special = true;
            case "con", "console":
                AddGeneral(as, Console);
                special = true;
        }
        if(special)
            return;

        //Otherwise, let this figure it out
        var c = Type.resolveClass(what);
        if(c == null) {LogFile.error("No class exists with the name "+what+"!"); return;}
        AddGeneral(as,c);
    }
}