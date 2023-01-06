package oop.premades;

import openfl.filesystem.File.HaxeFile;
import files.HXFile.HaxeScript;
import common.HscriptTimer;
import oop.Component;
import assets.ImageAsset;
import common.ClientPreferences;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.text.FlxText;
import rendering.Sprite;
import rendering.Text;
import utility.LogFile;
import utility.Utils;

//better optimized component for being the audio listener
class AudioListenerComponent extends Component {

    public static var listener:AudioListenerComponent = null;

    public var internalListener:FlxObject;

    //debug
    private var listenerSprite:FlxSprite;

    override function create(instance:ComponentInstance) {
        super.create(instance);

        if(listener != null){
            LogFile.error("ONLY 1 AUDIO LISTENER CAN EXIST AT A TIME!!!!");
            return;
        }

        listener = this;

        internalListener = new FlxObject(0,0,0,0);

        if(Main.DEBUG){
            listenerSprite = new FlxSprite(0,0,"embed/components/AudioListener.png");
            listenerSprite.cameras = [FlxGamePlus.DebugCam];
        }
        
        FlxG.sound.volume = instance.startingData.volume;

        compiled = true;
        ready = true;

        generateFrontend();
    }

    private function generateFrontend() {
        if(!ready || !exists) return;

        final frontend:Dynamic = frontend;

        //owner
        frontend.transform = owner.transform;
        frontend.getComponent = owner.getComponent;
        frontend.hasComponent = owner.hasComponent;

        //children
        frontend.getNumberOfChildren = owner.getNumberOfChildren;
        frontend.getChildAt = owner.getChildAt;

        frontend.Level = owner.level;

        frontend.setVolume = setVolume;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------

    //override and disable standard functions

    override function awake() {}
    override function start() {}
    override function compile(fullScript:String) {}
    override function requireComponent(typeof:String):HaxeScript { return null; }
    override function AddGeneral(name:String, toAdd:Dynamic) {}
    override function AddVariables() {}
    override function functionExists(func:String):Bool { return false; }
    override function doFunction(func:String, ?args:Array<Dynamic>):Dynamic { return null; }
    override function getFunction(func:String):Dynamic { return null; }
    override function setStaticVar(name:String, value:Dynamic):Dynamic { return null; }
    override function getStaticVar(name:String):Dynamic { return null; }
    override function importPackage(pack:String) {}
    override function getScriptVarExists(name:String):Bool { return false; }
    override function getScriptVar(name:String):Dynamic { return null; }
    override function setScriptVar(name:String, to:Dynamic) {}
    override function load() {}
    override function save() {}
    override function getTimers() { return null; }
    override function loadTimers(from:Array<HscriptTimerSave>) {}
    override function populateFrontend() {}
    override function RegisterExternalFunction(name:String, func:Dynamic) {}
    override function decompile() {}
    override function _import(what:String, as:String) {}
    override function grantImportPerms(to:HaxeScript) {}
    override function preprocessString(script:String, ?og:Bool = true):String { return "";}
    override function setCompilerFlag(name:String, value:Bool) {}

    //overrides

    override function update(elapsed:Float) {
        if(!exists || !ready) return;

        internalListener.setPosition(owner.transform.internalPosition.x, owner.transform.internalPosition.y);

        internalListener.update(elapsed);

        if(Main.DEBUG){
            listenerSprite.setPosition(owner.transform.internalPosition.x - (listenerSprite.width * 0.5), owner.transform.internalPosition.y  - (listenerSprite.height * 0.5));
            listenerSprite.update(elapsed);
        }
    }

    override function draw() {
        if(Main.DEBUG && ClientPreferences.drawDebug){ listenerSprite.draw();
            Component.precisionSprite.setPosition(listenerSprite.x, listenerSprite.y);
            Component.precisionSprite.draw();
        }
    }

    override function destroy() {
        if(!exists) return;

        listener = null;

        internalListener.destroy();

        //default basic destroy (so i don't have to call super)
        exists = false;
    }

    override public function clone(newParent:Object):HaxeScript {

        LogFile.error("Cannot clone a SaveData component!");

        return null;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------

    //api for interacting with this through the frontend
    public function setVolume(to:Float) {
        FlxG.sound.volume = to;
    }
}