package oop.premades;

import flixel.util.FlxColor;
import files.HXFile;
import common.HscriptTimer;
import oop.Component;
import assets.ImageAsset;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.text.FlxText;
import rendering.Sprite;
import rendering.Text;
import utility.Utils;

//better optimized component for displaying sprites
class TextComponent extends Component {

    public var _text:Text;

    public var text(get,set):String;
    public var size(get,set):Int;
    public var font(get,set):String;

    public var offsetX:Float = 0;
    public var offsetY:Float = 0;

    public var isCentered:Bool = false;

    override function create(instance:ComponentInstance) {
        super.create(instance);

        _text = new Text(0,0,0,"");
        _text.cameras = owner.cameras; //default

        _text.text = instance.startingData.text;
        _text.font = instance.startingData.font;
        _text.size = instance.startingData.size;
        _text.color = instance.startingData.color;
        
        offsetX = instance.startingData.offsetX;
        offsetY = instance.startingData.offsetY;

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

        frontend.overlapsMouse = overlapsMouse;
        frontend.setOffset = setOffset;
        frontend.setVisible = setVisible;

        frontend.setText = set_text;
        frontend.getText = get_text;
        frontend.setSize = set_size;
        frontend.getSize = get_size;
        frontend.setFont = set_font;
        frontend.getFont = get_font;

        frontend.setGlowing = setGlowing;
        frontend.setColorTransform = setColorTransform;
        frontend.setColor = setColor;
        frontend.setAlignment = setAlignment;
        frontend.setIsCentered = setIsCentered;

        frontend.setCamera = setCamera;
        frontend.getCamera = getCamera;
        frontend.setCameras = setCameras;
        frontend.getCameras = getCameras;
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
    override function getTimers() { return null; }
    override function loadTimers(from:Array<HscriptTimerSave>) {}
    override function populateFrontend() {}
    override function RegisterExternalFunction(name:String, func:Dynamic) {}
    override function decompile() {}
    override function _import(what:Import, as:Import) {}
    override function grantImportPerms(to:HaxeScript) {}
    override function preprocessString(script:String, ?og:Bool = true):String { return "";}
    override function setCompilerFlag(name:String, value:Bool) {}

    //overrides

    override function update(elapsed:Float) {
        if(!exists || !ready) return;

        _text.x = owner.transform.internalPosition.x + offsetX;
        _text.y = owner.transform.internalPosition.y + offsetY;

        _text.angle = owner.transform.angle;

        if(_text.alignment == CENTER) { //Special treatment: it'll be treated as if the pivot were the center of the text.
            _text.x -= _text.width * 0.5;
            _text.y -= _text.height * 0.5;
        }

        if(isCentered) _text.screenCenter(XY); //lazy

        _text.update(elapsed);
    }

    override function draw() {
        if(!exists || !ready) return;

        _text.draw();
    }

    override function destroy() {
        if(!exists) return;

        _text.destroy();

        //default basic destroy (so i don't have to call super)
        exists = false;
    }

    override public function clone(newParent:Object):HaxeScript {
        var c:HaxeScript = Component.instanceComponent("Text",newParent);
        var clone:TextComponent = c._dynamic.backend;
        clone.text = text;
        clone.font = font;
        clone.size = size;

        clone.offsetX = offsetX;
        clone.offsetY = offsetY;

        return c;
    }

    override function load() {
        if(owner.hasComponent("SaveData")){
            final sd:SaveDataComponent = cast owner.getComponentBackend("SaveData");
            
            //LOAD SAVED DATA
            var keyCache = sd.key;
            sd.setKey("textComponent");

            if(sd.existsVarType("text",String)) text = sd.getVarStringUnsafe("text");
            if(sd.existsVarType("font",String)) font = sd.getVarStringUnsafe("font");
            if(sd.existsVarType("size",Int)) size = sd.getVarInt("size");
            if(sd.existsVarType("color",Int)) _text.color = sd.getVarInt("color");

            if(sd.existsVarType("offsetX",Float)) offsetX = sd.getVarFloatUnsafe("offsetX");
            if(sd.existsVarType("offsetY",Float)) offsetY = sd.getVarFloatUnsafe("offsetY");

            sd.key = keyCache;
        }
    }

    override function save() {
        if(owner.hasComponent("SaveData")){
            final sd:SaveDataComponent = cast owner.getComponentBackend("SaveData");

            var keyCache = sd.key;
            sd.setKey("textComponent");

            sd.saveVarString("text",text);
            sd.saveVarString("font",font);

            sd.saveVarInt("size",size);
            sd.saveVarInt("color",_text.color);

            sd.saveVarFloat("offsetX",offsetX);
            sd.saveVarFloat("offsetY",offsetY);
            
            sd.key = keyCache;
        }
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------

    //api for interacting with this through the frontend

    public function overlapsMouse(?pixelAccurate:Bool = false) {
        return Utils.overlapsSprite(_text, owner.camera, pixelAccurate, owner.level.collisionLayer);
    }

    public function setOffset(?x:Float = 0, ?y:Float = 0) {
        offsetX = x;
        offsetY = y;
    }

    public function setVisible(value:Bool) {
        visible = value;
    }

    public var glow:Bool = false;
    public function setGlowing(to:Bool) {
        if(glow == to) return;
        glow = to;
        if(to)
            _text.setColorTransform(1,1,1,1,30,30,30,0);
        else
            _text.setColorTransform(1,1,1,1,0,0,0,0);
    }

    public function setColorTransform(rm:Float, bm:Float, gm:Float, am:Float, ro:Int, bo:Int, go:Int, ao:Int) {
        glow = false;
        _text.setColorTransform(rm,bm,gm,am,ro,bo,go,ao);
    }

    public function setColor(color:FlxColor) {
        if(_text.color != color)
        _text.color = color;
    }

    public function setAlignment(to:String) {
        _text.alignment = to;
    }

    public function setIsCentered(to:Bool) {
        isCentered = to;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------

	function get_text():String {
		return _text.text;
	}

	function set_text(value:String):String {
		return _text.text = value;
	}

	function get_size():Int {
		return _text.size;
	}

	function set_size(value:Int):Int {
		return _text.size = value;
	}

	function get_font():String {
		return _text.font;
	}

	function set_font(value:String):String {
		return _text.font = value;
	}

    function setCamera(c:FlxCamera) {
        _text.camera = owner.camera = c;
    }

    function getCamera():FlxCamera {
        return owner.camera;
    }

    function setCameras(c:Array<FlxCamera>) {
        _text.cameras = owner.cameras = c;
    }

    function getCameras():Array<FlxCamera> {
        return owner.cameras;
    }
}