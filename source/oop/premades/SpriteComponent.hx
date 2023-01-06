package oop.premades;

import flixel.util.FlxColor;
import files.HXFile.HaxeScript;
import common.HscriptTimer;
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

    override function create(instance:ComponentInstance) {
        super.create(instance);

        sprite = new Sprite(0,0,null);
        sprite.cameras = owner.cameras; //default

        texture = instance.startingData.texture;

        offsetX = instance.startingData.offsetX;
        offsetY = instance.startingData.offsetY;

        var w = Std.int(sprite.width);
        var h = Std.int(sprite.height);

        if(instance.startingData.width != w || instance.startingData.height != h){
            w = instance.startingData.width;
            h = instance.startingData.height;

            setSize(w,h);
        }

        sprite.flipX = instance.startingData.flipX;
        sprite.flipY = instance.startingData.flipY;

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

        
        frontend.setOffset = setOffset;
        frontend.setImportant = setImportant;

        frontend.overlapsMouse = overlapsMouse;
        frontend.setVisible = setVisible;
        frontend.isAnimated = isAnimated;

        frontend.setGlowing = setGlowing;
        frontend.setColorTransform = setColorTransform;
        frontend.setColor = setColor;

        frontend.setTexture = set_texture;
        frontend.getTexture = get_texture;

        frontend.requestAnimation = requestAnimation;
        frontend.playAnimation = playAnimation;

        frontend.setSize = setSize;
        frontend.getWidth = getWidth;
        frontend.getHeight = getHeight;
        
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
        
        sprite.x = owner.transform.internalPosition.x + offsetX;
        sprite.y = owner.transform.internalPosition.y + offsetY;

        sprite.angle = owner.transform.angle;

        sprite.update(elapsed);
    }

    override function draw() {
        if(sprite == null || !visible) return;
        sprite.draw();
    }

    override function destroy() {
        if(!exists) return;

        sprite.destroy();

        //default basic destroy (so i don't have to call super)
        exists = false;
        thisClass = null;
    }

    override public function clone(newParent:Object):HaxeScript {
        var c:HaxeScript = Component.instanceComponent("Sprite",newParent);
        var clone:SpriteComponent = c._dynamic.backend;
        clone.texture = texture;

        clone.offsetX = offsetX;
        clone.offsetY = offsetY;

        clone.setSize(Std.int(sprite.width), Std.int(sprite.height));

        return c;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------

    //api for interacting with this through the frontend

    public function overlapsMouse(?pixelAccurate:Bool = false) {
        return Utils.overlapsSprite(sprite, owner.camera, pixelAccurate, owner.level.collisionLayer);
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

    public function getWidth():Int {
        return Std.int(sprite.width);
    }

    public function getHeight():Int {
        return Std.int(sprite.height);
    }

    public var glow:Bool = false;
    public function setGlowing(to:Bool) {
        if(glow == to) return;
        glow = to;
        if(to)
            sprite.setColorTransform(1,1,1,1,30,30,30,0);
        else
            sprite.setColorTransform(1,1,1,1,0,0,0,0);
    }

    public function setColorTransform(rm:Float, bm:Float, gm:Float, am:Float, ro:Int, bo:Int, go:Int, ao:Int) {
        glow = false;
        sprite.setColorTransform(rm,bm,gm,am,ro,bo,go,ao);
    }

    public function setColor(color:FlxColor) {
        if(sprite.color != color)
        sprite.color = color;
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
}