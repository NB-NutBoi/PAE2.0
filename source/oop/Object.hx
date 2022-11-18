package oop;

//don't bother on FlxObject, it's got too much functionality, i can write most of what i need myself, specialized for this.
import oop.Component.ComponentInstance;
import common.ClientPreferences;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.group.FlxGroup.FlxTypedGroup;

typedef StaticSpriteDataStructure = {
    public var _TYPE:String; //"STATIC_SPRITE" in this case
    public var name:String;

    public var bitmapIndex:Int;
    public var x:Float;
    public var y:Float;
    public var z:Int;

    public var w:Int;
    public var h:Int;

    public var angle:Float;
}

typedef FullObjectDataStructure = {
    public var _TYPE:String; //"FULL" in this case.
    public var name:String;

    public var x:Float;
    public var y:Float;
    public var z:Int;

    public var angle:Float;

    public var components:Array<ComponentInstance>;
    public var children:Array<FullObjectDataStructure>;

    public var drawOrder:Int;//0: OBJECT_FIRST, 1: CHILDREN_FIRST
    public var Static:Bool;
}

enum ObjectDrawOrder {
    OBJECT_FIRST;
    CHILDREN_FIRST;
}

class Object extends FlxBasic {
    
    //hierarchy stuff
    public var parent(default,set):Object;
    public var children:FlxTypedGroup<Object>;

    //logic stuff
    public var componets:FlxTypedGroup<Component>;
    public var transform:Transform; //stores the local and global coords of the object

    /**
     * Declares if this object is static.
     * 
     * An object cannot be static if it is a child of a non-static object, however, a child of a static object can be non-static.
     */
    public var Static(get,set):Bool;
    private var _static:Bool = false;

    private var x:Float;
    private var y:Float;
    private var angle:Float;

    public var name:String;

    public var drawOrder:ObjectDrawOrder = OBJECT_FIRST;

    public static function fromFull(instance:FullObjectDataStructure):Object {
        final object = new Object(instance.x, instance.y);
        object.transform.z = instance.z;

        object.name = instance.name;

        object.transform.setAngle(instance.angle);
        object.Static = instance.Static;

        object.drawOrder = instance.drawOrder == 0 ? OBJECT_FIRST : CHILDREN_FIRST;
        

        for (compInst in instance.components) {
            final comp = Component.instanceComponent(compInst, object);
            object.componets.add(comp);
        }

        for (childInst in instance.children) {
            final child = fromFull(childInst);
            object.addChild(child);
        }

        return object;
    }

    override public function new(x:Float = 0, y:Float = 0) {
        super();

        componets = new FlxTypedGroup();
        children = new FlxTypedGroup();

        transform = new Transform(this, x,y);

        componets.memberAdded.add(onAddComponent);
        children.memberAdded.add(onAddChild);

        name = "";
        this.x = x;
        this.y = y;
        angle = 0;

    }

    override public function update(elapsed:Float) {
        if(!_static){
            transform.update(elapsed);

            x = transform.getPosition_x();
            y = transform.getPosition_y();


            angle = transform.angle;
    
            super.update(elapsed);

            //trace(name+ ", X: "+x+" Y: "+y);
    
            componets.update(elapsed);
            children.update(elapsed);
        }
        else{
            x = transform.position.x + transform.localPosition.x;
            y = transform.position.y + transform.localPosition.y;
        
            angle = transform.angle + transform.localAngle;

            children.forEach(_updateStatic);
            children.update(elapsed);
        }
    }

    function _updateStatic(child:Object) {
        if(!child._static) return;
        child.transform.position.set(x, y);
        child.transform.angle = angle;
    }

    override public function draw() {
        super.draw();
        
        switch (drawOrder){
            case OBJECT_FIRST:
                if(!_static)
                    componets.draw();
        
                children.draw();
            case CHILDREN_FIRST:
                children.draw();
                
                if(!_static)
                    componets.draw();
        }

        if(transform._drawDebug && Main.DEBUG && ClientPreferences.drawDebug){
            transform.debugTransform.draw();
        }
    }

    override public function destroy() {
        if(parent != null){
            parent.removeChild(this);
        }

        transform.destroy();


        children.destroy();


        componets.destroy();

        super.destroy();
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------

    public function save() {
        componets.forEach(_saveComponent);
        children.forEach(_saveChild);
    }

    private final function _saveComponent(component:Component) { component.save(); }
    private final function _saveChild(child:Object) { child.save(); }

    public function load() {
        componets.forEach(_loadComponent);
        children.forEach(_loadChild);
    }

    private final function _loadComponent(component:Component) { component.load(); }
    private final function _loadChild(child:Object) { child.load(); }

    //------------------------------------------------------------------------------------------------------------------------------------------------------

	function get_Static():Bool {
		return _static;
	}

    //children can be either static or dynamic but parent must be static or null
	function set_Static(value:Bool):Bool {
		if (value){
            if(parent == null) return _static = value;
            else if (parent._static) return _static = value;
            else return _static = false;
        }
        else
            return _static = value;
	}

	function set_parent(value:Object):Object {
        if(value == parent) return parent;
        
        cameras = value.cameras;
		if(_static && !value._static) _static = false;
        return parent = value;
	}

    override function set_camera(value:FlxCamera):FlxCamera {
        super.set_camera(value);
        children.forEach(onAddChild);
        componets.forEach(onAddComponent);

        children.camera = value;
        componets.camera = value;

        return value;
    }

    override function set_cameras(value:Array<FlxCamera>):Array<FlxCamera> {
        super.set_cameras(value);
        children.forEach(onAddChild);
        componets.forEach(onAddComponent);

        children.cameras = value;
        componets.cameras = value;

        return value;
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

    public function getNumberOfChildren():Int {
        return children.members.length;
    }

    public function getChildAt(index:Int):Object {
        return children.members[index];
    }

    public function removeChild(child:Object) {
        if(!children.members.contains(child)) return;
        
        child.parent = null;
        children.remove(child, true);
    }

    public function addChild(child:Object) {
        if(child == null || child == this) return;
        children.add(child);
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------

    function onAddComponent(value:Component) {
        value.cameras = cameras;
    }

    function onAddChild(value:Object) {
        value.parent = this;
        value.cameras = cameras;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------

    public function Destroy(object:Object) {
        object.destroy();
    }

    public function Instantiate(instance:Object, ?parent:Object = null):Object {
        if(parent == null && this.parent != null) parent = this.parent;

        var instantiated:Object = new Object();
        instantiated.name = instance.name + "_(copy)";

        instantiated.drawOrder = instance.drawOrder;
        instantiated.Static = instance.Static;
        instantiated.parent = parent;
        
        instantiated.transform.setPosition_point(instance.transform.position);
        instantiated.transform.setAngle(instance.transform.localAngle);

        //-----------------------------------below this it clones components and returns, physical properties go above.

        for (component in instance.componets.members) {
            if(component == null) continue;
            var c = component.clone(instantiated);
            if(c == null) continue;
            instantiated.componets.add(c);
        }

        for (child in instance.children.members) {
            if(child == null) continue;
            var c = Instantiate(child, instantiated);
            if(c == null) continue;
            instantiated.children.add(c);
        }
        
        return instantiated;
    }
}