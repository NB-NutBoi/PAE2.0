package ui.premades.inspector;

import oop.Component;
import leveleditor.ComponentVisualizer;
import flixel.util.FlxDestroyUtil;
import utility.Utils;
import flixel.text.FlxText;
import ui.elements.TextField;
import flixel.FlxSprite;
import ui.base.Container;
import ui.premades.inspector.InspectorComponentNode.NodeField;

class NumberField extends NodeField {
    
    public var text:FlxText;
    public var numberField:TextField;
    public var sepparator:FlxSprite;

    public var isInt:Bool = false;

    public var value:Float;

    override public function new(name:String, defaultValue:Float, int:Bool, parent:Container) {
        super(name, parent);

        text = new FlxText(0,0,0,name+" "+(int?"(int)":"(float)"),14);
        text.font = "vcr";
        text.antialiasing = true;
        add(text);

        numberField = new TextField(0,0,230);
        numberField.onPressEnter.add(onEnter);
        numberField.onDeselect.add(deselect);
        add(numberField);

        sepparator = Utils.makeRamFriendlyRect(0,0,240,2);
        add(sepparator);

        value = defaultValue;
        numberField.textField.text = Std.string(value);
        numberField.caret = numberField.textField.text.length;
        numberField.onUpdateText();
        isInt = int;

        stackObject.combinedHeight = stackObject.height = 55;
    }

    override function destroy() {

        text = FlxDestroyUtil.destroy(text);
        numberField = FlxDestroyUtil.destroy(numberField);
        sepparator = FlxDestroyUtil.destroy(sepparator);

        super.destroy();
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        if(component.UPDATE_VARIABLES){
            if(Component.getArray(key,component.variables) != value){
                value = Component.getArray(key,component.variables);

                numberField.textField.text = Std.string(value);
                numberField.caret = numberField.textField.text.length;
                numberField.onUpdateText();
            }
        }

        text.setPosition(stackObject.x+2,stackObject.y+1.5);
        numberField.setPosition(stackObject.x+10,stackObject.y+20.5);
        sepparator.setPosition(stackObject.x+5,stackObject.y+53);
    }

    public function deselect() {
        onEnter("");
    }

    public function onEnter(_) {
        if(isInt){
            var newValue:Null<Int> = Std.parseInt(numberField.textField.text);

            if(newValue != null){
                value = newValue;
            }
        }
        else{
            var newValue:Float = Std.parseFloat(numberField.textField.text);

            if(!Math.isNaN(newValue)){
                value = newValue;
            }
        }

        numberField.textField.text = Std.string(value);
        numberField.caret = numberField.textField.text.length;
        numberField.onUpdateText();

        Component.setArray(key, isInt ? Std.int(value) : value, component.variables);
		component.changeVariable(key,true);
    }

}