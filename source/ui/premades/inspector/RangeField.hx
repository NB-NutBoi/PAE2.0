package ui.premades.inspector;

import oop.Component;
import flixel.util.FlxDestroyUtil;
import ui.base.Container;
import utility.Utils;
import flixel.FlxSprite;
import flixel.text.FlxText;
import ui.elements.ScrollBar;
import ui.premades.inspector.InspectorComponentNode.NodeField;

class RangeField extends NodeField {
    
    public var text:FlxText;
    public var range:ScrollBar;
    public var valueDisplay:FlxText;
    public var sepparator:FlxSprite;

    override public function new(name:String, defaultValue:Float, min:Float, max:Float, step:Float, invert:Bool, parent:Container) {
        super(name, parent);

        text = new FlxText(0,0,0,name,14);
        text.font = "vcr";
        text.antialiasing = true;
        add(text);

        range = new ScrollBar(0,0,200,20,HORIZONTAL,10);
        range.min = min;
        range.max = max;
        range.step = step;
        range.invertValue = invert;
        range.setValue(defaultValue);
        range.onScroll = updateValue;
        add(range);

        valueDisplay = new FlxText(0,0,0,Std.string(defaultValue),14);
        valueDisplay.font = "vcr";
        valueDisplay.antialiasing = true;
        add(valueDisplay);

        sepparator = Utils.makeRamFriendlyRect(0,0,240,2);
        add(sepparator);

        stackObject.combinedHeight = stackObject.height = 55;
    }

    override function destroy() {

        text = FlxDestroyUtil.destroy(text);
        range = FlxDestroyUtil.destroy(range);
        valueDisplay = FlxDestroyUtil.destroy(valueDisplay);
        sepparator = FlxDestroyUtil.destroy(sepparator);

        super.destroy();
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    override function update(elapsed:Float) {
        super.update(elapsed);

        if(component.UPDATE_VARIABLES){
            if(Component.getArray(key,component.variables) != range.value){
                range.setValue(Component.getArray(key,component.variables));

                valueDisplay.text = Std.string(range.value);
            }
        }

        text.setPosition(stackObject.x+2,stackObject.y+1.5);
        range.setPosition(stackObject.x+10,stackObject.y+20.5);
        valueDisplay.setPosition(stackObject.x+220,stackObject.y+20.5);
        sepparator.setPosition(stackObject.x+5,stackObject.y+53);
    }

    public function updateValue(value:Float) {
        valueDisplay.text = Std.string(value);

        Component.setArray(key, value, component.variables);
		component.changeVariable(key);
    }
}