package ui.premades.inspector;

import oop.Component;
import flixel.util.FlxDestroyUtil;
import ui.base.Container;
import utility.Utils;
import flixel.FlxSprite;
import flixel.text.FlxText;
import ui.elements.TextField;
import ui.premades.inspector.InspectorComponentNode.NodeField;

class StringField extends NodeField {

    public var text:FlxText;
    public var stringField:TextField;
    public var sepparator:FlxSprite;
    
    override public function new(name:String, defaultValue:String, ?parent:Container) {
        super(name, parent);

        text = new FlxText(0,0,0,name,14);
        text.font = "vcr";
        text.antialiasing = true;
        add(text);

        stringField = new TextField(0,0,230);
        stringField.textField.text = defaultValue;
        stringField.caret = stringField.textField.text.length;
        stringField.onUpdateText();
        stringField.onDeselect.add(deselect);
        stringField.onPressEnter.add(onEnter);
        add(stringField);

        sepparator = Utils.makeRamFriendlyRect(0,0,240,2);
        add(sepparator);

        stackObject.combinedHeight = stackObject.height = 55;
    }

    override function destroy() {

        text = FlxDestroyUtil.destroy(text);
        stringField = FlxDestroyUtil.destroy(stringField);
        sepparator = FlxDestroyUtil.destroy(sepparator);
        
        super.destroy();
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        if(component.UPDATE_VARIABLES){
            if(Component.getArray(key,component.variables) != stringField.textField.text){
                stringField.textField.text = Component.getArray(key,component.variables);
                stringField.caret = stringField.textField.text.length;
                stringField.onUpdateText();
            }
        }

        text.setPosition(stackObject.x+2,stackObject.y+1.5);
        stringField.setPosition(stackObject.x+10,stackObject.y+20.5);
        sepparator.setPosition(stackObject.x+5,stackObject.y+53);
    }

    public function deselect() {
        onEnter("");
    }

    public function onEnter(_) {
        Component.setArray(key, stringField.textField.text, component.variables);
		component.changeVariable(key,true);
    }

}