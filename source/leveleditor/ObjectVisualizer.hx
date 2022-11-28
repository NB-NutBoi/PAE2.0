package leveleditor;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxBasic;

class ObjectVisualizer extends FlxBasic {

    public var existsInLevel:Bool = true; //to see if hierarchy or inspector need to remove the node.

    public var name:String;
    public var x:Float;
    public var y:Float;
    public var z:Int;
    
    public var parent:Null<ObjectVisualizer>;

    public var children:FlxTypedGroup<ObjectVisualizer>;

    override public function new() {
        super();

        name = "unnamed";

        children = new FlxTypedGroup();
        children.memberAdded.add(onAdd);
        children.memberRemoved.add(onAdd);
    }

    override function destroy() {
        existsInLevel = false;

        children.destroy();
        children = null;

        parent = null;

        super.destroy();
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public function onAdd(child:ObjectVisualizer) {
        child.parent = this;
    }

    public function onRemove(child:ObjectVisualizer) {
        child.parent = null;
    }

}