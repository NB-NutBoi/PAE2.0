package oop.premades;

import haxe.DynamicAccess;
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

//better optimized component for object-specific saveable map data
class SaveDataComponent extends Component {

    public var key:String;

    override public function new(comp:Dynamic, owner:Object) {
        super(null,owner);

        var instance:ComponentInstance = null;
        if(comp.component != null) instance = comp;

        if(instance == null) return;

        componentType = "SaveData";

        key = owner.name+"."+instance.startingData.uniqueKey;

        ready = true;

        generateFrontend();
    }

    override private function generateFrontend() {
        if(!ready || !exists) return;

        componentFrontend = {};

        //i think its more efficient to add them like this for premades?
        componentFrontend.transform = owner.transform;

        //variables
        componentFrontend.initVarInt = initVarInt;
        componentFrontend.saveVarInt = saveVarInt;
        componentFrontend.getVarInt = getVarInt;
        componentFrontend.getVarIntUnsafe = getVarIntUnsafe;

        componentFrontend.initVarFloat = initVarFloat;
        componentFrontend.saveVarFloat = saveVarFloat;
        componentFrontend.getVarFloat = getVarFloat;
        componentFrontend.getVarFloatUnsafe = getVarFloatUnsafe;

        componentFrontend.initVarBool = initVarBool;
        componentFrontend.saveVarBool = saveVarBool;
        componentFrontend.getVarBool = getVarBool;
        componentFrontend.getVarBoolUnsafe = getVarBoolUnsafe;

        componentFrontend.initVarString = initVarString;
        componentFrontend.saveVarString = saveVarString;
        componentFrontend.getVarString = getVarString;
        componentFrontend.getVarStringUnsafe = getVarStringUnsafe;

        //DANGEROUS!!! MAKE SURE YOU KNOW WHAT YOU'RE DOING!!!
        componentFrontend.initVarUnsafe = initVarUnsafe;
        componentFrontend.saveVarUnsafe = saveVarUnsafe;
        componentFrontend.getVarUnsafe = getVarUnsafe;
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

    //overrides

    override function update(elapsed:Float) {}

    override function draw() {}

    override function destroy() {
        if(!exists) return;



        //default basic destroy (so i don't have to call super)
        exists = false;
		_cameras = null;
    }

    override public function clone(newParent:Object):Component {

        LogFile.error("Cannot clone a SaveData component!");

        return null;
    }

    //is there any reason to use these? all data gets saved and read live
    override function load() {}
    override function save() {}

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------

    //api for interacting with this through the frontend

    function getSaveData() {
        //maybe find a better way to do this?
        //otherwise just refactor this.

        if(!owner.level.saveables.saveDataComponents.exists(key))
            owner.level.saveables.saveDataComponents.set(key, new DynamicAccess());

        return owner.level.saveables.saveDataComponents.get(key);
    }

    //INT
    function initVarInt(name:String, defaultValue:Int) {
        final data = getSaveData();
        if(!data.exists(name)) data.set(name, defaultValue);
    }

    function saveVarInt(name:String, value:Int) {
        getSaveData().set(name,value);
    }

    function getVarInt(name:String):Int {
        final value = getSaveData().get(name);
        if(value == null) return 0;
        if(!Std.isOfType(value, Int)) return 0;
        return value;
    }

    function getVarIntUnsafe(name:String):Int {
        return cast getSaveData().get(name);
    }

    //-------------------------------------------------------------------------

    //FLOAT
    function initVarFloat(name:String, defaultValue:Float) {
        final data = getSaveData();
        if(!data.exists(name)) data.set(name, defaultValue);
    }

    function saveVarFloat(name:String, value:Float) {
        getSaveData().set(name,value);
    }

    function getVarFloat(name:String):Float {
        final value = getSaveData().get(name);
        if(value == null) return 0;
        if(!Std.isOfType(value, Float)) return 0;
        return value;
    }

    function getVarFloatUnsafe(name:String):Float {
        return cast getSaveData().get(name);
    }

    //-------------------------------------------------------------------------

    //BOOL
    function initVarBool(name:String, defaultValue:Bool) {
        final data = getSaveData();
        if(!data.exists(name)) data.set(name, defaultValue);
    }

    function saveVarBool(name:String, value:Bool) {
        getSaveData().set(name,value);
    }

    function getVarBool(name:String):Bool {
        final value = getSaveData().get(name);
        if(value == true) return true;
        return false;
    }

    function getVarBoolUnsafe(name:String):Bool {
        return cast getSaveData().get(name);
    }

    //-------------------------------------------------------------------------

    //STRING
    function initVarString(name:String, defaultValue:Dynamic) {
        final data = getSaveData();
        if(!data.exists(name)) data.set(name, Std.string(defaultValue));
    }

    function saveVarString(name:String, value:Dynamic) {
        getSaveData().set(name,Std.string(value));
    }

    function getVarString(name:String):String {
        return Std.string(getSaveData().get(name));
    }

    function getVarStringUnsafe(name:String):String {
        return getVarString(name);
    }

    //-------------------------------------------------------------------------

    //these are dangerous, you could potentially brick a save with this.
    //UNSAFE
    function initVarUnsafe(name:String, defaultValue:Dynamic) {
        final data = getSaveData();
        if(!data.exists(name)) data.set(name, defaultValue);
    }

    function saveVarUnsafe(name:String, value:Dynamic) {
        getSaveData().set(name,value);
    }

    function getVarUnsafe(name:String):Dynamic {
        return getSaveData().get(name);
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