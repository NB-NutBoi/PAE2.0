package levels;

import flixel.FlxObject;
import oop.Rail;
import oop.Object;
import utility.LogFile;
import flixel.FlxBasic;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxSort;
import levels.Level;

class Layer extends FlxTypedGroup<FlxBasic> {

    public var rails:FlxTypedGroup<Rail>;
    
    public static function load(json:LayerStructure):Layer {
        var toSort:Array<FlxBasic> = [];

        for (objInst in json.objects) {
            switch (objInst._TYPE){
                case "FULL":
                    //full object
                    toSort.push(Object.fromFull(objInst));
                case "STATIC_SPRITE":
                    //static sprite object
                    trace("TODO");
                default:
                    LogFile.error("Unidentified object type found on level load, Ignoring!");
                    continue;
            }
        }

        toSort.sort(sortByZ);

        final layer:Layer = new Layer();

        for (object in toSort) {
            layer.add(object);
        }

        for (rail in json.rails) {
            layer.rails.add(new Rail(rail));
        }

        toSort.resize(0);
        toSort = null;

        return layer;
    }

    static function sortByZ(obj1:FlxBasic, obj2:FlxBasic):Int {
        return sortByZ_Order(FlxSort.ASCENDING, obj1, obj2);
    }

    static function sortByZ_Order(order:Int, obj1:FlxBasic, obj2:FlxBasic):Int {
        var z1 = 0;
        if(Std.isOfType(obj1, Object)) z1 = cast(obj1, Object).transform.z;

        var z2 = 0;
        if(Std.isOfType(obj2, Object)) z2 = cast(obj2, Object).transform.z;

        return FlxSort.byValues(order, z1, z2);
    }

    override public function new() {
        super();

        rails = new FlxTypedGroup();
    }

    override function update(elapsed:Float) {
        super.update(elapsed);
        rails.update(elapsed);
    }

    override function draw() {
        super.draw();
        rails.draw();
    }

    override function destroy() {
        super.destroy();
        rails.destroy();
    }

    override function add(Object:FlxBasic):FlxBasic {
        final r = super.add(Object);
        sort(sortByZ_Order);
        return r;
    }
}