package leveleditor;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxBasic;

class ObjectVisualizer extends FlxBasic {

    public var existsInLevel:Bool = true; //to see if hierarchy or inspector need to remove the node.
    
    public var parent:Null<ObjectVisualizer>;

    public var children:FlxTypedGroup<ObjectVisualizer>;

    override public function new() {
        super();

        children = new FlxTypedGroup();
    }

    override function destroy() {
        existsInLevel = false;
        super.destroy();
    }

}