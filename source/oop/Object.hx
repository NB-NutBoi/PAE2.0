package oop;

//don't bother on FlxObject, it's got too much functionality, i can write most of what i need myself, specialized for this.
import JsonDefinitions;
import oop.Component.ComponentInstance;
import common.ClientPreferences;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.group.FlxGroup.FlxTypedGroup;

typedef StaticSpriteDataStructure = {
    public var _TYPE:String; //"STATIC_SPRITE" in this case
    public var name:String;

    public var transform:JSONTransform;
    public var scale:JSONScale;

    public var bitmapIndex:Int;
}

typedef FullObjectDataStructure = {
    public var _TYPE:String; //"FULL" in this case.
    public var name:String;

    public var transform:JSONTransform;

    public var components:Array<ComponentInstance>;
    public var children:Array<FullObjectDataStructure>;

    public var drawOrder:Int;//0: OBJECT_FIRST, 1: CHILDREN_FIRST
    public var Static:Bool;
}

enum ObjectDrawOrder {
    OBJECT_FIRST;
    CHILDREN_FIRST;
}

class Object extends GenericObject {
    
    //logic stuff
    public var componets:FlxTypedGroup<Component>;

    public static function fromJson(instance:FullObjectDataStructure):Object {
        final object = new Object(instance.transform.X, instance.transform.Y);
        object.transform.z = instance.transform.Z;

        object.name = instance.name;

        object.transform.angle = instance.transform.A;
        object.Static = instance.Static;

        object.drawOrder = instance.drawOrder == 0 ? OBJECT_FIRST : CHILDREN_FIRST;
        

        for (compInst in instance.components) {
            final comp = Component.instanceComponent(compInst, object);
            object.componets.add(comp);
        }

        for (childInst in instance.children) {
            final child = GenericObject.fromJson(childInst);
            object.addChild(child);
        }

        return object;
    }

    override public function new(x:Float = 0, y:Float = 0) {
        super();

        componets = new FlxTypedGroup();

        componets.memberAdded.add(onAddComponent);
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);
        componets.update(elapsed);
    }

    override function drawObject() {
        componets.draw();
    }

    override public function destroy() {
        componets.destroy();

        super.destroy();
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------

    override public function save() {
        componets.forEach(_saveComponent);
        super.save();
    }

    private final function _saveComponent(component:Component) { component.save(); }

    override public function load() {
        componets.forEach(_loadComponent);
        super.load();
    }

    private final function _loadComponent(component:Component) { component.load(); }

    //------------------------------------------------------------------------------------------------------------------------------------------------------

    override function set_camera(value:FlxCamera):FlxCamera {
        componets.forEach(onAddComponent);
        componets.camera = value;

        return super.set_camera(value);
    }

    override function set_cameras(value:Array<FlxCamera>):Array<FlxCamera> {
        componets.forEach(onAddComponent);
        componets.cameras = value;

        return super.set_cameras(value);
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------


    public function getComponent(type:String):Dynamic {
        for (component in componets.members) {
            if(component.componentType == type){
                return component.componentFrontend;
            }
        }
        
        return null;
    }

    public function getComponentBackend(type:String):Component {
        for (component in componets.members) {
            if(component.componentType == type){
                return component;
            }
        }
        
        return null;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------

    function onAddComponent(value:Component) {
        value.cameras = cameras;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------

    override function setInstanceProperties(instance:GenericObject, instantiated:GenericObject) {
        if(!Std.isOfType(instance, Object) || !Std.isOfType(instantiated, Object)) return;
            var instance = cast(instance, Object);
            var instantiated = cast(instantiated, Object);

        for (component in instance.componets.members) {
            if(component == null) continue;
            var c = component.clone(instantiated);
            if(c == null) continue;
            instantiated.componets.add(c);
        }
    }
}