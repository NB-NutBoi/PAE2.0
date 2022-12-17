package oop;

import common.HscriptTimer;
import common.BasicHscript.HScriptable;
import saving.SaveManager;
import Discord.DiscordClient;
import utility.Language.LanguageManager;
import rendering.Skybox;
import rendering.Text;
import rendering.Sprite;
import flixel.FlxSprite;
import oop.premades.SaveDataComponent;
import haxe.ds.ObjectMap;
import haxe.ds.IntMap;
import assets.AssetCache;
import assets.AssetPaths;
import common.ClientPreferences;
import common.Keyboard;
import common.Mouse;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.util.typeLimit.OneOfTwo;
import haxe.DynamicAccess;
import haxe.Json;
import haxe.ds.StringMap;
import hscript.Expr;
import hscript.Interp;
import hscript.Parser;
import lime.ui.KeyCode;
import oop.ComponentPackages;
import oop.premades.AudioListenerComponent;
import oop.premades.AudioSourceComponent;
import oop.premades.SpriteComponent;
import oop.premades.TextComponent;
import sys.io.File;
import utility.LogFile;
import utility.Utils;

using StringTools;

typedef ComponentClass = {
    public var name:Null<String>; //optional
    public var key:String;
    public var icon:Null<String>; //optional
    public var editableVars:Null<DynamicAccess<String>>;
    public var defaultVars:Null<Array<Array<Dynamic>>>;
    public var specialOverrideClass:Null<Class<Component>>;
    public var specialOverrideArgs:Null<Array<Dynamic>>;
    public var script:String; // path because editing this in-json would be a pain in the ass.
    public var static_vars:Null<DynamicAccess<Dynamic>>;
}

typedef ComponentInstance = {
    public var extended:Bool; //editor data
    public var component:String; //key of the component class
    public var startingData:Null<Dynamic>; //make sure it's an anonymous structure.
}
typedef ComponentInstanciator = OneOfTwo<String, ComponentInstance>;

typedef ComponentTimers = {
    public var usesTimers:Bool;
    public var timers:Array<HscriptTimerSave>;
}

class Component extends FlxBasic implements HScriptable {

    //REMEMBER TO REGISTER CLASSES!
    public static var componentClasses(default,never):Map<String,ComponentClass> = new Map();
    //------------------------------------------------------------------------------------------
    //for optimization purposes, i'll let levels define specific classes so long as they're only used in the level.
    public static var levelSpecificClasses:Array<String> = [];
    public static function resetLevelClasses() {
        //remove level-specific shit
        for (s in levelSpecificClasses) {
            componentClasses.set(s,null);
            componentClasses.remove(s);
        }
    }
    //------------------------------------------------------------------------------------------

    //low level stuff
    public static var currentBuildingBackend:Component = null;

    public static var componentStandard:String = ""; //gets added to the end of every component code.

    @:isVar public static var precisionSprite(get,null):FlxSprite;
    static function get_precisionSprite() {
        if(precisionSprite == null) precisionSprite = new FlxSprite(0,0,"embed/components/Precision.png");
        return precisionSprite;
    }

    //actual component vars

    public var ready:Bool;
    public var componentType:String;
    var thisClass:ComponentClass;

    public var parser:Parser;
	public var program:Expr;
	public var interpreter:Interp;

    public var timers:HscriptTimerManager;

    public var componentFrontend:Dynamic;
    public var owner:Object;

    public var compiling:Bool = false;
    private var usingSavesPackage:Bool = false;

    //private var getsetFrontend(get,set):Dynamic;

    //not ideal, but kept for convenience reasons.
    public static function makeComponentOfType(typeof:String, owner:Object):Component {
        var _class:ComponentClass = componentClasses.get(typeof);

        var thisClass:Class<Component> = Component;
        if(_class.specialOverrideClass != null){
            thisClass = _class.specialOverrideClass;
        }

        var component:Any = null;

        var instance:ComponentInstance = {
            extended: true,
            component: typeof,
            startingData: {}
        }

        for (array in _class.defaultVars) {
            Reflect.setField(instance,array[0],array[1]);
        }

        if(_class.specialOverrideArgs != null){
            var args = _class.specialOverrideArgs.copy();
            args.push(instance);
            args.push(owner); //!!!MAKE SURE OWNER IS ALWAYS THE LAST ARGUMENT!!!
            component = Type.createInstance(thisClass, args);
            args = null;
        }
        else{
            var args:Array<Dynamic> = [instance, owner];
            component = Type.createInstance(thisClass, args);
            args = null;
        }

        return component;
    }

    public static function instanceComponent(instance:ComponentInstance, owner:Object):Component {
        var _class:ComponentClass = componentClasses.get(instance.component);

        var thisClass:Class<Component> = Component;
        if(_class.specialOverrideClass != null){
            thisClass = _class.specialOverrideClass;
        }

        var component:Any = null;

        if(_class.specialOverrideArgs != null){
            var args = _class.specialOverrideArgs.copy();
            args.push(instance);
            args.push(owner); //!!!MAKE SURE OWNER IS ALWAYS THE LAST ARGUMENT!!!
            component = Type.createInstance(thisClass, args);
            args = null;
        }
        else{
            var args:Array<Dynamic> = [instance, owner];
            component = Type.createInstance(thisClass, args);
            args = null;
        }

        return component;
    }

    public static function getArray(key:String, array:Array<Array<Dynamic>>):Dynamic {
        var value:Dynamic = null;
        var i = 0;
        while (i < array.length) {
            if(key == array[i][0]) { value = array[i][1]; break; }
            i++;
        }

        return value;
    }

    public static function exsistsArray(key:String, array:Array<Array<Dynamic>>):Bool {
        var exists = false;
        var i = 0;
        while (i < array.length) {
            if(key == array[i][0]) { exists = true; break; }
            i++;
        }

        return exists;
    }

    public static function setArray(key:String, value:Dynamic, array:Array<Array<Dynamic>>) {
        var i = 0;
        while (i < array.length) {
            if(key == array[i][0]) { array[i][1] = value; break; }
            i++;
        }
    }

    override public function new(comp:ComponentInstanciator, ?_owner:Object) {
        super();

        owner = _owner;

        if(comp == null) return;

        var instance:ComponentInstance = null;
        if(Std.isOfType(comp, String)) instance = {component: Std.string(comp), startingData: null, extended: true};
        else instance = comp;

        if(instance == null) return;

        componentType = instance.component;

        thisClass = componentClasses.get(instance.component);
        if(thisClass == null) return;

        ready = false;
        
		parser = new hscript.Parser();
		parser.allowTypes = true;
        
        //set preprocesorValues
        parser.preprocesorValues.set("windows", #if windows true #else false #end);
        parser.preprocesorValues.set("mac", #if mac true #else false #end);
        parser.preprocesorValues.set("desktop", #if desktop true #else false #end);
        parser.preprocesorValues.set("telemetry", #if telemetry true #else false #end);
        parser.preprocesorValues.set("linux", #if linux true #else false #end);
        parser.preprocesorValues.set("debug", Main.DEBUG);
        parser.preprocesorValues.set("discord", #if windows DiscordClient.active #else false #end);

		interpreter = new hscript.Interp();

        AddVariables();
        compile(AssetCache.getDataCache(thisClass.script));

        if(!ready) return;
        

        if(instance.startingData != null && thisClass.editableVars != null){

            for (eVar in thisClass.editableVars.keys()) {
                var value = null;
                if(Reflect.hasField(instance.startingData, eVar))
                    value = Reflect.field(instance.startingData, eVar);
                else if(exsistsArray(eVar, thisClass.defaultVars))
                    value = getArray(eVar, thisClass.defaultVars);
                else continue;

                setScriptVar(eVar, value);
            }
        }

        generateFrontend();

        awake();

        parser = null; //i don't think we need the parser at all anymore?
    }

    


    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------

    public function AddVariables() {
		//BASICS
        AddGeneral("trace", _trace);
        AddGeneral("traceLocals", _traceLocals);

        AddGeneral("requireComponent", requireComponent);
        AddGeneral("requireComponentInstance", requireComponentInstance);
        AddGeneral("importPackage", importPackage);

        AddGeneral("camera", camera);
        AddGeneral("cameras", cameras);

        AddGeneral("globals", ComponentGlobals);
        AddGeneral("setStaticVar", setStaticVar);
        AddGeneral("getStaticVar", getStaticVar);

        AddGeneral("getTimers", getTimers);

        //owner
        AddGeneral("transform", owner.transform);
        AddGeneral("getComponent", owner.getComponent);
        AddGeneral("hasComponent", owner.hasComponent);

        //children
        AddGeneral("getNumberOfChildren", owner.getNumberOfChildren);
        AddGeneral("getChildAt", owner.getChildAt); //i know this one's dangerous cause it returns the object backend but what the hell, who's gonna notice?

        //object fundamentals
        AddGeneral("Destroy", owner.Destroy);
        AddGeneral("Instantiate", owner.Instantiate);

        //script workaround
        AddGeneral("__this",this);


        //level
        AddGeneral("Level",owner.level);

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

    @:access(hscript.Interp)
    private function _traceLocals() {
        trace(interpreter.locals);
        trace(interpreter.declared);
        trace(interpreter.variables);
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------

    //timers

    public function getTimers():HscriptTimerManager {
        if(timers == null) timers = new HscriptTimerManager(this);
        return timers;
    }

    public function loadTimers(from:Array<HscriptTimerSave>) {
        if(timers != null) timers.destroy();
        timers = HscriptTimerManager.load(from,this);
    }

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

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------

    public function getScriptVar(name:String):Dynamic {
        if (!ready || !exists)
			return null;

        if(!functionExists("__getComponentValue")) { LogFile.warning("Standard component function __getComponentValue not supported!"); return null; }

        return doFunction("__getComponentValue",[name]);
    }

    public function setScriptVar(name:String, to:Dynamic) {
        if (!ready || !exists)
			return;

        if(!functionExists("__setComponentValue")) { LogFile.warning("Standard component function __setComponentValue not supported!"); return; }

        doFunction("__setComponentValue",[name, to]);
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------

    public function functionExists(func:String):Bool {
        if (!ready || !exists)
			return false;

        if(!interpreter.variables.exists(func)) return false;

        if(!Reflect.isFunction(interpreter.variables[func])) return false;

        return true;
    }

    public function getFunction(func:String):Dynamic {
		if (!ready || !exists)
			return null;

		if(Reflect.isFunction(interpreter.variables[func]))
			return interpreter.variables[func];

		return null;
    }

	public function doFunction(func:String, ?args:Array<Dynamic>):Dynamic {
        if (!ready || !exists) return null;
        
		var Function = getFunction(func);

		if (Function != null){
			if(args == null)
				args = [];

			
			var r = Reflect.callMethod(this,Function,args);
			Function = null;
			return r;
		}
		else{
            //make sure the console isn't getting flooded because timmy forgot to add the OnUpdate function to his code, all of these are potentially unneeded.
            if(!Utils.matchesAny(func, Main.defaultFunctions))
                Console.logWarning("tried calling non-existing function "+ func+" of component "+componentType+" on object "+owner.name+"!");
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
            program = parser.parseString(fullScript+componentStandard);
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

    

    @:access(hscript.Interp)
    private function generateFrontend() {
        if(!ready || !exists) return;

        currentBuildingBackend = this;

        //might improve this if i figure out how to make properties from thin air
        //update to the above, it's impossible. properites are too fancy and compile-sided.
        componentFrontend = {};

        for (variableKey in interpreter.variables.keys()) {
            if(Reflect.isFunction(interpreter.variables.get(variableKey))){  //variables are a bitch to sync up to an anonymous structure so only functions i guess
                // better than nothing
                Reflect.setField(componentFrontend,variableKey,interpreter.variables.get(variableKey));
            }
        }

        componentFrontend.camera = camera;
        componentFrontend.cameras = cameras;

        currentBuildingBackend = null;
    }

    override function set_camera(value:FlxCamera):FlxCamera {
        componentFrontend.camera = value;
        componentFrontend.cameras = [value];

        AddGeneral("camera", value);
        AddGeneral("cameras", [value]);

        return super.set_camera(value);
    }

    override function set_cameras(value:Array<FlxCamera>):Array<FlxCamera> {
        componentFrontend.camera = value[0];
        componentFrontend.cameras = value;

        AddGeneral("camera", value[0]);
        AddGeneral("cameras", value);

        return super.set_cameras(value);
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------

    private function awake() {
        if(!exists || !ready) return;

        doFunction("OnAwake");
    }

    public function start() {
        if(!exists || !ready) return;

        if(owner.hasComponent("SaveData")){
            final sd:SaveDataComponent = cast owner.getComponentBackend("SaveData");

            var timers:ComponentTimers = {
                usesTimers: false,
                timers: null
            }

            if(sd.existsVarUnsafe("timers")){
                var t = sd.getVarUnsafe("timers");

                if(t.usesTimers != null) timers = cast t;
                if(timers.usesTimers && timers.timers != null) loadTimers(timers.timers);
            }
        }

        doFunction("OnStart");
    }

    override function update(elapsed:Float) {
        if(!exists || !ready) return;
        super.update(elapsed);

        if(timers != null) timers.update(elapsed);

        //do update idk
        doFunction("OnUpdate", [elapsed]);
    }

    public function lateUpdate(elapsed:Float) {
        if(!exists || !ready) return;

        doFunction("OnLateUpdate", [elapsed]);
    }

    override function draw() {
        if(!exists || !ready) return;
        super.draw();

        //do draw
        doFunction("OnDraw");
    }

    override function destroy() {
        if(!exists) return;

        doFunction("OnDestroy");

        ready = false;

        thisClass = null;

        interpreter.variables.clear();

        componentFrontend = null;
        parser = null;
		interpreter = null;
		program = null;

        super.destroy();
    }
    
    public function save() {
        if(!exists || !ready || !usingSavesPackage) return;

        if(owner.hasComponent("SaveData")){
            final sd:SaveDataComponent = cast owner.getComponentBackend("SaveData");
            var timers:ComponentTimers = {
                usesTimers: (timers != null),
                timers: (timers != null) ? timers.saveTimers() : null
            }

            sd.saveVarUnsafe("timers",timers);
        }

        doFunction("OnSave");
    }

    public function load() {
        if(!exists || !ready || !usingSavesPackage) return;

        doFunction("OnLoad");
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------

    //can be overriden if there needs to be builtin components (probably for performance reasons, don't want everything to be handled through hscript)
    public function clone(newParent:Object):Component {

        var component:Component = new Component(componentType,newParent);

        //is there any more we can do to sync 2 hscript components?
        //there's no way to sync non-global variables since they're protected with some witchcraft dark magic, and syncing global variables would be a pain to sort.

        //remaking the interpreter and parser so we can declare public vars would be the only real option in order to expand on this, but that's way past my grade

        //worry not past mark, for i am the king of shitty workarounds and i have come to deliver
        if(thisClass.editableVars != null){

            for (eVar in thisClass.editableVars.keys()) { //only set vars that were defined in the class json, which is fair.
                final value = getScriptVar(eVar);

                component.setScriptVar(eVar, value);
            }
        }

        return component;
    }

    public function requireComponent(typeof:String):Dynamic {
        if (owner == null) return null;

        var c:Dynamic = owner.getComponentBackend(typeof);

        if(c == null) {
            c = makeComponentOfType(typeof, owner);
            owner.componets.add(c);
        }

        c = c.componentFrontend;

        return c;
    }

    public function requireComponentInstance(instance:ComponentInstance) {
        if (owner == null) return null;
        
        var c:Dynamic = owner.getComponentBackend(instance.component);

        if(c == null) {
            c = instanceComponent(instance, owner);
            owner.componets.add(c);
        }

        c = c.componentFrontend;

        return c;
    }

    public function setStaticVar(name:String, value:Dynamic):Dynamic {
        if(!exists || !ready) return null;
        if(thisClass.static_vars == null) thisClass.static_vars = new DynamicAccess();

        thisClass.static_vars.set(name, value);

        return value;
    }

    public function getStaticVar(name:String):Dynamic {
        if(!exists || !ready || thisClass.static_vars == null) return null;

        return thisClass.static_vars.get(name);
    }


    //define packages of stuff to import here, if you need something more specialized, add it to the switch function.
    public static final packages:Map<String, Map<String, Dynamic>> = [
        "Input" => ["Keyboard" => Keyboard, "KeyCode" => InputPackageKeyCode, "Mouse" => Mouse],
        "ClientPrefs" => ["ClientPreferences" => ClientPreferences],
        "Maps" => ["StringMap" => StringMap, "IntMap" => IntMap, "ObjectMap" => ObjectMap],
        "Rendering" => ["Sprite" => Sprite, "Text" => Text, "Skybox" => Skybox],
        "Language" => ["LanguageManager" => LanguageManager],
        "Discord" => ["DiscordRPC" => #if windows DiscordClient #else HscriptMissingDiscord #end ],
    ];

    public function importPackage(pack:String) {
        switch (pack){ //allow for more specialized packs
            case "LowLevel":
                AddGeneral("importClassByName", importClassByName);
            case "Saves":
                usingSavesPackage = true;
            case "Main":
                AddGeneral("MainScript", CoreState.mainScript);
            default:
                if(!packages.exists(pack)) { LogFile.error("No Package exists with the name "+pack+" for import."); return;}

                var pack = packages.get(pack);
                for (key in pack.keys()) {
                    AddGeneral(key, pack.get(key));
                }
        }
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------

    //low level package

    public function importClassByName(name:String) {
        var c = Type.resolveClass(name);
        if(c == null) {LogFile.error("No class exists with the name "+name+"!"); return;}
        AddGeneral(name, c);
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------

    public static function registerStandardComponents() {

        final spriteEditables = new DynamicAccess();
        spriteEditables.set("texture", "filepath");
        spriteEditables.set("flipX", "bool");
        spriteEditables.set("flipY", "bool");
        spriteEditables.set("tint", "color");
        spriteEditables.set("offsetX", "float");
        spriteEditables.set("offsetY", "float");
        spriteEditables.set("width", "int");
        spriteEditables.set("height", "int");

        final spriteDefaults:Array<Array<Dynamic>> = [
            ["texture", "assets/images/Testbox1.asset"],
            ["flipX", false],
            ["flipY", false],
            ["tint", 0xFFFFFFFF],
            ["offsetX", 0],
            ["offsetY", 0],
            ["width", 128],
            ["height", 128]
        ];

        componentClasses.set("Sprite", {
            name: "Sprite",
            key: "Sprite",
            icon: "embed/components/Sprite.png",
            script: "",
            editableVars: spriteEditables,
            defaultVars: spriteDefaults,
            specialOverrideClass: SpriteComponent,
            specialOverrideArgs: [],
            static_vars: null
        });

        final textEditables = new DynamicAccess();
        textEditables.set("text", "string");
        textEditables.set("font", "filepath");
        textEditables.set("color", "color");
        textEditables.set("size", "int");
        textEditables.set("offsetX", "float");
        textEditables.set("offsetY", "float");

        final textDefaults:Array<Array<Dynamic>> = [
            ["text", "lorem ipsum"],
            ["color", 0xFFFFFFFF],
            ["font", "vcr"],
            ["size", 16],
            ["offsetX", 0],
            ["offsetY", 0]
        ];

        componentClasses.set("Text", {
            name: "Text",
            key: "Text",
            icon: "embed/components/Text.png",
            script: "",
            editableVars: textEditables,
            defaultVars: textDefaults,
            specialOverrideClass: TextComponent,
            specialOverrideArgs: [],
            static_vars: null
        });

        final aListenerEditables = new DynamicAccess();
        aListenerEditables.set("volume", "float");

        final aListenerDefaults:Array<Array<Dynamic>> = [
            ["volume", 1]
        ];

        componentClasses.set("AudioListener", {
            name: "AudioListener",
            key: "AudioListener",
            icon: "embed/components/AudioListener.png",
            script: "",
            editableVars: aListenerEditables,
            defaultVars: aListenerDefaults,
            specialOverrideClass: AudioListenerComponent,
            specialOverrideArgs: [],
            static_vars: null
        });

        final aSourceEditables = new DynamicAccess();
        aSourceEditables.set("clip", "filepath");
        aSourceEditables.set("panning", "range(-1,1,0,true)");

        aSourceEditables.set("usingProximity", "bool");
        aSourceEditables.set("usingProximityPanning", "bool");
        aSourceEditables.set("radius", "float");

        aSourceEditables.set("offsetX", "float");
        aSourceEditables.set("offsetY", "float");

        aSourceEditables.set("important", "bool"); //only used if clip is set by default. (might need CSD file support for this after all)

        final aSourceDefaults:Array<Array<Dynamic>> = [
            ["clip", ""],
            ["panning", 0],
            ["usingProximity", false],
            ["usingProximityPanning", false],
            ["radius", 100],
            ["offsetX", 0],
            ["offsetY", 0],
            ["important", false],
        ];

        componentClasses.set("AudioSource", {
            name: "AudioSource",
            key: "AudioSource",
            icon: "embed/components/AudioSource.png",
            script: "",
            editableVars: aSourceEditables,
            defaultVars: aSourceDefaults,
            specialOverrideClass: AudioSourceComponent,
            specialOverrideArgs: [],
            static_vars: null
        });

        
        final saveDataEditables = new DynamicAccess();
        saveDataEditables.set("uniqueKey", "string");

        final saveDataDefaults = [
            ["uniqueKey", "default"]
        ];

        componentClasses.set("SaveData", {
            name: "SaveData",
            key: "SaveData",
            icon: "embed/components/SaveData.png",
            script: "",
            editableVars: saveDataEditables,
            defaultVars: saveDataDefaults,
            specialOverrideClass: SaveDataComponent,
            specialOverrideArgs: [],
            static_vars: null
        });

    }

    public static function registerComponents(folder:String) {
        for (filePath in AssetPaths.getPathList(folder,null,["comp"])) {
            var file = File.getContent(filePath);

            while (!file.endsWith("}"))
            {
                file = file.substr(0, file.length - 1);
            }

            var componentClass:ComponentClass = null;

            try{
                componentClass = cast Json.parse(file);
            }
            catch(e){
                LogFile.error("Component file error! |[ " + e.message + " ]| : The file is badly formatted or missing essential data.\n",true);
                continue;
            }

            if(componentClasses.exists(componentClass.key)){
                LogFile.error("A class already exists with the key "+componentClass.key+". adding as clone.",true);
                while(componentClasses.exists(componentClass.key)){
                    componentClass.key += "_clone";
                }
            }

            LogFile.log("Registered component class "+componentClass.key+".");
            componentClasses.set(componentClass.key, componentClass);
        }
    }
}

class ComponentGlobals {
    public static var audioListenerExists(get,never):Bool;
	static function get_audioListenerExists():Bool {
		return (AudioListenerComponent.listener != null);
	}
}