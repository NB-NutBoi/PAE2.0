package ui.premades.inspector;

import oop.Component;
import flixel.util.FlxDestroyUtil;
import ui.base.Container;
import utility.Utils;
import flixel.text.FlxText;
import flixel.FlxSprite;
import ui.elements.DropdownList;
import ui.premades.inspector.InspectorComponentNode.NodeField;

class StringEnumField extends NodeField {
    
    public var text:FlxText;
    public var stringEnum:DropdownList;
    public var sepparator:FlxSprite;

    override public function new(name:String, values:Array<String>, defaultValue:String, ?parent:Container) {
        super(name, parent);

        text = new FlxText(0,0,0,name,14);
        text.font = "vcr";
        text.antialiasing = true;
        add(text);

        stringEnum = new DropdownList(0,0,values,230);
        stringEnum.setChoice(defaultValue);
        stringEnum.onSelect = select;
        add(stringEnum);

        sepparator = Utils.makeRamFriendlyRect(0,0,240,2);
        add(sepparator);

        stackObject.combinedHeight = stackObject.height = 55;
    }

    override function destroy() {

        text = FlxDestroyUtil.destroy(text);
        stringEnum = FlxDestroyUtil.destroy(stringEnum);
        sepparator = FlxDestroyUtil.destroy(sepparator);
        
        super.destroy();
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        if(component.UPDATE_VARIABLES){
            if(Component.getArray(key,component.variables) != stringEnum.selected.text){
                stringEnum.setChoice(Component.getArray(key,component.variables));
            }
        }

        text.setPosition(stackObject.x+2,stackObject.y+1.5);
        stringEnum.setPosition(stackObject.x+10,stackObject.y+20.5);
        sepparator.setPosition(stackObject.x+5,stackObject.y+53);
    }

    public function select(i:Int) {
        Component.setArray(key, stringEnum.selected.text, component.variables);
		component.changeVariable(key,true);
    }

}