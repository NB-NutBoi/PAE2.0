package leveleditor.componentvisualizers;

import flixel.math.FlxPoint;
import utility.Utils;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import oop.Component;
import flixel.text.FlxText;

using StringTools;

class TextVisualizer extends ComponentVisualizer {
    
    public var text:FlxText;

    override function copyJson(json:ComponentInstance) {
        super.copyJson(json);
        changeVariable("text");
        changeVariable("font");
        changeVariable("color");
        changeVariable("size");
    }

    override public function new(type:ComponentClass, parent:ObjectVisualizer) {
        super(type,parent);

        text = new FlxText(
            parent.transform.internalX+Component.getArray("offsetX", variables),
            parent.transform.internalY+Component.getArray("offsetY", variables),0,
            Component.getArray("text", variables),
            Component.getArray("size", variables));

        text.font = Component.getArray("font", variables);
        text.color = Component.getArray("color", variables);

        text.antialiasing = true;
    }

    override function destroy() {
        text = FlxDestroyUtil.destroy(text);
        super.destroy();
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    override function changeVariable(key:String, ?inEditor:Bool = false) {
        switch(key){
            case "text":
                text.text = Component.getArray("text", variables);
                text.text = text.text.replace("[br]","\n");
            case "font":
                text.font = Component.getArray("font", variables);
            case "color":
                text.color = Component.getArray("color", variables);
            case "size":
                text.size = Component.getArray("size", variables);
        }
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    override function onActiveLayerChange(to:Bool) {
        text.color = to ? Component.getArray("color", variables) : FlxColor.GRAY;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    override function checkCollides(mousePos:FlxPoint):Bool {
        return Utils.overlapsSprite(text,mousePos,false);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    override function update(elapsed:Float) {
        super.update(elapsed);

        text.setPosition(
            owner.transform.internalX+Component.getArray("offsetX", variables),
            owner.transform.internalY+Component.getArray("offsetY", variables));

            text.angle = owner.transform.internalAngle;
    }

    override function draw() {
        text.draw();
    }
}