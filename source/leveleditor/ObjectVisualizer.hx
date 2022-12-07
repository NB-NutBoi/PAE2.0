package leveleditor;

import oop.Object.FullObjectDataStructure;
import flixel.math.FlxPoint;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxBasic;

class ObjectVisualizer extends GenericObjectVisualizer {

    public var components:FlxTypedGroup<ComponentVisualizer>;

    public static function fromJson(json:FullObjectDataStructure) {
        var o:ObjectVisualizer = new ObjectVisualizer();

        o.name = json.name;

        o.transform.x = json.transform.X;
        o.transform.y = json.transform.Y;
        o.transform.z = json.transform.Z; //Deprecated
        o.transform.angle = json.transform.A;

        o.extended = json.extended;
        o.drawOrder = json.drawOrder;
        o.visible = json.active;
        o.isStatic = json.Static;

        for (instance in json.components) {
            var c = ComponentVisualizer.make(instance.component,o);
            c.extended = instance.extended;
            c.copyJson(instance);

            o.components.add(c);
        }

        for (childInstance in json.children) {
            var child = GenericObjectVisualizer.makefromJson(childInstance);

            o.children.add(child);
        }

        return o;
    }

    override public function new() {
        super();

        components = new FlxTypedGroup();
    }

    override function destroy() {

        components.destroy();
        components = null;

        super.destroy();
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    override function update(elapsed:Float) {
        transform.update(elapsed);
        components.update(elapsed);
        children.update(elapsed);
    }

    override function drawObject() {
        components.draw();
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    override public function onActiveLayerChange(to:Bool) {
        for (component in components) {
            component.onActiveLayerChange(to);
        }

        super.onActiveLayerChange(to);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    override public function checkIsHit(mousePos:FlxPoint):ObjectVisualizer {
        for (component in components) {
            if(component.checkCollides(mousePos)) return this;
        }
        
        return super.checkIsHit(mousePos);
    }

    override function handleScaling(axis:Int) {
        for (component in components) {
            component.handleScaling(axis);
        }
    }

}