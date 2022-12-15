package oop.premades;

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

    override public function new(instancer:Dynamic, owner:Object) {
        super(null,owner);

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

        var instance:ComponentInstance = null;
        if(instancer.component != null) instance = instancer;

        if(instance == null) return;

        componentType = "AudioSource";

        FlxG.sound.volume = instance.startingData.volume;

        ready = true;

        generateFrontend();
    }

    override private function generateFrontend() {
        if(!ready || !exists) return;

        componentFrontend = {};

        componentFrontend.camera = camera;
        componentFrontend.cameras = cameras;

        //owner
        componentFrontend.transform = owner.transform;
        componentFrontend.getComponent = owner.getComponent;

        //children
        componentFrontend.getNumberOfChildren = owner.getNumberOfChildren;
        componentFrontend.getChildAt = owner.getChildAt;

        componentFrontend.Level = owner.level;

        componentFrontend.setVolume = setVolume;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------

    //override and disable standard functions

    override function awake() {}
    override function start() {}
    override function compile(fullScript:String) {}
    override function requireComponent(typeof:String):Dynamic { return null; }
    override function AddGeneral(name:String, toAdd:Dynamic) {}
    override function AddVariables() {}
    override function _traceLocals() {}
    override function _trace(content:Dynamic) {}
    override function functionExists(func:String):Bool { return false; }
    override function doFunction(func:String, ?args:Array<Dynamic>):Dynamic { return null; }
    override function getFunction(func:String):Dynamic { return null; }
    override function setStaticVar(name:String, value:Dynamic):Dynamic { return null; }
    override function getStaticVar(name:String):Dynamic { return null; }
    override function importPackage(pack:String) {}
    override function getScriptVar(name:String):Dynamic { return null; }
    override function setScriptVar(name:String, to:Dynamic) {}
    override function importClassByName(name:String) {}
    override function load() {}
    override function save() {}

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
		_cameras = null;
    }

    override public function clone(newParent:Object):Component {

        var clone:AudioListenerComponent = new AudioListenerComponent("", newParent);

        return clone;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------

    //api for interacting with this through the frontend
    public function setVolume(to:Float) {
        FlxG.sound.volume = to;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------

    override function set_camera(value:FlxCamera):FlxCamera {
        return super.set_camera(value);
    }

    override function set_cameras(value:Array<FlxCamera>):Array<FlxCamera> {
        return super.set_cameras(value);
    }
}