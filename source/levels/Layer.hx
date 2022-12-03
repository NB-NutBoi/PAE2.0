package levels;

import oop.GenericObject;
import flixel.FlxObject;
import oop.Rail;
import oop.Object;
import utility.LogFile;
import flixel.FlxBasic;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxSort;
import levels.Level;

class Layer extends FlxTypedGroup<FlxBasic> {

    public var enabled:Bool = true;

    public var rails:FlxTypedGroup<Rail>;
    
    public static function load(json:LayerStructure):Layer {
        final layer:Layer = new Layer();

        for (objInst in json.objects) {
            final result = GenericObject.fromJson(objInst);
            if(result == null) continue;
            layer.add(result);
        }

        for (rail in json.rails) {
            layer.rails.add(new Rail(rail));
        }

        layer.enabled = json.enabledByDefault;

        return layer;
    }

    override public function new() {
        super();

        rails = new FlxTypedGroup();
    }

    override function update(elapsed:Float) {
        if(!enabled) return;
        super.update(elapsed);
        rails.update(elapsed);
    }

    override function draw() {
        if(!enabled) return;
        super.draw();
        rails.draw();
    }

    override function destroy() {
        super.destroy();
        rails.destroy();
    }

    public function save() {
        for (basic in members) {
            if(Std.isOfType(basic, GenericObject)) cast(basic, GenericObject).save();
        }
    }
}