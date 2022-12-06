package;

import ui.elements.Context;
import ui.elements.ColorPicker.ColorWheel;
import gameside.inventory.ItemContainer;
import gameside.dialogue.DialogueState;
import saving.SaveManager;
import JsonDefinitions;
import haxe.DynamicAccess;
import Main.BuildType;
import assets.AssetCache;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import utility.LogFile;
import utility.Utils;
import lime.app.Event;


//use this as the base FlxState class from now on.
class CoreState extends FlxState {

    public static var watermark:FlxText;

    override public function new(?MaxSize:Int) {
        super(MaxSize);

        if(!coreInitialized){
            initCore();
        }
    }

    override function create() {
        super.create();

        var watermark = false;
        var watermarkText = "";
        switch (Main.buildType){
            case INDEV, PRE_RELEASE:
                watermark = true;               //FUCK GRAMMAR
                watermarkText = "This is "+(Main.buildType == INDEV ? "an INDEV" : "a PRE RELEASE")+" build.\nAll content is not representative of final quality and is subject to change.";
            case PRIVATE_BUILD:
                watermark = true;
                watermarkText = "This is a Private Build.\nDo not show any footage or distribute it.";
            case TESTER_BUILD:
                watermark = true;
                watermarkText = "This is a Private testing build.\nAll content is not representative of final quality and is subject to change.   -Do not distribute.";
            case RELEASE:
        }

        //Watermark :D
        if(watermark){
            if(CoreState.watermark != null) CoreState.watermark.destroy();
            CoreState.watermark = new FlxText(5,1030,0,watermarkText,10);
            CoreState.watermark.setFormat("vcr",20,FlxColor.WHITE,LEFT,OUTLINE_FAST,FlxColor.BLACK);
            CoreState.watermark.alpha = 0.2;
            CoreState.watermark.scrollFactor.set();
            CoreState.watermark.antialiasing = true;
            CoreState.watermark.borderSize = 4;
            CoreState.watermark.cameras = [FlxGamePlus.OverlayCam];
        }

        if(!coreStarted){
            startCore();
        }
    }

    override function draw() {
        super.draw();
        if(watermark != null && watermark.visible) watermark.draw();
        if(ColorWheel.instance != null) ColorWheel.instance.draw(); //color wheel :D
        if(Context.instance != null) Context.instance.draw();
    }
    
    override function tryUpdate(elapsed:Float) {
        
        if(_frame) //make sure this is only updated once per frame (why would there be multiple coreState instances running anyway)
            updateCore(elapsed);

        if(!Main.Paused){
            if (persistentUpdate || subState == null)
                update(elapsed);
        }
        
		if (_requestSubStateReset)
		{
			_requestSubStateReset = false;
			resetSubState();
		}
		if (subState != null)
		{
            if(!Main.Paused)
			    subState.tryUpdate(elapsed);
		}

        if(_lateFrame)
            lateUpdateCore(elapsed);
    }

    //-------------------------------------------------------------------------------
    //Core

    public static var _frame:Bool = true;
    public static var _lateFrame:Bool = true;

    public static var coreInitialized:Bool = false;
    public static var coreStarted:Bool = false;

    public static var mainScript:CorePlugin;
    public static var plugins:Map<String,CorePlugin>;

    public static var tryUpdatePlugin:String->Bool;

    public static function initCore() {
        coreInitialized = true;

        tryUpdatePlugin = defaultUpdatePlugin;

        plugins = new Map();

        final mainScriptPath = Main.SetupConfig.getConfig("MainScript","String","");
        if(Utils.checkExternalHaxeFileValid(mainScriptPath)){
            AssetCache.cacheData(mainScriptPath);
            mainScript = new CorePlugin(mainScriptPath, "MainScript"); //careful using OnAwake, it's not safe to do everything yet, save most important stuff to OnStart
        }

        if(mainScript == null){
            LogFile.fatalError("!!! MAIN SCRIPT \""+mainScriptPath+"\" COULD NOT BE INITIATED !!!", 10);
            return;
        } 
        
        mainScript.AddGeneral("plugins",plugins);
        mainScript.AddGeneral("loadPlugin",loadPlugin);
    }

    public static function startCore() {
        coreStarted = true;
    
        mainScript.start(); //should init plugins here
        for (plugin in plugins) {
            plugin.start();
        }
    }

    public static function updateCore(elapsed:Float) {
        _frame = false;
        

        mainScript.update(elapsed);
        for (plugin in plugins) {
            if(tryUpdatePlugin(plugin.name)) plugin.update(elapsed);
        }
    }

    public static function lateUpdateCore(elapsed:Float) {
        _lateFrame = false;


        mainScript.lateUpdate(elapsed);
        for (plugin in plugins) {
            if(tryUpdatePlugin(plugin.name)) plugin.lateUpdate(elapsed);
        }
    }

    static function defaultUpdatePlugin(plugin:String):Bool {
        return true;
    }

    static function loadPlugin(path:String, name:String) {
        final plugin = new CorePlugin(path,name);
        plugins.set(name,plugin);
    }

    //------------------------------------------------------------------------------------------------------------------------------

    public static final onSave:Event<String->Void> = new Event<String->Void>();
    public static final onLoad:Event<String->Void> = new Event<String->Void>();

    public static function Save(where:String) {
        mainScript.save();
        onSave.dispatch(where);
    }

    public static function Load(what:String) {
        mainScript.load();
        onLoad.dispatch(what);
    }

}

typedef GlobalSaveables = {
    public var scriptSaveables:DynamicAccess<ScriptVariable>;

    public var containers:DynamicAccess<ItemContainerCache>;
    public var dialogues:DynamicAccess<DialogueCache>;
}