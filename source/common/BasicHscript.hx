package common;

import saving.SaveManager;
import sys.io.File;
import sys.FileSystem;
import JsonDefinitions;
import assets.AssetCache;
import flixel.FlxBasic;
import haxe.DynamicAccess;
import hscript.Expr;
import hscript.Interp;
import hscript.Parser;
import utility.LogFile;
import utility.Utils;

using StringTools;

class BasicHscript extends FlxBasic implements HScriptable {
    
    public var ready:Bool;

    public var parser:Parser;
	public var program:Expr;
	public var interpreter:Interp;

    //----------------------------------------------

    //scriptdef

    public var properties:Map<String,String>;

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
            program = parser.parseString(preprocessString(fullScript));
            interpreter.execute(program);

            ready = true;
        }
        catch (e)
        {
            // All exceptions will be caught here
            LogFile.error("Script error! |[ " + e.message + " ]| :" + parser.line+"\n",true);
        }

        dynamicImports = null;
    }
    
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------

    var dynamicImports:Array<String> = [];
    function preprocessString(script:String, ?og:Bool = true) {
        var finalString:String = script;
		var lines = script.split("\n");

        for (i in 0...lines.length) {
            var line = lines[i].trim();

            //optimization
            if(line.length == 0 || line == "") continue;
			if(line.startsWith("//")) continue;

            //early stop (optimization)
			if(line.startsWith("#FLAG_STOP_PREPROCESS")){
				finalString = finalString.replace(lines[i],"");

				break;
			}

            // imports
            if(line.startsWith("#import")){
                var imp:String = line.split(" ")[1].trim();
				

				if (dynamicImports.contains(imp)){
                    finalString = finalString.replace(lines[i],"");
                    continue;
                }
					

				dynamicImports.push(imp);

				if (!FileSystem.exists(imp) || !imp.endsWith(".hx")){
                    finalString = finalString.replace(lines[i],"");
                    continue;
                }
					
                finalString = finalString.replace(lines[i],preprocessString(File.getContent(imp).toString(),false));
				continue;
            }

            //defines pieces of code
			if(line.startsWith("#define")){
				var dNd = getDefineAndDefined(line);

                // remove to avoid crash
				finalString = finalString.replace(lines[i], "");

                if(dNd.length != 2) continue;

				var defined:String = dNd[0];
				var define:String = dNd[1];

				//careful with your defines, they replace ALL instances of that string in the code, no matter where
				finalString = finalString.replace(defined, define);
				continue;
			}

            //defines properties
            if (line.startsWith("#property")){

                // remove to avoid crash
				finalString = finalString.replace(lines[i], "");

                if(!og) continue;

                final propertees = line.split(" ");
				var property:String = propertees[1].trim();
				var value:String = propertees[2].trim();

				properties.set(property,value);

				continue;
            }
        }

        lines = null;

        return finalString;
    }

    static function getDefineAndDefined(s:String):Array<String> {
		var r:Array<String> = [];

		s = s.replace("#define","").trim();

		r = s.split(" as ").map(function (s:String) {
			return s.trim();
		});

		return r;
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


        //GLOBALS

        //initializers
        AddGeneral("initializeGlobalString",initializeGlobalString);
        AddGeneral("initializeGlobalInt",initializeGlobalInt);
        AddGeneral("initializeGlobalFloat",initializeGlobalFloat);
        AddGeneral("initializeGlobalBool",initializeGlobalBool);

        //getters
        AddGeneral("getGlobalString",getGlobalString);
        AddGeneral("getGlobalInt",getGlobalInt);
        AddGeneral("getGlobalFloat",getGlobalFloat);
        AddGeneral("getGlobalBool",getGlobalBool);

        //setters
        AddGeneral("setGlobalBool",setGlobalBool);
        AddGeneral("setGlobalFloat",setGlobalFloat);
        AddGeneral("setGlobalInt",setGlobalInt);
        AddGeneral("setGlobalString",setGlobalString);
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

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------

    public function initializeGlobalString(name:String, value:String):Null<String> {
        var s = SaveManager.curSaveData.globals.scriptSaveables.get(name);
        if(s == null){
            SaveManager.curSaveData.globals.scriptSaveables.set(name,value);
        }

        return SaveManager.curSaveData.globals.scriptSaveables.get(name);
    }

    public function initializeGlobalInt(name:String, value:Int):Null<Int> {
        var i = SaveManager.curSaveData.globals.scriptSaveables.get(name);
        if(i == null){
            SaveManager.curSaveData.globals.scriptSaveables.set(name,value);
        }

        return SaveManager.curSaveData.globals.scriptSaveables.get(name);
    }

    public function initializeGlobalFloat(name:String, value:Float):Null<Float> {
        var f = SaveManager.curSaveData.globals.scriptSaveables.get(name);
        if(f == null){
            SaveManager.curSaveData.globals.scriptSaveables.set(name,value);
        }

        return SaveManager.curSaveData.globals.scriptSaveables.get(name);
    }

    public function initializeGlobalBool(name:String, value:Bool):Null<Bool> {
        var b = SaveManager.curSaveData.globals.scriptSaveables.get(name);
        if(b == null){
            SaveManager.curSaveData.globals.scriptSaveables.set(name,value);
        }

        return SaveManager.curSaveData.globals.scriptSaveables.get(name);
    }

    public function getGlobalString(name:String):Null<String> {
        var s = SaveManager.curSaveData.globals.scriptSaveables.get(name);
        if(s != null){
            if(Std.isOfType(s,String)){
                return s;
            }
        }

        LogFile.error("Global STRING "+name+" Doesn't exist or is not a STRING type!");
        return null;
    }

    public function getGlobalInt(name:String):Null<Int> {
        var i = SaveManager.curSaveData.globals.scriptSaveables.get(name);
        if(i != null){
            if(Std.isOfType(i,Int)){
                return i;
            }
        }

        LogFile.error("Global INT "+name+" Doesn't exist or is not an INT type!");
        return null;
    }

    public function getGlobalFloat(name:String):Null<Float> {
        var f = SaveManager.curSaveData.globals.scriptSaveables.get(name);
        if(f != null){
            if(Std.isOfType(f,Float)){
                return f;
            }
        }

        LogFile.error("Global FLOAT "+name+" Doesn't exist or is not a FLOAT type!");
        return null;
    }

    public function getGlobalBool(name:String):Null<Bool> {
        var b = SaveManager.curSaveData.globals.scriptSaveables.get(name);
        if(b != null){
            if(Std.isOfType(b,Bool)){
                return b;
            }
        }

        LogFile.error("Global BOOL "+name+" Doesn't exist or is not a BOOL type!");
        return null;
    }

    public function setGlobalBool(name:String,b:Bool):Null<Bool> {
        return SaveManager.curSaveData.globals.scriptSaveables.set(name,b);
    }

    public function setGlobalFloat(name:String,f:Float):Null<Float> {
        return SaveManager.curSaveData.globals.scriptSaveables.set(name,f);
    }

    public function setGlobalInt(name:String,i:Int):Null<Int> {
        return SaveManager.curSaveData.globals.scriptSaveables.set(name,i);
    }

    public function setGlobalString(name:String,s:String):Null<String> {
        return SaveManager.curSaveData.globals.scriptSaveables.set(name,s);
    }
}

interface HScriptable {
    public var ready:Bool;

    var parser:Parser;
	var program:Expr;
	var interpreter:Interp;
}