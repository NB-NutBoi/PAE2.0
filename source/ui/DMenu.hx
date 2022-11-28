package ui;

import ui.premades.ItemEditor;
import assets.AssetPaths;
import flixel.util.FlxArrayUtil;
import haxe.Json;
import haxe.iterators.ArrayIterator;
import sys.io.File;
import ui.base.Container;
import ui.premades.DebugMenu;
import utility.LogFile;
import utility.Utils;

using StringTools;

typedef MenuRegister = {
    public var TYPE:String; //ALWAYS "MENU"
    public var script:String;
    public var registerName:String;
    public var altNames:Array<String>;
    public var width:Int;
    public var height:Int;
    public var canOverride:Null<Bool>;
}

typedef MenuOverride = {
    public var TYPE:String; //ALWAYS "OVERRIDE"
    public var script:String;
    public var overrideMenu:String;
}

typedef MenuPlugin = {
    public var TYPE:String; //ALWAYS "PLUGIN"
    public var script:String;
    public var pluginTo:String;
}

class DMenu extends Container {

    public static var menuKeys:Map<String,String> = new Map();
    public static var menus:Map<String,DMenu> = new Map();

    public static function register(folder:String) {
        if(!Main.DEBUG) return;

        trace("setting up DMenus");

        var registerList:Array<MenuRegister> = [];
        var overrideList:Array<MenuOverride> = [];
        var pluginList:Array<MenuPlugin> = [];

        //get the lists.

        var files:Array<String> = AssetPaths.getPathList(folder,null,["json"]);
        trace("DMenu files found:" + files);
		for (file in files) {
			var content = File.getContent(file);
                                        //emergency stop, just in case.
            while (!content.endsWith("}") && content.length > 0)
            {
                content = content.substr(0, content.length - 1);
            }

            var thing:Dynamic = null;
            try{ thing = Json.parse(content); }
            catch(e){
                LogFile.error("Error while parsing DMenu file! |[ " + e.message + " ]| : The file is badly formatted or missing essential data.\n",true);
                continue;
            }

            var type:String = thing.TYPE;
            switch (type){
                case null:
                    LogFile.error("Error while parsing DMenu file! |[ MISSING_VITAL_INFO_TYPE ]| : The file is badly formatted or missing essential data.\n",true);
                    continue;
                case "MENU":
                    var menu:MenuRegister = cast thing;
                    if(menu.registerName == null || menu.script == null || menu.altNames == null) {
                        LogFile.error("Error while parsing DMenu file! |[ MISSING_VITAL_INFO ]| : The file is badly formatted or missing essential data.\n",true);
                        continue;
                    }

                    if(menu.canOverride == null) menu.canOverride = true;

                    registerList.push(menu);
                case "OVERRIDE":
                    var overrider:MenuOverride = cast thing;
                    if(overrider.overrideMenu == null || overrider.script == null) {
                        LogFile.error("Error while parsing DMenu file! |[ MISSING_VITAL_INFO ]| : The file is badly formatted or missing essential data.\n",true);
                        continue;
                    }

                    overrideList.push(overrider);
                case "PLUGIN":
                    var plugin:MenuPlugin = cast thing;

                    if(plugin.pluginTo == null || plugin.script == null) {
                        LogFile.error("Error while parsing DMenu file! |[ MISSING_VITAL_INFO ]| : The file is badly formatted or missing essential data.\n",true);
                        continue;
                    }

                    pluginList.push(plugin);
                default:
                    LogFile.warning("DMenu file type "+type+" does not exist!");
                    continue;
            }
		}

        //lists should be in order from here.

        var registered:Map<String,DMenu> = new Map();

        //REGISTER DEFAULTS!!!

        registered.set("debugmenu", new DebugMenu(0,0));
        menuKeys.set("debugmenu", "debugmenu");
        menuKeys.set("debug", "debugmenu");

        registered.set("itemeditor", new ItemEditor(0,0));
        menuKeys.set("itemeditor", "itemeditor");
        menuKeys.set("item", "itemeditor");

        //register custom.

        for (registerer in registerList) {
            var menu:DMenu = new DMenu(0,0,registerer.width, registerer.height);

            menu.canOverride = registerer.canOverride;
            menu.preMainScript = registerer.script;

            registered.set(registerer.registerName, menu);
            menuKeys.set(registerer.registerName, registerer.registerName);
            for (name in registerer.altNames) {
                menuKeys.set(name, registerer.registerName);
            }
        }

        for (overrider in overrideList) {
            if(!registered.exists(overrider.overrideMenu)) continue;
            if(registered.get(overrider.overrideMenu).canOverride) registered.get(overrider.overrideMenu).preMainScript = overrider.script;
        }

        for (plugin in pluginList) {
            if(!registered.exists(plugin.pluginTo)) continue;
            registered.get(plugin.pluginTo).plugs.push(plugin.script);
        }

        //compile.
        trace("DMenus registered: " + Utils.arrayFromIterator(registered.keys()));

        for (key in registered.keys()) {
            registered.get(key).compile();
            menus.set(key, registered.get(key));
        }
    }

    public var mainScript:Null<DMenuScript>; //premades dont have this, that's what plugins are for
    public var canOverride:Bool = true;

    public var plugins:Array<DMenuScript> = [];

    //pre-compile
    var preMainScript:String;
    var doCompile:Bool = true;
    var plugs:Array<String> = [];

    override public function new(x:Float,y:Float, w:Int, h:Int) {
        super(x,y,w,h);
    }
    
    function compile() {
        if(doCompile){
            mainScript = new DMenuScript(preMainScript, this);
        }

        for (s in plugs) {
            plugins.push(new DMenuScript(s, this));
        }
    }


    override function update(elapsed:Float) {
        if(!visible) return;
        
        super.update(elapsed);

        if(mainScript != null) mainScript.update(elapsed);

        var i = 0;
        while (i < plugins.length) {
            plugins[i].update(elapsed);
            i++;
        }
    }

    override function updateInputs(elapsed:Float) {
        if(!visible) return;
        if(!overlapped) return;
        if(Container.contextActive) return;
        
        super.updateInputs(elapsed);

        if(mainScript != null) mainScript.updateInputs(elapsed);

        var i = 0;
        while (i < plugins.length) {
            plugins[i].updateInputs(elapsed);
            i++;
        }
    }

    override function postUpdate(elapsed:Float) {
        super.postUpdate(elapsed);

        if(mainScript != null) mainScript.postUpdate(elapsed);

        var i = 0;
        while (i < plugins.length) {
            plugins[i].postUpdate(elapsed);
            i++;
        }
    }
}