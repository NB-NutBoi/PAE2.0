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

        _text.x = owner.transform.internalPosition.x + offsetX;
        _text.y = owner.transform.internalPosition.y + offsetY;

        _text.angle = owner.transform.angle;

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
}