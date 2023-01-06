package oop;

import common.EventTrack;
import files.HXFile;
import files.HXFile.HaxeScriptBackend;
import common.HscriptTimer;
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
    public var specialOverrideClass:Null<Class<HaxeScriptBackend>>;
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

class Component extends HaxeScriptBackend {

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

    @:isVar public static var precisionSprite(get,null):FlxSprite;
    static function get_precisionSprite() {
        if(precisionSprite == null) precisionSprite = new FlxSprite(0,0,"embed/components/Precision.png");
        return precisionSprite;
    }

    //actual component vars

    var visible:Bool = true;

    public var componentType:String;
    var thisClass:ComponentClass;

    public var owner:Object;

    private var usingSavesPackage:Bool = false;

    public static function instanceComponent(comp:ComponentInstanciator, owner:Object):HaxeScript {
        var instance:ComponentInstance = null;
        if(Std.isOfType(comp, String)) instance = {component: Std.string(comp), startingData: null, extended: true};
        else instance = comp;

        var _class:ComponentClass = componentClasses.get(instance.component);

        var thisClass:Class<HaxeScriptBackend> = Component;
        if(_class.specialOverrideClass != null){
            thisClass = _class.specialOverrideClass;
        }

        var component:Any = null;

        component = makeNew(instance, owner, thisClass, thisClass != Component);

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

    static function makeNew(instance:ComponentInstance, ?_owner:Object, ?managerClass:Class<HaxeScriptBackend> = null, ?isOverride:Bool = false):HaxeScript {
        if(managerClass == null) managerClass = Component;
        var c = HXFile.makeNew(managerClass);
        final cBackend = cast(c.backend, Component);

        cBackend.owner = _owner;

        if(instance == null) return c;

        cBackend.thisClass = componentClasses.get(instance.component);
        if(cBackend.thisClass == null) return c;

        cBackend.componentType = cBackend.thisClass.key;

        currentCompiling = instance;
        if(!isOverride) cBackend.compile(AssetCache.getDataCache(cBackend.thisClass.script));
        currentCompiling = null;
        

        cBackend.create(instance);

        return c;
    }

    public function create(instance:ComponentInstance) {
        
    }

    static var currentCompiling:ComponentInstance;
    override function compile(fullScript:String) {
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

        if(currentCompiling.startingData != null && thisClass.editableVars != null){

            for (eVar in thisClass.editableVars.keys()) {
                var value = null;
                if(Reflect.hasField(currentCompiling.startingData, eVar))
                    value = Reflect.field(currentCompiling.startingData, eVar);
                else if(exsistsArray(eVar, thisClass.defaultVars))
                    value = getArray(eVar, thisClass.defaultVars);
                else continue;

                setScriptVar(eVar, value);
            }
        }

        awake(); //dangerous as script may still be hot

        parser = null; //i don't think we need the parser at all anymore?
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------

    override public function AddVariables() {
        super.AddVariables();

		//BASICS
        AddGeneral("requireComponent", requireComponent);
        AddGeneral("importPackage", importPackage);

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


        //level
        AddGeneral("Level",owner.level);
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

    public function draw() {
        if(!exists || !ready) return;

        doFunction("OnDraw");
    }

    override function destroy() {
        super.destroy();

        thisClass = null;
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
    public function clone(newParent:Object):HaxeScript {

        var component:HaxeScript = instanceComponent(componentType,newParent);

        //is there any more we can do to sync 2 hscript components?
        //there's no way to sync non-global variables since they're protected with some witchcraft dark magic, and syncing global variables would be a pain to sort.

        //remaking the interpreter and parser so we can declare public vars would be the only real option in order to expand on this, but that's way past my grade

        //worry not past mark, for i am the king of shitty workarounds and i have come to deliver
        if(thisClass.editableVars != null){

            for (eVar in thisClass.editableVars.keys()) { //only set vars that were defined in the class json, which is fair.
                final value = getScriptVar(eVar);

                component.backend.setScriptVar(eVar, value);
            }
        }

        return component;
    }

    public function requireComponent(typeof:ComponentInstanciator):HaxeScript {
        if (owner == null) return null;

        var c:Dynamic = owner.getComponentBackend(typeof);

        if(c == null) {
            c = instanceComponent(typeof, owner);
            owner.componets.push(c);
        }
        else c = c.frontend;

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
        "EventTracks" => ["Track" => Track, "WaitNode" => WaitNode, "WaitForNode" => WaitForNode, "FunctionNode" => FunctionNode, "SkipNode" => SkipNode, "GotoNode" => GotoNode, "BiNode" => BiNode],
        "Discord" => ["DiscordRPC" => #if windows DiscordClient #else HscriptMissingDiscord #end ],
    ];

    public function importPackage(pack:String) {
        switch (pack){ //allow for more specialized packs
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