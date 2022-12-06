package oop.premades;

import oop.Component;
import oop.Component.ComponentInstanciator;
import assets.ImageAsset;
import flixel.FlxCamera;
import flixel.FlxG;
import rendering.Sprite;
import utility.Utils;

//better optimized component for displaying sprites
class SpriteComponent extends Component {
    
    var sprite:Sprite;

    public var texture(get,set):String;

    public var offsetX:Float = 0;
    public var offsetY:Float = 0;

    override public function new(instancer:Dynamic, owner:Object) {
        super(null,owner);

        sprite = new Sprite(0,0,null);
        sprite.cameras = owner.cameras; //default

        ready = true;

        generateFrontend();

        var instance:ComponentInstance = null;
        if(instancer.component != null) instance = instancer;

        if(instance == null) return;

        if(instance.startingData.texture != null)
            texture = instance.startingData.texture;

        if(instance.startingData.offsetX != null)
            offsetX = instance.startingData.offsetX;

        if(instance.startingData.offsetY != null)
            offsetY = instance.startingData.offsetY;

            var w = Std.int(sprite.width);
            var h = Std.int(sprite.height);
            var changeScale = false;
        if(instance.startingData.width != null){
            w = instance.startingData.width;
            changeScale = true;
        }

        if(instance.startingData.height != null){
            h = instance.startingData.height;
            changeScale = true;
        }

        if(changeScale) setSize(w,h);

    }

    override private function generateFrontend() {
        if(!ready || !exists) return;

        componentFrontend = {};

        //i think its more efficient to add them like this for premades?
        componentFrontend.transform = owner.transform;
        componentFrontend.setOffset = setOffset;
        componentFrontend.setImportant = setImportant;

        componentFrontend.overlapsMouse = overlapsMouse;
        componentFrontend.setVisible = setVisible;
        componentFrontend.isAnimated = isAnimated;

        componentFrontend.setTexture = set_texture;
        componentFrontend.getTexture = get_texture;

        componentFrontend.requestAnimation = requestAnimation;
        componentFrontend.playAnimation = playAnimation;

        componentFrontend.setSize = setSize;
        
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
        
        sprite.x = owner.transform.internalPosition.x + offsetX;
        sprite.y = owner.transform.internalPosition.y + offsetY;

        sprite.angle = owner.transform.angle;

        sprite.update(elapsed);
    }

    override function draw() {
        if(!exists || !ready) return;

        sprite.draw();
    }

    override function destroy() {
        if(!exists) return;

        sprite.destroy();

        //default basic destroy (so i don't have to call super)
        exists = false;
		_cameras = null;
    }

    override public function clone(newParent:Object):Component {

        var clone:SpriteComponent = new SpriteComponent("", newParent);
        clone.texture = texture;

        clone.offsetX = offsetX;
        clone.offsetY = offsetY;

        clone.setSize(Std.int(sprite.width), Std.int(sprite.height));

        return clone;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------

    //api for interacting with this through the frontend

    public function overlapsMouse(?pixelAccurate:Bool = false) {
        return Utils.overlapsSprite(sprite, Utils.getMousePosInCamera(cameras[0]), pixelAccurate);
    }

    public function setOffset(?x:Float = 0, ?y:Float = 0) {
        offsetX = x;
        offsetY = y;
    }

    public function setVisible(value:Bool) { visible = value; }
    public function requestAnimation(name:String) { sprite.requestAnimation(name); }
    public function playAnimation(name:String, ?force:Bool = false) { sprite.playAnimation(name, force); }

    public function isAnimated():Bool { return sprite.animated; }

    public function setImportant(to:Bool) {
        if(sprite.assets[0] != null)
            sprite.assets[0].important = to;
    }

    public function setSize(w:Int, h:Int, ?updateHitbox:Bool = true) {
        sprite.setGraphicSize(w,h);
        if(updateHitbox) sprite.updateHitbox();
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------

	function get_texture():String {
        if(sprite.assets[0] == null) return "";
		return sprite.assets[0].key;
	}

	function set_texture(value:String):String {
        if(value == "") return value;
        
        var asset = ImageAsset.get(value);
        sprite.setAsset(asset);
        
		return value;
	}

    override function set_camera(value:FlxCamera):FlxCamera {
        return sprite.camera = value;
    }

    override function set_cameras(value:Array<FlxCamera>):Array<FlxCamera> {
        return sprite.cameras = value;
    }
}