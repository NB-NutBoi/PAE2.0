package leveleditor;

import utility.LogFile;
import flixel.math.FlxPoint;
import flixel.FlxBasic;
import flixel.group.FlxGroup;

class GenericObjectVisualizer extends FlxBasic {

    public var existsInLevel:Bool = true; //to see if hierarchy or inspector need to remove the node.

    public var name:String;
    public var transform:TransformVisualizer;
    
    public var parent:Null<GenericObjectVisualizer>;
    public var children:FlxTypedGroup<GenericObjectVisualizer>;

    /**
     * Declares if this object is static.
     * 
     * An object cannot be static if it is a child of a non-static object, however, a child of a static object can be non-static.
     */
    public var isStatic:Bool = false;
    public var drawOrder:Int = 0;

    //-----------------------------------------------------------------

    public var extended:Bool = false; //hierarchy temp data
    public var usesSize:Bool = false;

    public static function makefromJson(json:Dynamic):GenericObjectVisualizer {
        switch (json._TYPE){
            case "FULL":
                //full object
                return ObjectVisualizer.fromJson(json);
            case "STATIC_SPRITE":
                //static sprite object
                trace("TODO");
            default:
                LogFile.error("Unidentified object type found!, RETURNING NULL!");
        }

        return null;
    }

    override public function new() {
        super();

        name = "unnamed";
        transform = new TransformVisualizer(this);

        children = new FlxTypedGroup();
        children.memberAdded.add(onAdd);
        children.memberRemoved.add(onAdd);
    }

    override function destroy() {
        existsInLevel = false;

        transform.destroy();
        transform = null;

        children.destroy();
        children = null;

        parent = null;

        super.destroy();
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    override function update(elapsed:Float) {
        super.update(elapsed);
        transform.update(elapsed);
        children.update(elapsed);
    }

    override function draw() {
        super.draw();

        //abstraction so stuff can be drawn however i want
        switch (drawOrder){
            case 0:
                drawObject();
        
                drawChildren();
            case 1:
                drawChildren();
                
                drawObject();
            default:
                trace("HOWWWW???????");
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

    public function onAdd(child:GenericObjectVisualizer) {
        if(child.parent != null) child.parent.children.remove(child,true);
        child.parent = this;
    }

    public function onRemove(child:GenericObjectVisualizer) {
        child.parent = null;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public function onActiveLayerChange(to:Bool) {
        for (object in children) {
            object.onActiveLayerChange(to);
        }
    }

    //ONLY COPY ATTRIBUTES!!! A COPY IS ALREADY MADE!!!
    public function duplicate(copy:GenericObjectVisualizer):GenericObjectVisualizer {
        return copy;
    }

    public function handleScaling(axis:Int) {
        
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    //way this works is it goes down the hierarchy chain until one returns itself, anything other than null is considered a success.
    public function checkIsHit(mousePos:FlxPoint):ObjectVisualizer {
        
        if(children.length > 0) {
            var result = null;
            for (child in children) {
                result = child.checkIsHit(mousePos);
                if(result != null) return result;
            }
        }

        return null;
    }
}