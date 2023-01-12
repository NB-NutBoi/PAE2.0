package files;

import lowlevel.HAbstracts;
import Discord;
import saving.SaveManager;
import utility.Utils;
import sys.io.File;
import sys.FileSystem;
import utility.LogFile;
import hscript.Parser;
import hscript.Expr;
import hscript.Interp;

import common.HscriptTimer;

using StringTools;

/**
 * Haxe File
 * 
 * Standard utility for loading haxe files with hscript
 * 
 * @author NutBoi
 */
class HXFile {

    //making/compiling functions.

    public static function makeNew(?managerClass:Class<HaxeScriptBackend> = null):HaxeScript {
        return new HaxeScript(managerClass);
    }

    public static function fromFile(path:String, ?managerClass:Class<HaxeScriptBackend> = null):HaxeScript {
        final script = makeNew(managerClass);
        compileFromFile(script, path);
        return script;
    }

    public static function compileFromFile(script:HaxeScript, path:String) {
        if(!Utils.checkExternalHaxeFileValid(path)) return;
        final content = File.getContent(path);
        script.backend.compile(content);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public static function destroy(script:HaxeScript) {
        script.destroy();
    }

    public static function update(script:HaxeScript, elapsed:Float){
        script.update(elapsed);
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

abstract HaxeScript(Dynamic) to Dynamic {

    //imagine that backend is a default variable for this allways.
    public var backend(get, never):HaxeScriptBackend;
    inline function get_backend():HaxeScriptBackend {return this.backend;}

    public var _dynamic(get, never):Dynamic;
    inline function get__dynamic():Dynamic {return this;}

    @:allow(files.HXFile)
    private function new(?managerClass:Class<HaxeScriptBackend> = null)
    {
        if(managerClass == null) managerClass = HaxeScriptBackend;
        this = {};

        //create backend.
        this.backend = Type.createInstance(managerClass,[this]);
    }

    public inline function clear() {
        for (s in Reflect.fields(this)) {
            if(s == "backend") continue;
            Reflect.deleteField(this,s);
        }
    }

    public inline function functionExists(func:String):Bool {
        return this.backend.functionExists(func);
    }

    public inline function getFunction(func:String):Dynamic {
        return this.backend.getFunction(func);
    }

    public inline function doFunction(func:String, ?args:Array<Dynamic>) {
        this.backend.doFunction(func,args);
    }

    public inline function update(elapsed:Float) {
        this.backend.update(elapsed);
    }

    public inline function destroy() {
        this.backend.destroy();
        this.backend = null;
        this = null;
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

class HaxeScriptBackend {

    //i love hacky workarounds
    final fileStandard:String = "
    //script file standard.
    //------------------------------------------------------------
    function __getVarExists(name:String, interpreter:InterpPlus):Bool
    {
        return interpreter.locals.exists(name);
    }
    function __setVar(name:String, to:Dynamic, interpreter:InterpPlus):Dynamic
    { if(!interpreter.locals.exists(name)) return null;
        return interpreter.locals.get(name).r = to;
    }
    function __getVar(name:String, interpreter:InterpPlus):Dynamic
    { if(!interpreter.locals.exists(name)) return null;
        return interpreter.locals.get(name).r;
    }";

    final logScriptOnError:Bool = true;

    public var exists:Bool = false;
    public var compiled:Bool = false;
    public var ready:Bool = false;

    public var timers:HscriptTimerManager;

    public var parser:Parser;
	public var program:Expr;
    public var interpreter:InterpPlus;

    public var frontend:HaxeScript = null;

    //-----------------------------------------------

    public var properties:Map<String,String>;
    
    private function new(frontend:HaxeScript) {
        this.frontend = frontend;

        decompile();
        
        exists = true;
    }

    //DIVIDE PROCESS.
    //-------------------------------------------------

    //pre-compile

    public function decompile() {
        if(!compiled && exists) return;

        //Decompile and revert to default

        frontend.clear();

        interpreter = null;
        program = null;
        parser = null;

        parser = new hscript.Parser();
		parser.allowTypes = true;

        interpreter = new InterpPlus(frontend);

        compiled = false;
        ready = false;
    }

    public function setCompilerFlag(name:String, value:Bool) {
        if(!exists || compiled) return;
        parser.preprocesorValues.set(name, value);
    }

    /**
     * Override to add your own variables before compile.
     */
    public function AddVariables() {
        AddGeneral("this",frontend);
        AddGeneral("trace",_trace);
        AddGeneral("cast", ScriptGlobals.Cast);

        AddGeneral("getTimers", getTimers);

        AddGeneral("abstracts", HAbstracts);

        //GLOBALS

        //initializers
        AddGeneral("initializeGlobalString",ScriptGlobals.initializeGlobalString);
        AddGeneral("initializeGlobalInt",ScriptGlobals.initializeGlobalInt);
        AddGeneral("initializeGlobalFloat",ScriptGlobals.initializeGlobalFloat);
        AddGeneral("initializeGlobalBool",ScriptGlobals.initializeGlobalBool);

        //getters
        AddGeneral("getGlobalString",ScriptGlobals.getGlobalString);
        AddGeneral("getGlobalInt",ScriptGlobals.getGlobalInt);
        AddGeneral("getGlobalFloat",ScriptGlobals.getGlobalFloat);
        AddGeneral("getGlobalBool",ScriptGlobals.getGlobalBool);

        //setters
        AddGeneral("setGlobalBool",ScriptGlobals.setGlobalBool);
        AddGeneral("setGlobalFloat",ScriptGlobals.setGlobalFloat);
        AddGeneral("setGlobalInt",ScriptGlobals.setGlobalInt);
        AddGeneral("setGlobalString",ScriptGlobals.setGlobalString);
    }

    public function AddGeneral(name:String,toAdd:Dynamic)
    {if(Utils.checkNull(interpreter, false, null, "Cannot add general before interpreter creation.")) return;
        interpreter.variables.set(name, toAdd);
    }

    public function RegisterExternalFunction(name:String,func:Dynamic) {
        if(!Reflect.isFunction(func)) return;
        interpreter.variables.set(name, func);
        Reflect.setField(frontend,name,func);
    }

    //-------------------------------------------------

    //compile

    public function compile(fullScript:String) {
        if(!exists || compiled) return;

        setCompilerFlag("windows", #if windows true #else false #end);
        setCompilerFlag("mac", #if mac true #else false #end);
        setCompilerFlag("desktop", #if desktop true #else false #end);
        setCompilerFlag("telemetry", #if telemetry true #else false #end);
        setCompilerFlag("linux", #if linux true #else false #end);
        setCompilerFlag("debug", Main.DEBUG);
        setCompilerFlag("discord", #if windows DiscordClient.active #else false #end);

        AddVariables();

        //Parse and compile
		try
        {
            program = parser.parseString(fullScript = preprocessString(fullScript) + fileStandard);
            interpreter.execute(program);

            ready = true;
        }
        catch (e)
        {
            // All exceptions will be caught here
            LogFile.error("Script error! |[ " + e.message + " ]| :" + parser.line+"\n",true);
            if(logScriptOnError) trace("Script:\n"+fullScript);
        }

        

        fullScript = null;
        dynamicImports = null;

        populateFrontend();

        compiled = true;

        awake(); //dangerous as script may still be hot

        parser = null; //i don't think we need the parser at all anymore?
    }

    function populateFrontend() {
        if(compiled) return;
        //populate frontend

        for (variableKey in interpreter.variables.keys()) {
            switch(variableKey){
                case 
                "initializeGlobalString",
                "initializeGlobalInt",
                "initializeGlobalFloat",
                "initializeGlobalBool",
                "getGlobalString",
                "getGlobalInt",
                "getGlobalFloat",
                "getGlobalBool",
                "setGlobalBool",
                "setGlobalFloat",
                "setGlobalInt",
                "setGlobalString",
                
                "trace",
                "getTimers",
                "cast",
                "import",
                "_import": continue; //don't clutter with standard functions
            }

            if(Reflect.isFunction(interpreter.variables.get(variableKey))){
                Reflect.setField(frontend,variableKey,interpreter.variables.get(variableKey));
            }
        }
    }

    var dynamicImports:Array<String> = [];
    function preprocessString(script:String, ?og:Bool = true) {
        var finalString:String = script;
		var lines = script.split("\n");

        var cut = 0;

        var i = 0;
        while (i < lines.length) {
            var line = lines[i].trim();
            final pos = i;
            i++;

            //optimization
            if(cut > 0) {
                cut--;
                if(line.length == 0 || line == "") continue;
                finalString = finalString.replace(lines[pos]+"\n", "");
                continue; 
            }
            if(line.length == 0 || line == "") continue;
			if(line.startsWith("//")) continue;

            //early stop (optimization)
			if(line.startsWith("#FLAG_STOP_PREPROCESS")){
				finalString = finalString.replace(lines[pos]+"\n","");

				break;
			}

            // imports
            if(line.startsWith("#import")){
                var imp:String = line.split(" ")[1].trim();
				

				if (dynamicImports.contains(imp)){
                    finalString = finalString.replace(lines[pos]+"\n","");
                    continue;
                }
					

				dynamicImports.push(imp);

				if (!FileSystem.exists(imp) || !imp.endsWith(".hx")){
                    finalString = finalString.replace(lines[pos]+"\n","");
                    continue;
                }
					
                finalString = finalString.replace(lines[pos],preprocessString(File.getContent(imp).toString(),false));
				continue;
            }

            //defines pieces of code
			if(line.startsWith("#define")){
				var dNd = getDefineAndDefined(line);

                // remove to avoid crash
				finalString = finalString.replace(lines[pos]+"\n", "");

                if(dNd.length != 2) continue;

				var defined:String = dNd[0];
				var define:String = dNd[1];

				//careful with your defines, they replace ALL instances of that string in the code, no matter where
				finalString = finalString.replace(defined, define);
				continue;
			}

            //defines properties
            if(line.startsWith("#property")){

                // remove to avoid crash
				finalString = finalString.replace(lines[pos]+"\n", "");

                if(!og) continue;

                final propertees = line.split(" ");
				var property:String = propertees[1].trim();
				var value:String = propertees[2].trim();

				properties.set(property,value);

				continue;
            }

            //skips the compiler to a set line
            if(line.startsWith("#goto")){

                // remove to avoid crash
				finalString = finalString.replace(lines[pos]+"\n", "");

                final values = line.split(" ");
                var line:Int = Std.parseInt(values[1])-1;

                i = line;
                continue;
            }

            //removes all content from line called to line declared
            if(line.startsWith("#cutto")){

                // remove to avoid crash
				finalString = finalString.replace(lines[pos]+"\n", "");

                final values = line.split(" ");
                var line:Int = Std.parseInt(values[1])-1;

                if(line <= pos) continue;

                cut = (line) - (pos)-1;
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

    //-------------------------------------------------

    //post-compile

    public static function _trace(content:Dynamic) {
        #if debug
            trace(content);
        #else
            LogFile.log(Std.string(content),true,true);
        #end
    }

    public function functionExists(func:String):Bool {
        if (!ready || !exists)
			return false;

        return Reflect.isFunction(interpreter.variables[func]);
    }

    public function getFunction(func:String):Dynamic {
		if (!ready || !exists)
			return null;

        if(!functionExists(func)) return null;
        
        var f = interpreter.variables[func];
		return f;
    }

	public function doFunction(funcName:String, ?args:Array<Dynamic>):Dynamic {
        if (!ready || !exists) return null;
        
		var func = getFunction(funcName);

		if (func != null){
			if(args == null)
				args = [];

			return Reflect.callMethod(this,func,args);
		}
		else{
            switch(funcName){
                case "OnUpdate", "OnLateUpdate", "OnDraw": return null; //don't bother with these functions
                default: LogFile.warning("tried calling non-existing function "+ funcName+" of script!");
            }
		}

		return null;
    }

    public function getScriptVar(name:String):Dynamic {
        if (!ready || !exists)
			return null;

        if(!functionExists("__getVar")) { LogFile.warning("Standard component function __getVar not supported!"); return null; }

        return doFunction("__getVar",[name, interpreter]);
    }

    public function setScriptVar(name:String, to:Dynamic) {
        if (!ready || !exists)
			return null;

        if(!functionExists("__setVar")) { LogFile.warning("Standard component function __setVar not supported!"); return null; }

        return doFunction("__setVar",[name, to, interpreter]);
    }

    public function getScriptVarExists(name:String):Bool {
        if (!ready || !exists)
			return false;

        if(!functionExists("__getVarExists")) { LogFile.warning("Standard component function __getVarExists not supported!"); return false; }

        return doFunction("__getVarExists",[name, interpreter]);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    //timers

    public function getTimers():HscriptTimerManager {
        if(timers == null) timers = new HscriptTimerManager(this);
        return timers;
    }

    public function loadTimers(from:Array<HscriptTimerSave>) {
        if(timers != null) timers.destroy();
        timers = HscriptTimerManager.load(from,this);
    }

    //functions

    public function update(elapsed:Float) {
        if(!exists || !ready) return;
        
        if(timers != null) timers.update(elapsed);

        doFunction("OnUpdate", [elapsed]);
    }

    function awake() {
        if(!exists || !ready) return;

        doFunction("OnAwake");
    }

    //destroy

    public function destroy() {
        if(!exists || !ready) return;

        doFunction("OnDestroy");

        ready = false;
        compiled = false;
        exists = false;

        if(timers != null) timers.destroy();

        interpreter.variables.clear();
        frontend.clear();

        parser = null;
		interpreter = null;
		program = null;
    }

    //import
    
    public var importPerms:Bool = false;

    public function grantImportPerms(to:HaxeScript) {
        if(!importPerms) return;
        to.backend.importPerms = true;
        to.backend.AddGeneral("import", to.backend._import);
        to.backend.AddGeneral("grantImportPerms", to.backend.grantImportPerms); //this file is now allowed to grant import perms
    }

    static final blacklist:Array<String> = []; //add keywords that cannot be imported for whatever reason.

    function _import(what:String, as:String) {
        if(!importPerms) return;
        if(ScriptGlobals.__backendCaller != null && ScriptGlobals.__backendCaller != frontend) return;
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
        if(c == null) {LogFile.error("No class exists with the name "+what+"!",true,true); return;}
        AddGeneral(as,c);
    }

}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

class InterpPlus extends Interp {
    var caller:HaxeScript;

    override public function new(c:HaxeScript) {
        caller = c;
        super();
    }

	override function get( o : Dynamic, f : String ) : Dynamic {
        if ( o == null ) error(EInvalidAccess(f));
		return {
			#if php
				try {
					Reflect.getProperty(o, f);
				} catch (e:Dynamic) {
					Reflect.field(o, f);
				}
			#else
                if(Std.isOfType(o, HaxeScriptBackend)){
                    if(!caller.backend.importPerms)
                    switch (f) { 
                        case "importPerms": 
                            LogFile.warning("Cannot get import perms from script!",false,true); 
                            null;
                        case "parser", "program", "interpreter": 
                            LogFile.warning("Cannot get script parser/interpreter/program from script!",false,true); 
                            null;
                        default: Reflect.getProperty(o, f);
                    }
                    else Reflect.getProperty(o, f);
                }
                else if(isHaxeScript(o)){
                    if(o.backend.getScriptVarExists(f)) o.backend.getScriptVar(f);
                    else Reflect.getProperty(o,f);
                }
                else
				Reflect.getProperty(o, f);
			#end
		}
    }

    override function set( o : Dynamic, f : String, v : Dynamic ) : Dynamic {
        if( o == null ) error(EInvalidAccess(f));
        if(Std.isOfType(o, HaxeScriptBackend))
        {switch (f) { 
            case "importPerms": LogFile.warning("Cannot set import perms from script!",false,true); return null;
            case "parser", "program", "interpreter": LogFile.warning("Cannot set/change script parser/interpreter/program from script!",false,true); return null;
            case "exists", "compiled", "ready": LogFile.warning("Cannot change script state from script!",false,true); return null;
        }}
        else if(isHaxeScript(o)){
            if(f == "backend") return null; //NO, YOU ARE NOT ALLOWED THE FORBIDDEN BACKEND.
            
            if(o.backend.getScriptVarExists(f)) o.backend.setScriptVar(f,v);
            else if(Reflect.hasField(o,f)) Reflect.setProperty(o,f,v);
        }
        else
		Reflect.setProperty(o,f,v);

		return v;
    }

	override function call( o : Dynamic, f : Dynamic, args : Array<Dynamic> ) : Dynamic {
        ScriptGlobals.__backendCaller = caller;
        if(!caller.backend.importPerms) switch(f){
            case //block illegal accesses to the backend class
            "import",
            "_import",
            "grantImportPerms": 
                LogFile.log("cannot use the function "+f+" for security reasons.");
                return null;
        }
    
        final r = Reflect.callMethod(o,f,args);

        ScriptGlobals.__backendCaller = null;

		return r;
	}

    static inline function isHaxeScript(o:Dynamic) {
        return (Reflect.hasField(o,"backend") && Std.isOfType(o.backend, HaxeScriptBackend));
    }
	
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

class ScriptGlobals {
    public static var __backendCaller:HaxeScript = null; //Used for security purposes

    public static function initializeGlobalString(name:String, value:String):Null<String> {
        var s = SaveManager.curSaveData.globals.scriptSaveables.get(name);
        if(s == null){
            SaveManager.curSaveData.globals.scriptSaveables.set(name,value);
        }

        return SaveManager.curSaveData.globals.scriptSaveables.get(name);
    }

    public static function initializeGlobalInt(name:String, value:Int):Null<Int> {
        var i = SaveManager.curSaveData.globals.scriptSaveables.get(name);
        if(i == null){
            SaveManager.curSaveData.globals.scriptSaveables.set(name,value);
        }

        return SaveManager.curSaveData.globals.scriptSaveables.get(name);
    }

    public static function initializeGlobalFloat(name:String, value:Float):Null<Float> {
        var f = SaveManager.curSaveData.globals.scriptSaveables.get(name);
        if(f == null){
            SaveManager.curSaveData.globals.scriptSaveables.set(name,value);
        }

        return SaveManager.curSaveData.globals.scriptSaveables.get(name);
    }

    public static function initializeGlobalBool(name:String, value:Bool):Null<Bool> {
        var b = SaveManager.curSaveData.globals.scriptSaveables.get(name);
        if(b == null){
            SaveManager.curSaveData.globals.scriptSaveables.set(name,value);
        }

        return SaveManager.curSaveData.globals.scriptSaveables.get(name);
    }

    public static function getGlobalString(name:String):Null<String> {
        var s = SaveManager.curSaveData.globals.scriptSaveables.get(name);
        if(s != null){
            if(Std.isOfType(s,String)){
                return s;
            }
        }

        LogFile.error("Global STRING "+name+" Doesn't exist or is not a STRING type!");
        return null;
    }

    public static function getGlobalInt(name:String):Null<Int> {
        var i = SaveManager.curSaveData.globals.scriptSaveables.get(name);
        if(i != null){
            if(Std.isOfType(i,Int)){
                return i;
            }
        }

        LogFile.error("Global INT "+name+" Doesn't exist or is not an INT type!");
        return null;
    }

    public static function getGlobalFloat(name:String):Null<Float> {
        var f = SaveManager.curSaveData.globals.scriptSaveables.get(name);
        if(f != null){
            if(Std.isOfType(f,Float)){
                return f;
            }
        }

        LogFile.error("Global FLOAT "+name+" Doesn't exist or is not a FLOAT type!");
        return null;
    }

    public static function getGlobalBool(name:String):Null<Bool> {
        var b = SaveManager.curSaveData.globals.scriptSaveables.get(name);
        if(b != null){
            if(Std.isOfType(b,Bool)){
                return b;
            }
        }

        LogFile.error("Global BOOL "+name+" Doesn't exist or is not a BOOL type!");
        return null;
    }

    public static function setGlobalBool(name:String,b:Bool):Null<Bool> {
        return SaveManager.curSaveData.globals.scriptSaveables.set(name,b);
    }

    public static function setGlobalFloat(name:String,f:Float):Null<Float> {
        return SaveManager.curSaveData.globals.scriptSaveables.set(name,f);
    }

    public static function setGlobalInt(name:String,i:Int):Null<Int> {
        return SaveManager.curSaveData.globals.scriptSaveables.set(name,i);
    }

    public static function setGlobalString(name:String,s:String):Null<String> {
        return SaveManager.curSaveData.globals.scriptSaveables.set(name,s);
    }


    //-----------------------------------------------------------------------------------------------------------


    public static function Cast<T>(casted:Dynamic):T {
		return cast casted;
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

class HscriptMissingDiscord {
	public static function changePresence(state:Null<String>, details:String,  ?icon:String = 'icon', ?smallImageKey : String = '')
	{
		LogFile.error("Discord is not available for this game version!");
	}

	public static function initialize()
	{
		LogFile.error("Discord is not available for this game version!");
	}

	public static function shutdown()
	{
		LogFile.error("Discord is not available for this game version!");
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//Custom parser features when?