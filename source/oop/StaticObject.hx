package oop;

import flixel.FlxCamera;
import levels.Level;
import flixel.FlxSprite;
import oop.Object.StaticSpriteDataStructure;
import utility.Utils;
import assets.AssetCache;
import flixel.util.FlxDestroyUtil;
import flixel.graphics.FlxGraphic;

class StaticObject extends GenericObject {

    public static var staticSprites:Map<String,FlxGraphic> = new Map();
    public static function clearAssets() {
        for (s in staticSprites.keys()) {
            var g = staticSprites.get(s);
            g = FlxDestroyUtil.destroy(g);
            staticSprites.set(s,g);
            AssetCache.removeImageCache(s);
        }

        staticSprites.clear();
    }

    public static function getAsset(name:String) {
        if(staticSprites.get(name) != null) return staticSprites.get(name);
        var g = FlxGraphic.fromBitmapData(AssetCache.getImageCache(name),false,"STATIC_"+name);
        g.destroyOnNoUse = false;
        staticSprites.set(name,g);
        return g;
    }

    public static function removeAsset(name:String) {
        if(!staticSprites.exists(name))return;
        staticSprites.set(name,FlxDestroyUtil.destroy(staticSprites.get(name)));
        staticSprites.remove(name);
    }

    public static function setAssets(to:Array<String>) {
        var old = Utils.arrayFromIterator(staticSprites.keys());

        var matching:Array<String> = [];

        for (s in to) {
            if(old.contains(s)) matching.push(s);
        }

        for (s in old) {
            if(!matching.contains(s)) removeAsset(s);
        }

        for (s in to) {
            getAsset(s);
        }

    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public var sprite:FlxSprite;
    public var index:Int = 0;

    public static function fromJson(json:StaticSpriteDataStructure) {
        var so = new StaticObject(json.transform.X,json.transform.Y);
        so.transform.z = json.transform.Z;

        so.transform.angle = json.transform.A;

        so.name = json.name;

        so.drawOrder = json.drawOrder == 0 ? OBJECT_FIRST : CHILDREN_FIRST;
        so.setSprite(json.bitmapIndex);
        so.setSize(json.scale.W,json.scale.H);

        so.active = json.active;

        for (cInstance in json.children) {
            final child = GenericObject.fromJson(cInstance);
            so.addChild(child);
        }

        return so;
    }
    
    override public function new(x:Float = 0, y:Float = 0) {
        super(x,y);

        sprite = new FlxSprite(transform.internalPosition.x,transform.internalPosition.y);

        Static = true;
    }

    override public function destroy() {
        sprite.destroy();

        super.destroy();
    }

    public function setSprite(idx:Int) {
        sprite.loadGraphic(getAsset(MainState.instance.level.bitmaps[idx])); //no better way ig
        index = idx;
    }

    public function setSize(w:Int, h:Int) {
        sprite.setGraphicSize(w,h);
        sprite.updateHitbox();
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    override public function update(elapsed:Float) {
        super.update(elapsed);
        sprite.setPosition(transform.internalPosition.x,transform.internalPosition.y);
    }

    override function drawObject() {
        sprite.draw();
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    override function set_camera(value:FlxCamera):FlxCamera {
        sprite.camera = value;

        return super.set_camera(value);
    }

    override function set_cameras(value:Array<FlxCamera>):Array<FlxCamera> {
        sprite.cameras = value;

        return super.set_cameras(value);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    override function setInstanceProperties(instance:GenericObject, instantiated:GenericObject) {
        if(!Std.isOfType(instance, StaticObject) || !Std.isOfType(instantiated, StaticObject)) return;

        var instance = cast(instance, StaticObject);
        var instantiated = cast(instantiated, StaticObject);

        instantiated.setSprite(instance.index);
        instantiated.setSize(Std.int(instance.sprite.width), Std.int(instance.sprite.height));
    }
}