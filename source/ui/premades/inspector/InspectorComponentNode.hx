package ui.premades.inspector;

import flixel.text.FlxText;
import flixel.FlxSprite;
import flixel.FlxBasic;
import flixel.group.FlxGroup.FlxTypedGroup;
import leveleditor.ComponentVisualizer;
import oop.Component.ComponentClass;
import ui.base.Container;
import ui.base.ContainerObject;
import ui.elements.StackableObject;

using StringTools;

class InspectorComponentNode extends StackableObject implements ContainerObject {

	public var parent:Null<Container>;

	public var component:Null<ComponentVisualizer>;

	public var fields:FlxTypedGroup<NodeField>;

	public var icon:FlxSprite;
	public var componentName:FlxText;

	override public function new(reference:ComponentVisualizer) {
		super(0,0);

		component = reference;

		fields = new FlxTypedGroup();
		for (key in component.variables.keys()) {
			makeFieldAndAdd(key, component.variables.get(key));
		}
	}

	override function destroy() {
		super.destroy();
	}
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	function makeFieldAndAdd(key:String, ?defaultValue:Null<Any>) {
		//TODO
	}

	function makeField(key:String, ?defaultValue:Null<Any>) {
		var type:String = component.component.editableVars.get(key).toLowerCase().trim();

		switch (type){
			//Basic data types
			case "string":
				//TODO

				return;
			case "int":
				//TODO

				return;
			case "float":
				//TODO

				return;
			case "bool":
				//TODO

				return;
			//-------------------------------------------------
			//more specialized data types
			case "filepath":
				//String but has utilities to pick files
				//TODO

				return;
			case "color":
				//is both an Int and an FlxColor at the same time.
				//TODO
			
				return;
		}

		//-----------------------------------------------------------------------
		//data types with variables

		if(type.startsWith("range")){
			//Float but represented as a slider between 2 ranges
			//TODO

			return;
		}

		if(type.startsWith("enumstring")){
			//String but represented as a list of choices
			//TODO

			return;
		}
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	public function updateInputs(elapsed:Float) {}

	public function postUpdate(elapsed:Float) {}
}

class NodeField extends FlxTypedGroup<FlxBasic> {
	
}