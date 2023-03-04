package oop;

import levels.Level;
import utility.LogFile;
import flixel.FlxCamera;
import common.ClientPreferences;
import oop.Object;
import flixel.group.FlxGroup;
import flixel.FlxBasic;

//Base class for all types of objects.
class GenericObject extends FlxBasic {

    public var level:Null<Level> = null;
    
    public var name:String;
    public var transform:Transform;

    public var parent(default,set):GenericObject;
    public var children:FlxTypedGroup<GenericObject>;

    /**
     * Declares if this object is static.
     * 
     * An object cannot be static if it is a child of a non-static object, however, a child of a static object can be non-static.
     */
    public var Static(default,set):Bool;

    public var drawOrder:ObjectDrawOrder = OBJECT_FIRST;

    //-----------------------------------------------------------------

    public static function fromJson(json:Dynamic, level:Level):GenericObject {
        switch (json._TYPE){
            case "FULL":
                //full object
                return Object.fromJson(json, level);
            case "STATIC_SPRITE":
                //static sprite object
                return StaticObject.fromJson(json, level);
            default:
                LogFile.error("Unidentified object type found!, RETURNING NULL!");
        }

        return null;
    }

    override public function new(x:Float = 0, y:Float = 0) {
        super();

        name = "";

        transform = new Transform(this, x,y);

        children = new FlxTypedGroup();
        children.memberAdded.add(onAddChild);

    }

    override public function destroy() {
        level = null;
        if(parent != null){
            parent.removeChild(this);
        }

        transform.destroy();


        children.destroy();

        super.destroy();
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public function save() {
        children.forEach(_saveChild);
    }

    private final function _saveChild(child:GenericObject) { child.save(); }

    public function load() {
        children.forEach(_loadChild);
    }

    private final function _loadChild(child:GenericObject) { child.load(); }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    override public function update(elapsed:Float) {
        if(!Static){
            transform.update(elapsed);
    
            super.update(elapsed);

            children.update(elapsed);
        }
        else{
            //manually update transform with the least ammount of information possible.
            transform.internalPosition.set(transform.position.x,transform.position.y);
            transform.internalAngle = transform.angle;
            if(parent != null){
                transform.internalPosition.add(parent.transform.internalPosition.x,parent.transform.internalPosition.y);
                transform.internalAngle += parent.transform.internalAngle;
            }

            children.update(elapsed);
        }
    }

    public function lateUpdate(elapsed:Float) {
        for (object in children) {
            object.lateUpdate(elapsed);
        }
    }

    //gonna have to abstract it a lil
    override public function draw() {
        super.draw();
        
        if(!active) return;

        switch (drawOrder){
            case OBJECT_FIRST:
                drawObject();
        
                drawChildren();
            case CHILDREN_FIRST:
                drawChildren();
                
                drawObject();
        }

        if(transform._drawDebug && Main.DEBUG && ClientPreferences.drawDebug){
            transform.debugTransform.draw();
        }
    }

    public function drawObject() {
        
    }

    public function drawChildren() {
        children.draw();
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public function getNumberOfChildren():Int {
        return children.members.length;
    }

    public function getChildAt(index:Int):GenericObject {
        return children.members[index];
    }

    public function removeChild(child:GenericObject) {
        if(!children.members.contains(child)) return;
        
        child.parent = null;
        children.remove(child, true);
    }

    public function addChild(child:GenericObject) {
        if(child == null || child == this) return;
        children.add(child);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function onAddChild(value:GenericObject) {
        value.parent = this;
        value.cameras = cameras;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    //children can be either static or dynamic but parent must be static or null
	function set_Static(value:Bool):Bool {
		if (value){
            if(parent == null) return Static = value;
            else if (parent.Static) return Static = value;
            else return Static = false;
        }
        else
            return Static = value;
	}

    //------------------------------------------------------------------------

    function set_parent(value:GenericObject):GenericObject {
        if(value == parent) return parent;
        if(value == null) return parent = null;
        
        cameras = value.cameras;
		if(Static && !value.Static) Static = false;
        return parent = value;
	}

    override function set_camera(value:FlxCamera):FlxCamera {
        super.set_camera(value);
        children.forEach(onAddChild);

        children.camera = value;

        return value;
    }

    override function set_cameras(value:Array<FlxCamera>):Array<FlxCamera> {
        super.set_cameras(value);
        children.forEach(onAddChild);

        children.cameras = value;

        return value;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public function Destroy(object:GenericObject) {
        object.destroy();
    }

    public function Instantiate(instance:GenericObject, ?parent:GenericObject = null):GenericObject {
        if(parent == null && this.parent != null) parent = this.parent;

        var instantiated:GenericObject = Type.createInstance(Type.getClass(instance),[transform.position.x, transform.position.y]);
        instantiated.name = instance.name + "_(copy)";

        instantiated.drawOrder = instance.drawOrder;
        instantiated.Static = instance.Static;
        instantiated.parent = parent;
        
        instantiated.transform.setPosition_point(instance.transform.position);
        instantiated.transform.angle = instance.transform.angle;

        //-----------------------------------below this it clones components and returns, physical properties go above.

        setInstanceProperties(instance,instantiated);

        for (child in instance.children.members) {
            if(child == null) continue;
            var c = Instantiate(child, instantiated);
            if(c == null) continue;
            instantiated.children.add(c);
        }
        
        return instantiated;
    }

    private function setInstanceProperties(instance:GenericObject, instantiated:GenericObject) {
        //do nothing
    }

}