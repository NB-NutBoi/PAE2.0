package common;

import JsonDefinitions;
import assets.AssetCache;
import flixel.FlxBasic;
import haxe.DynamicAccess;
import hscript.Expr;
import hscript.Interp;
import hscript.Parser;
import utility.LogFile;
import utility.Utils;

class BasicHscript extends FlxBasic implements HScriptable {
    
    public var ready:Bool;

    public var parser:Parser;
	public var program:Expr;
	public var interpreter:Interp;

    override public function new(scriptPath:String) {
        super();

        ready = false;
        
		parser = new hscript.Parser();
		parser.allowTypes = true;
        
        //set preprocesorValues
        parser.preprocesorValues.set("windows", #if windows true #else false #end);
        parser.preprocesorValues.set("mac", #if mac true #else false #end);
        parser.preprocesorValues.set("desktop", #if desktop true #else false #end);
        parser.preprocesorValues.set("telemetry", #if telemetry true #else false #end);
        parser.preprocesorValues.set("linux", #if linux true #else false #end);

		interpreter = new hscript.Interp();

        AddVariables();
        compile(AssetCache.getDataCache(scriptPath));

        if(!ready) return;
        
        awake();

        parser = null; //i don't think we need the parser at all anymore?
    }

    private function compile(fullScript:String) {
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
            LogFile.error("Script error! |[ " + e.message + " ]| :" + parser.line+"\n",true);
        }
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

    public function AddVariables() {
		//BASICS
        AddGeneral("trace", _trace);
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

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------

    override function update(elapsed:Float) {
        if(!exists || !ready) return;

        doFunction("OnUpdate", [elapsed]);
    }

    public function lateUpdate(elapsed:Float) {
        if(!exists || !ready) return;

        doFunction("OnLateUpdate", [elapsed]);
    }

    override function draw() {
        if(!exists || !ready) return;

        doFunction("OnDraw");
    }

    function awake() {
        if(!exists || !ready) return;

        doFunction("OnAwake");
    }

    public function start() {
        if(!exists || !ready) return;

        doFunction("OnStart");
    }

    override function destroy() {
        if(!exists || !ready) return;

        doFunction("OnDestroy");
    }

    public function save() {
        if(!exists || !ready) return;

        doFunction("OnSave");
    }

    public function load() {
        if(!exists || !ready) return;

        doFunction("OnLoad");
    }
}

interface HScriptable {
    public var ready:Bool;

    var parser:Parser;
	var program:Expr;
	var interpreter:Interp;
}