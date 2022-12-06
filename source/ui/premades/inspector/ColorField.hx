package ui.premades.inspector;

import flixel.util.FlxDestroyUtil;
import oop.Component;
import ui.base.Container;
import utility.Utils;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.FlxSprite;
import ui.elements.ColorPicker;
import ui.premades.inspector.InspectorComponentNode.NodeField;

class ColorField extends NodeField {
    
    public var text:FlxText;
    public var colorField:ColorPicker;
    public var sepparator:FlxSprite;

    public var value:Int;

    override public function new(name:String, defaultValue:Int, ?parent:Container) {
        super(name, parent);

        text = new FlxText(0,0,0,name,16);
        text.font = "vcr";
        text.antialiasing = true;
        add(text);

        colorField = new ColorPicker(0,0,defaultValue);
        colorField.onUpdateColor = updateValue;
        add(colorField);

        sepparator = Utils.makeRamFriendlyRect(0,0,240,2);
        add(sepparator);

        stackObject.combinedHeight = stackObject.height = 40;
    }

    override function destroy() {
        
        text = FlxDestroyUtil.destroy(text);
        colorField = FlxDestroyUtil.destroy(colorField);
        sepparator = FlxDestroyUtil.destroy(sepparator);
        
        super.destroy();
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        value = colorField.color;

        if(component.UPDATE_VARIABLES){
            if(Component.getArray(key,component.variables) != value){
                colorField.color = value = Component.getArray(key,component.variables);
            }
        }

        
        colorField.setPosition(stackObject.x+10,stackObject.y+3);
        text.setPosition(colorField.x+colorField.box.width+3,stackObject.y+5);
        sepparator.setPosition(stackObject.x+5,stackObject.y+36);
    }

    public function updateValue(f) {
        value = colorField.color;

        Component.setArray(key, value, component.variables);
        component.changeVariable(key);
    }

}