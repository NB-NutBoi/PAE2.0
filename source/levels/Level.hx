package levels;

import common.HscriptTimer.HscriptTimerSave;
import oop.StaticObject;
import oop.GenericObject;
import gameside.dialogue.DialogueState;
import gameside.inventory.ItemContainer;
import oop.Rail;
import openfl.Assets;
import pgr.dconsole.DC;
import flixel.util.FlxDestroyUtil;
import assets.ImageAsset;
import saving.SaveManager;
import JsonDefinitions;
import assets.AssetCache;
import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;
import flixel.util.typeLimit.OneOfFour;
import haxe.DynamicAccess;
import haxe.Json;
import haxe.io.Path;
import levels.Layer;
import oop.Object;
import openfl.system.System;
import rendering.Skybox;
import sys.FileSystem;
import sys.io.File;
import utility.LogFile;
import utility.Utils;

using StringTools;

//------------------------------------------------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------------------------------------------------

typedef LevelFile = {
    //editor-only
    public var levelName:String;
    public var curLayer:Int;
    public var gridSize:Float;
    public var snapping:Bool;

    //precache data
    public var bitmaps:Array<String>;

    //actual level data
    public var layers:Array<LayerStructure>;
    public var skybox:String;
    public var skyboxVisible:Bool; //level editor only.
    public var script:String;
    public var backgroundColor:Null<JSONColor>;
}

typedef LayerStructure = {
    public var enabledByDefault:Bool;
    public var visible:Bool; //level editor only.
    public var objects:Array<Dynamic>;
    public var rails:Array<RailStructure>;
}

typedef RailStructure = {
    public var name:String;
    public var startNode:RailNodeStructure;
}

typedef RailNodeStructure = {
    public var x:Float;
    public var y:Float;

    public var speedMul:Float;

    public var nextNode:Null<RailNodeStructure>;
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------------------------------------------------

typedef LevelSaveables = {
    public var firstTime:Bool; //used live, no need to load
    public var scriptSaveables:DynamicAccess<ScriptVariable>; //used live, no need to load
    public var saveDataComponents:DynamicAccess<DynamicAccess<Dynamic>>; //used live, no need to load

    public var containers:DynamicAccess<ItemContainerCache>;
    public var dialogues:DynamicAccess<DialogueCache>;

    public var timers:Array<HscriptTimerSave>;
}

typedef Callback = {
    public var name:String;
    public var func:String;
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------------------------------------------------

class Level {
    
    public var bitmaps:Array<String> = [];

    public var path:String = "";

    public var curSkybox:Skybox = null;
    public var layers:FlxTypedGroup<Layer> = new FlxTypedGroup();
    
    public var saveables:LevelSaveables = null;

    public var collisionLayer:Int = 0;

    //-------------------------------------------------------------------------------------------------------------

    //Level script
    public var script:LevelScript;

    public var levelSpecificImports:Map<String,Array<{value:Dynamic, name:String}>> = new Map();

    //-------------------------------------------------------------------------------------------------------------

    public function new() {
        
    }

    public function loadLevel(path:String, ?load:Bool = false) {
        if(((!FileSystem.exists(path) || FileSystem.isDirectory(path)) && !path.startsWith("embed")) || Path.extension(path) != "map"){
            trace("error loading map");
            LogFile.error({ message: "Error loading map: path " + path + " is does not exist or is not a valid map file.\n", caller: "Level", id: 30});
            return;
        }
        else if(path.startsWith("embed")){
            trace("LOADING EMBEDDED MAP.");
            if(!Assets.exists(path)) { LogFile.error({ message: "Error loading embedded map " + path + ".\n", caller: "Level", id: 30}); return; }
        }

        #if !debug
        try
        {
        #end

            if(this.path != path) AssetCache.removeDataCache(this.path); //no need to keep old level's cache.


            if(script != null)
            {
                if(script.ready) script.onLeave();

                script.destroy();
            }

            script = null;

            if(saveables != null && !load){
                SaveManager.curSaveData.mapSaveables.set(this.path,saveables);
            }            

            //--------------------------------------------------------------------------------------------------------------------------------

            this.path = path;
            SaveManager.curSaveData.currentMap = path;
            final levelFile:LevelFile = cast Json.parse(AssetCache.getDataCache(path));

            if(SaveManager.curSaveData.mapSaveables.get(path) != null){
                saveables = SaveManager.curSaveData.mapSaveables.get(path);
            }
            else{
                saveables = {
                    firstTime: true,
                    scriptSaveables: new DynamicAccess(),
                    saveDataComponents: new DynamicAccess(),

                    dialogues: new DynamicAccess(),
                    containers: new DynamicAccess(),

                    timers: null
                }
            }

            LogFile.log({ message: "Loading map: " + path + "\n", caller: "Level", id: 31});

            //--------------------------------------------------------------------------------------------------------------------------------

            var nonRepeating:Array<String> = [];

            for (s in bitmaps) {
                if(!levelFile.bitmaps.contains(s)){
                    nonRepeating.push(s);
                }
            }

            for (s in nonRepeating) {
                AssetCache.removeImageCache(s);
            }

            for (s in levelFile.bitmaps) {
                AssetCache.cacheImage(s);
            }

            bitmaps.resize(0);
            nonRepeating.resize(0);
            nonRepeating = null;

            bitmaps = levelFile.bitmaps;
            //layers = levelFile.layers;

            StaticObject.setAssets(bitmaps);

            if(levelFile.backgroundColor != null && this == MainState.instance.level) //only "main" level can modify camera bg color.
                FlxG.camera.bgColor = FlxColor.fromRGB(levelFile.backgroundColor.R,levelFile.backgroundColor.G,levelFile.backgroundColor.B,levelFile.backgroundColor.A);

            //-------------------------------------------------------------------------------------------------------------

            //clear objects
            /* someday we'll get physics back :(

            FlxNapeSpace.space.listeners.clear();
            FlxNapeSpace.space.constraints.clear();
            FlxNapeSpace.space.clear();
            */

            layers.forEach(FlxDestroyUtil.destroy);
            layers.destroy();
            layers = null;

            if(curSkybox != null) curSkybox.destroy();
            curSkybox = null;

            System.gc();

            //-------------------------------------------------------------------------------------------------------------

            layers = new FlxTypedGroup();

            //make the new objects
            for (layer in levelFile.layers) {
                layers.add(Layer.load(layer,this));
            }

            if(levelFile.skybox != "" && levelFile.skybox != null){
                curSkybox = new Skybox(0,0,ImageAsset.get(levelFile.skybox));
            }

            //--------------------------------------------------------------------------------------------------------------------------------

            if(saveables != null){
                //load saveables stuff that isn't live usage here.
            }

            if(load) for (layer in layers) {
                for (basic in layer) {
                    if(Std.isOfType(basic, GenericObject)) cast(basic, GenericObject).load();
                }
            }

            //--------------------------------------------------------------------------------------------------------------------------------

            

            var doScript:Bool = true;
            //script can be null
            if(levelFile.script != null){
                doScript = Utils.checkExternalHaxeFileValid(levelFile.script);

                if(doScript){
                    LogFile.log({ message: "Loading Script "+levelFile.script+".\n", caller: "Level", id: 32},false);
                    
                    script = new LevelScript(this,levelFile.script);
                    if(saveables.timers != null) script.loadTimers(saveables.timers);
                    
                    if(saveables.firstTime){
                        saveables.firstTime = false;
                        script.start();
                    }

                    if(load) script.load();
                    else script.onEnter();
                }
            }
            else{
                doScript = false;
            }

            if(!doScript)
                LogFile.warning({ message: "Level Script '"+levelFile.script+"' could not be loaded.\n", caller: "Level", id: 34});

            //--------------------------------------------------------------------------------------------------------------------------------

            LogFile.log({ message: "Finished loading map.\n\n", caller: "Level", id: 38});

            //--------------------------------------------------------------------------------------------------------------------------------
        #if !debug
        }
        catch (e)
        {
            LogFile.error("Error thrown when loading map! |[ " + e.message + " ]|\n",true);
        }
        #end
    }

    //-------------------------------------------------------------------------------------------------------------
    //----------------------------------------------------DEFAULT--------------------------------------------------
    //-------------------------------------------------------------------------------------------------------------

    public function draw() {
        Console.beginProfile("drawLevel");

        if(curSkybox != null) Utils.drawSkybox(curSkybox);
        layers.draw();

        if(script != null){
            script.draw();
        }

        Console.endProfile("drawLevel");
    }

    public function update(elapsed:Float) {
        Console.beginProfile("updateLevel");

        if(curSkybox != null) curSkybox.update(elapsed);
        layers.update(elapsed);
        for (layer in layers) {
            layer.lateUpdate(elapsed);
        }

        if(script != null){
            script.update(elapsed);
        }

        Console.endProfile("updateLevel");
    }

    public function destroy() {
        trace("level destroyed");

        if(script != null) script.destroy();
        script = null;

        layers.destroy();
        layers = null;

        StaticObject.clearAssets();
    }

    //-------------------------------------------------------------------------------------------------------------
    //-----------------------------------------------------SAVES---------------------------------------------------
    //-------------------------------------------------------------------------------------------------------------

    public function onSave() {
        if(script != null) {
            script.save();
            if(script.timers != null) saveables.timers = script.timers.saveTimers();
        }

        SaveManager.curSaveData.mapSaveables.set(this.path,saveables);
    }

    public function onLoad() {
        var nextMap = SaveManager.curSaveData.currentMap;

        loadLevel(nextMap,true);
    }
    
    //-------------------------------------------------------------------------------------------------------------
    //-----------------------------------------------OBJECT_MANAGEMENT---------------------------------------------
    //-------------------------------------------------------------------------------------------------------------

    //generic
    public function getObjectByName(name:String):GenericObject {
        if(layers.members.length == 1) return getObjectInLayerByName(name,0);

        for (layer in layers.members) {
            if(layer.members.length == 0) continue;
            for (basic in layer.members) {
                if(!Std.isOfType(basic, GenericObject)) continue;
                if(cast(basic, GenericObject).name == name) return cast basic;
            }
        }

        LogFile.log("No object exists in scene with the name "+name);
        return null;
    }

    public function getRailByName(name:String):Rail {
        if(layers.members.length == 1) return getRailInLayerByName(name,0);

        for (layer in layers.members) {
            if(layer.rails.members.length == 0) continue;
            for (rail in layer.rails.members) {
                if(rail.name == name) return rail;
            }
        }

        LogFile.log("No rail exists in scene with the name "+name);
        return null;
    }

    //specific
    public function getObjectInLayerByName(name:String, layer:Int):GenericObject {
        if(layers.members[layer] == null || layer < 0) {
            LogFile.log("Layer "+layer+" does not exist!");
            return null;
        }

        if(layers.members[layer].members.length != 0){
            for (basic in layers.members[layer].members) {
                if(!Std.isOfType(basic, GenericObject)) continue;
                if(cast(basic, GenericObject).name == name) return cast basic;
            }
        }

        LogFile.log("No object exists in scene layer "+layer+" with the name "+name);
        return null;
    }

    public function getRailInLayerByName(name:String, layer:Int):Rail {
        if(layers.members[layer] == null || layer < 0) {
            LogFile.log("Layer "+layer+" does not exist!");
            return null;
        }

        if(layers.members[layer].rails.members.length != 0){
            for (rail in layers.members[layer].rails.members) {
                if(rail.name == name) return rail;
            }
        }

        LogFile.log("No rail exists in scene layer "+layer+" with the name "+name);
        return null;
    }

    //-------------------------------------------------------------------------------------------------------------
    //------------------------------------------------LEVEL_SCRIPT-------------------------------------------------
    //-------------------------------------------------------------------------------------------------------------

    public function doLevelCallback(name:String, ?args:Array<Dynamic> = null) {
        if(script == null) return;

        script.doFunction(name,args);
    }
}