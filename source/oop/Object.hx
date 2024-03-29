package oop;

//don't bother on FlxObject, it's got too much functionality, i can write most of what i need myself, specialized for this.
import utility.Utils;
import oop.Transform;
import oop.premades.SaveDataComponent;
import files.HXFile.HaxeScriptBackend;
import lowlevel.ListenerArray;
import files.HXFile.HaxeScript;
import levels.Level;
import JsonDefinitions;
import oop.Component.ComponentInstance;
import common.ClientPreferences;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.group.FlxGroup.FlxTypedGroup;

typedef StaticSpriteDataStructure = {
    public var _TYPE:String; //"STATIC_SPRITE" in this case
    public var name:String;
    public var extended:Bool; //editor data
    public var active:Bool;
    //-----------------------------------------------------------

    public var drawOrder:Int;//0: OBJECT_FIRST, 1: CHILDREN_FIRST
    public var children:Array<Dynamic>;

    //-----------------------------------------------------------

    public var transform:JSONTransform;
    public var scale:JSONScale;

    public var bitmapIndex:Int;
}

typedef FullObjectDataStructure = {
    public var _TYPE:String; //"FULL" in this case.
    public var name:String;
    public var extended:Bool; //editor data
    public var active:Bool;
    //-----------------------------------------------------------
    

    public var transform:JSONTransform;

    public var components:Array<ComponentInstance>;
    public var children:Array<Dynamic>;

    public var drawOrder:Int;//0: OBJECT_FIRST, 1: CHILDREN_FIRST
    public var Static:Bool;
}

enum ObjectDrawOrder {
    OBJECT_FIRST;
    CHILDREN_FIRST;
}

class Object extends GenericObject {
    
    //logic stuff
    public var components:ListenerArray<HaxeScript>;

    public static function fromJson(instance:FullObjectDataStructure, level:Level):Object {
        if(Utils.checkNull(instance,true,null,"Fed null object instance to instanciator!")) return null;
        final object = new Object(instance.transform.X, instance.transform.Y);
        object.level = level;
        object.transform.z = instance.transform.Z;

        object.name = instance.name;
        object.camera = level.camera;

        object.transform.angle = instance.transform.A;
        object.Static = instance.Static;

        object.drawOrder = instance.drawOrder == 0 ? OBJECT_FIRST : CHILDREN_FIRST;
        
        object.active = instance.active;

        for (compInst in instance.components) {
            final comp = Component.instanceComponent(compInst, object);
            if(comp == null) continue;
            object.components.push(comp);
        }

        for (childInst in instance.children) {
            final child = GenericObject.fromJson(childInst, level);
            if(child == null) continue;
            object.addChild(child);
        }

        for (component in object.components) {
            component._dynamic.backend.start();
        }

        return object;
    }

    override public function new(x:Float = 0, y:Float = 0) {
        super(x,y);

        components = new ListenerArray();
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);
        for (script in components) {
            script.update(elapsed);
        }
    }

    override function lateUpdate(elapsed:Float) {
        for (component in components) {
            component.doFunction("OnLateUpdate", [elapsed]);
        }
        super.lateUpdate(elapsed);
    }

    override function drawObject() {
        for (script in components) {
            script._dynamic.backend.draw();
        }
    }

    override public function destroy() {
        for (script in components) {
            script.destroy();
        }

        components.kill();
        components = null;

        super.destroy();
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------

    override public function save() {
        if(hasComponent("SaveData")){
            final sd:SaveDataComponent = cast getComponentBackend("SaveData");

            var keyCache = sd.key;
            sd.setKey("objectInstance");

            var tCache:TransformCache = {
                x: transform.position.x,
                y: transform.position.y,
                xAccel: transform.velocity.x,
                yAccel: transform.velocity.y,
                pps: transform.usePixelsPerSecond,
                angle: transform.angle,
                angularVel: transform.angularVelocity
            }

            sd.saveVarUnsafe("transform",tCache);

            sd.key = keyCache;
        }
        
        components.map(_saveComponent);
        super.save();
    }

    private final function _saveComponent(component:HaxeScript):HaxeScript { cast(component.backend, Component).save(); return component; }

    override public function load() {
        if(hasComponent("SaveData")){
            final sd:SaveDataComponent = cast getComponentBackend("SaveData");

            var keyCache = sd.key;
            sd.setKey("objectInstance");

            var tCache:TransformCache = sd.getVarUnsafe("transform");

            transform.setPosition(tCache.x,tCache.y);
            transform.angle = tCache.angle;

            transform.usePixelsPerSecond = tCache.pps;

            transform.velocity.set(tCache.xAccel,tCache.yAccel);
            transform.angularVelocity = tCache.angularVel;
            
            sd.key = keyCache;
        }

        components.map(_loadComponent);
        super.load();
    }

    private final function _loadComponent(component:HaxeScript):HaxeScript { cast(component.backend, Component).load(); return component; }

    //------------------------------------------------------------------------------------------------------------------------------------------------------


    public function getComponent(type:String):HaxeScript {
        for (component in components) {
            if(component._dynamic.backend.componentType == type) return component;
        }
        
        return null;
    }

    public function getComponentBackend(type:String):HaxeScriptBackend {
        for (component in components) {
            if(component._dynamic.backend.componentType == type) return component.backend;
        }
        
        return null;
    }

    public function hasComponent(type:String):Bool {
        for (component in components) {
            if(component._dynamic.backend.componentType == type) return true;
        }
        
        return false;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------

    override function setInstanceProperties(instance:GenericObject, instantiated:GenericObject) {
        if(!Std.isOfType(instance, Object) || !Std.isOfType(instantiated, Object)) return;
            var instance = cast(instance, Object);
            var instantiated = cast(instantiated, Object);

        for (component in instance.components) {
            if(component == null) continue;
            var c = component._dynamic.backend.clone(instantiated);
            if(c == null) continue;
            instantiated.components.push(c);
        }
    }
}