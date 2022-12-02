package oop.premades;

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

    override public function new(instancer:ComponentInstanciator, owner:Object) {
        super(null,owner);

        _text = new Text(0,0,0,"");
        _text.cameras = owner.cameras; //default

        ready = true;

        generateFrontend();
    }

    override private function generateFrontend() {
        if(!ready || !exists) return;

        componentFrontend = {};

        //i think its more efficient to add them like this for premades?
        componentFrontend.transform = owner.transform;

        componentFrontend.overlapsMouse = overlapsMouse;
        componentFrontend.setOffset = setOffset;
        componentFrontend.setVisible = setVisible;

        componentFrontend.setText = set_text;
        componentFrontend.getText = get_text;
        componentFrontend.setSize = set_size;
        componentFrontend.getSize = get_size;
        componentFrontend.setFont = set_font;
        componentFrontend.getFont = get_font;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------

    //override and disable standard functions

    override function awake() {}
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
		_cameras = null;
    }

    override public function clone(newParent:Object):Component {

        var clone:TextComponent = new TextComponent("", newParent);
        clone.text = text;
        clone.font = font;
        clone.size = size;

        clone.offsetX = offsetX;
        clone.offsetY = offsetY;

        return clone;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------

    //api for interacting with this through the frontend

    public function overlapsMouse(?pixelAccurate:Bool = false) {
        return Utils.overlapsSprite(_text, Utils.getMousePosInCamera(cameras[0]), pixelAccurate);
    }

    public function setOffset(?x:Float = 0, ?y:Float = 0) {
        offsetX = x;
        offsetY = y;
    }

    public function setVisible(value:Bool) {
        visible = value;
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

    override function set_camera(value:FlxCamera):FlxCamera {
        return _text.camera = value;
    }

    override function set_cameras(value:Array<FlxCamera>):Array<FlxCamera> {
        return _text.cameras = value;
    }
}