package ui.premades.inspector;

import oop.Component;
import flixel.math.FlxPoint;
import flixel.FlxG;
import assets.AssetCache;
import flixel.graphics.FlxGraphic;
import utility.Utils;
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
	public static final BG:Int = 0xFF1D1D1D;

	public var parent:Null<Container>;

	public var component:Null<ComponentVisualizer>;

	public var fields:FlxTypedGroup<NodeField>;

	public var icon:FlxSprite;
	public var componentName:FlxText;
	public var extendedIcon:FlxSprite;

	public var box:FlxSprite;

	public var extended:Bool = true;

	override public function new(reference:ComponentVisualizer, parent:Container) {
		super(0,0);

		this.parent = parent;

		component = reference;

		box = Utils.makeRamFriendlyRect(0,0,250,20,BG);
		box.camera = parent.cam;

		combinedHeight = height = 20;


		icon = new FlxSprite(0,0,makeIcon());
		icon.setGraphicSize(20,20);
		icon.updateHitbox();
		icon.camera = parent.cam;

		extendedIcon = new FlxSprite(0,0,"embed/ui/smallarrow.png");
		extendedIcon.camera = parent.cam;

		componentName = new FlxText(0,0,0,component.component.name,16);
		componentName.font = "vcr";
		componentName.antialiasing = true;
		componentName.camera = parent.cam;

		//---------------------------------------------------

		fields = new FlxTypedGroup();
		fields.memberAdded.add(onAddField);
		for (variable in component.variables) {
			makeFieldAndAdd(variable[0], variable[1]);
		}

		extended = component.extended;
	}

	override function destroy() {

		fields.destroy();
		fields = null;

		box.destroy();
		box = null;

		componentName.destroy();
		componentName = null;

		extendedIcon.destroy();
		extendedIcon = null;

		icon.destroy();
		icon = null;

		component = null;

		super.destroy();
	}
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	function onAddField(node:NodeField) {
	}

	function makeFieldAndAdd(key:String, ?defaultValue:Null<Any>) {
		var field = makeField(key, defaultValue);
		if(field == null) return;
		fields.add(field);
	}

	function makeField(key:String, ?defaultValue:Null<Any>):NodeField {
		var type:String = component.component.editableVars.get(key).toLowerCase().trim();

		switch (type){
			//Basic data types
			case "string":
				var sF = new StringField(key, defaultValue, parent);
				sF.component = component;

				return sF;
			case "int":
				var nF = new NumberField(key, defaultValue, true, parent);
				nF.component = component;

				return nF;
			case "float":
				var nF = new NumberField(key, defaultValue, false, parent);
				nF.component = component;

				return nF;
			case "bool":
				var bF = new BoolField(key, defaultValue, parent);
				bF.component = component;

				return bF;
			//-------------------------------------------------
			//more specialized data types
			case "filepath":
				//String but has utilities to pick files
				var fP = new FileField(key,defaultValue,parent);
				fP.component = component;

				return fP;
			case "color":
				//is both an Int and an FlxColor at the same time.
				var cF = new ColorField(key,defaultValue,parent);
				cF.component = component;
			
				return cF;
		}

		//-----------------------------------------------------------------------
		//data types with variables

		if(type.startsWith("range")){
			//Float but represented as a slider between 2 ranges
			//TODO

			return null;
		}

		if(type.startsWith("enumstring")){
			//String but represented as a list of choices
			//TODO

			return null;
		}

		return null;
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	static var icons:Map<String,FlxGraphic> = new Map();

	function makeIcon():FlxGraphic {
		if(icons.exists(component.component.key)) return icons.get(component.component.key);
		var g = FlxGraphic.fromBitmapData(AssetCache.getImageCache(component.component.icon),false,"EDITOR_ICON_"+component.component.key);
		g.destroyOnNoUse = false;
		icons.set(component.component.key,g);
		return g;
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	override function update(elapsed:Float) {
		super.update(elapsed);

		combinedHeight = 20;

		extendedIcon.angle = extended == true ? 0 : -90;

		if(!extended) return;

		for (field in fields) {
			field.stackObject.setPosition(x,y+combinedHeight);
			field.update(elapsed);
			combinedHeight += field.stackObject.combinedHeight;
		}

		component.UPDATE_VARIABLES = false;
	}

	public function updateInputs(elapsed:Float) {
		var localMousePos = FlxPoint.get(0,0);
        localMousePos = Utils.getMousePosInCamera(parent == null ? camera : parent.cam, localMousePos, box);

		if(Utils.overlapsSprite(extendedIcon,localMousePos,false) && FlxG.mouse.justPressed) extended = component.extended = !extended;

		localMousePos.put();

		if(!extended) return;

		for (field in fields) {
			field.updateInputs(elapsed);
		}
	}

	public function postUpdate(elapsed:Float) {
		box.setPosition(x,y);
		box.setGraphicSize(250,Std.int(combinedHeight));
		box.updateHitbox();

		icon.setPosition(x,y);

		extendedIcon.setPosition(x+22.5,y+2.5);

		componentName.setPosition(x+50,y+2);

		if(!extended) return;

		for (field in fields) {
			field.postUpdate(elapsed);
		}
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	override function draw() {
		super.draw();

		box.draw();
		icon.draw();
		extendedIcon.draw();
		componentName.draw();

		if(extended) fields.draw();
	}
}

class NodeField extends FlxTypedGroup<FlxBasic> {
	public var parent:Null<Container>;
	public var stackObject:StackableObject;
	var _elapsed:Float;

	public var component:ComponentVisualizer;
	public var key:String;

	override public function new(key:String, _parent:Container) {
		super();
		parent = _parent;
		stackObject = new StackableObject(0,0);
		camera = parent.cam;

		this.key = key;
	}

	override function destroy() {

		stackObject.destroy();
		stackObject = null;

		component = null;

		super.destroy();
	}

	public function checkUpdated() {
		
	}

	public function updateInputs(elapsed:Float) {
		_elapsed = elapsed;
		forEach(_updateInputs);
	}
	function _updateInputs(o:FlxBasic) {
		if(Std.isOfType(o,ContainerObject)) cast(o,ContainerObject).updateInputs(_elapsed);
	}
	
	public function postUpdate(elapsed:Float) {
		_elapsed = elapsed;
		forEach(_postUpdate);
	}
	function _postUpdate(o:FlxBasic) {
		if(Std.isOfType(o,ContainerObject)) cast(o,ContainerObject).postUpdate(_elapsed);
	}

	override function add(Object:FlxBasic):FlxBasic {
		if(Std.isOfType(Object,ContainerObject)) cast(Object,ContainerObject).parent = parent;
		return super.add(Object);
	}
	
}