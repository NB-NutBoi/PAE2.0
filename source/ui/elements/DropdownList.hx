package ui.elements;

import ui.elements.ColorPicker.ColorWheel;
import flixel.FlxG;
import common.Mouse;
import flixel.math.FlxPoint;
import utility.Utils;
import flixel.text.FlxText;
import flixel.FlxSprite;
import flixel.FlxObject;
import ui.base.Container;
import ui.base.ContainerObject;

class DropdownList extends StackableObject implements ContainerObject {
	static final IDLE:Int = 0xFF303030;
    static final HOVER:Int = 0xFF414141;
    static final DISABLED:Int = 0xFF141414;


	public var parent:Null<Container>;

	public var box:FlxSprite;
	public var selected:FlxText;

	public var list:SelectableList;


	public var extended:Bool = false;
	public var over:Bool = false;

	var requestClose:Bool = false;

	public var onSelect:Int->Void = null;

	override public function new(x:Float, y:Float, defaultChoices:Array<String>, width:Int) {
		super(x,y);

		box = Utils.makeRamFriendlyRect(x,y,width,21);

		list = new SelectableList(x,y+21,defaultChoices,width);
		list.onSelect = select;

		selected = new FlxText(x+1,y,width-4,list.choices.members[list.selected].text,15);
		selected.font = "vcr";
		selected.antialiasing = true;
		selected.alignment = CENTER;

		height = combinedHeight = box.height;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if(requestClose) { parent.remove(list); extended = false; parent.exclusiveInputs = null; requestClose = false; list.isExtended = false; Container.dropdownActive = false;}

		box.setPosition(x,y);
		selected.setPosition(x+1,y);
		list.setPosition(x,y+21);

		combinedHeight = box.height;

		box.update(elapsed);
		selected.update(elapsed);

		if(extended) {	combinedHeight += list.combinedHeight; }
		else over = false;
	}

	public function updateInputs(elapsed:Float) {
		if(ColorWheel.instance != null) return;
		if(Container.contextActive) return;
		if(Container.dropdownActive && parent.exclusiveInputs != this) return;
		var localMousePos = FlxPoint.get(0,0);
		localMousePos = Utils.getMousePosInCamera(parent == null ? camera : parent.cam, localMousePos, box);

		if(!extended){
			over = box.overlapsPoint(localMousePos);
	
			if(over && FlxG.mouse.justPressed) { parent.add(list); extended = true; parent.exclusiveInputs = this; list.isExtended = true; Container.dropdownActive = true; }
		}
		else{
			if(!list.box.overlapsPoint(localMousePos) && !box.overlapsPoint(localMousePos)) requestClose = true;

			list.updateInputs(elapsed);
		}

		localMousePos.put();
	}

	public function postUpdate(elapsed:Float) {
		if(!extended) 
		{
			if(over){
				Mouse.setAs(BUTTON);
				box.color = HOVER;
			}
			else{
				box.color = IDLE;
			}
		}
	}

    override function draw() {
		super.draw();

		box.draw();
		selected.draw();
	}

	override function setScrollFactor(x:Float = 0, y:Float = 0) {
		super.setScrollFactor(x, y);
		box.scrollFactor.set(x,y);
		selected.scrollFactor.set(x,y);
		list.setScrollFactor(x,y);
	}

	override function setPosition(X:Float = 0, Y:Float = 0) {
		box.x = X;
		box.y = Y;
		super.setPosition(X, Y);
	}

	//-------------------------------------------------------------------------------------------------------

	function select(i:Int) {
		selected.text = list.choices.members[i].text;
		requestClose = true;
		if(onSelect != null) onSelect(list.selected);
	}

	public function addChoice(s:String) {
		list.addChoice(s);
	}

	public function removeChoice(s:String) {
		list.removeChoice(s);
	}

	public function setChoices(choices:Array<String>) {
		list.setChoices(choices);
		selected.text = list.choices.members[list.selected].text;
	}

	public function setChoice(choice:String) {
		selected.text = list.choices.members[list.setChoice(choice)].text;
	}

	public function choiceExists(s:String):Bool {
		return list.choiceExists(s);
	}
}