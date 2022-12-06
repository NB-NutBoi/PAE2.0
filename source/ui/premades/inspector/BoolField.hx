package ui.premades.inspector;

import oop.Component;
import flixel.util.FlxDestroyUtil;
import ui.base.Container;
import utility.Utils;
import flixel.FlxSprite;
import ui.premades.inspector.InspectorComponentNode;
import ui.elements.Checkbox;

class BoolField extends NodeField {
    
    public var boolField:Checkbox;
    public var sepparator:FlxSprite;

    override public function new(name:String, defaultValue:Bool, ?parent:Container) {
        super(name, parent);

        boolField = new Checkbox(0,0,name,check);
        boolField.checked = defaultValue;
        add(boolField);

        sepparator = Utils.makeRamFriendlyRect(0,0,240,2);
        add(sepparator);

        stackObject.combinedHeight = stackObject.height = 35;
    }

    override function destroy() {
        
        boolField = FlxDestroyUtil.destroy(boolField);
        sepparator = FlxDestroyUtil.destroy(sepparator);
        
        super.destroy();
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        if(component.UPDATE_VARIABLES){
            if(Component.getArray(key,component.variables) != boolField.checked){
                boolField.checked = Component.getArray(key,component.variables);
            }
        }

        boolField.setPosition(stackObject.x+10,stackObject.y+6);
        sepparator.setPosition(stackObject.x+5,stackObject.y+32);
    }

    public function check(to:Bool) {
        Component.setArray(key,boolField.checked, component.variables);
        component.changeVariable(key);
    }

}