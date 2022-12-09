package ui.premades.hierarchy;

import leveleditor.GenericObjectVisualizer;
import leveleditor.LevelEditor;
import flixel.text.FlxText;
import flixel.FlxG;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import utility.Utils;
import leveleditor.ObjectVisualizer;
import flixel.FlxSprite;
import ui.base.Container;
import ui.base.ContainerObject;
import ui.elements.StackableObject;

class HierarchyNode extends StackableObject implements ContainerObject{
	public var parent:Null<Container>;


	public static final IDLE:Int = 0xFF303030;
    static final HOVER:Int = 0xFF414141;
	static final SELECTED:Int = 0xFF484474;


	public var objectReference:Null<GenericObjectVisualizer>;

	public var rotateSymbol:FlxSprite;
	
	public var hierarchyParent:Null<HierarchyNode>;
	public var children:Array<HierarchyNode>;


	public var extended:Bool = false;
	public var over:Int = -1;

	public var box:FlxSprite;
	public var label:FlxText;

	public var icons:Array<FlxSprite>;

	//drag'n drop

	public var held:Bool = false;
	public var heldTimer:Int = 0;

	public var Drag:Bool = false;

	override public function new(x:Float, y:Float) {
		super(x,y);

		children = [];

		rotateSymbol = new FlxSprite(0,0,"embed/ui/smallarrow.png");

		icons = [];
		box = Utils.makeRamFriendlyRect(x,y,200,20,FlxColor.WHITE);
		height = 20;
		combinedHeight = 20;

		label = new FlxText(0,0,180,"",16);
		label.font = "vcr";
		label.textField.wordWrap = false;
		label.textField.multiline = false;
	}

	override function destroy() {

		if(hierarchyParent != null) {
			hierarchyParent.children.remove(this);
			hierarchyParent = null;
		}

		if(LevelEditor.curEditedObject == objectReference) { LevelEditor.tempCurEdited = null; LevelEditor.curEditedObject = null; }
		objectReference = null;

		icons.resize(0);
		icons = null;

		for (node in children) {
			node.destroy();
		}

		box.destroy();
		box = null;

		rotateSymbol.destroy();
		rotateSymbol = null;

		label.destroy();
		label = null;

		super.destroy();
	}

	public function delete() {
		LevelEditor.instance.deleteObject(objectReference);
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	public function setReference(reference:GenericObjectVisualizer) {
		if(reference == null) return;

		objectReference = reference;

		label.text = reference.name;
		extended = reference.extended;
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	override function update(elapsed:Float) {
		if(!exists) return;

		if(objectReference == null) { destroy(); return; }
		if(!objectReference.existsInLevel) { destroy(); return; }
		if(objectReference.name != label.text) label.text = objectReference.name;

		var i = 0;
		while (i < children.length) {
			if(children[i] != null){
				if(!children[i].exists) { children.remove(children[i]); i--; }
			}
			else{
				children.remove(children[i]); i--;
			}
			
			i++;
		}

		rotateSymbol.update(elapsed);
		rotateSymbol.angle = extended == true ? 0 : -90;

		combinedHeight = height;

		if(Drag){
			var localMousePos = FlxPoint.get(0,0);
        	localMousePos = Utils.getMousePosInCamera(parent == null ? camera : parent.cam, localMousePos, box);
			x = localMousePos.x - 20;
			y = localMousePos.y - 10;
			localMousePos.put();
		}

		over = -1;
		super.update(elapsed);

		box.setPosition(x,y);
		label.setPosition(x+rotateSymbol.width+2.5,y+1);
		rotateSymbol.setPosition(x+2.5,y+2.5);

		for (i in 0...icons.length) {
			if(icons[i].camera != parent.cam) icons[i].camera = parent.cam;
		}

		if(extended){
			for (node in children) {
				node.setPosition(x+10,y+combinedHeight);
				node.update(elapsed);
				combinedHeight += node.combinedHeight;
			}
		}
	}

	public function updateInputs(elapsed:Float) {
		if(!exists) return;

		var localMousePos = FlxPoint.get(0,0);
        localMousePos = Utils.getMousePosInCamera(parent == null ? camera : parent.cam, localMousePos, box);

		if(box.overlapsPoint(localMousePos)) over = 0;
		if(children.length > 0 && Utils.overlapsSprite(rotateSymbol,localMousePos,false)) over = 1;
		if(over != -1 && !Drag) { Hierarchy.overlappedNode = this; } else if(Hierarchy.overlappedNode == this) { Hierarchy.overlappedNode = null; }

		if(FlxG.mouse.justPressed){
			if(over != -1) LevelEditor.tempCurEdited = objectReference;
			if(over == 1) { extended = !extended; objectReference.extended = extended; }
			if(over == 0) { LevelEditor.curEditedObject = objectReference; held = true; }
			Drag = false;
		}
		
		if(FlxG.mouse.justReleased) { held = false; if(Drag) Hierarchy.instance.dropNode(this); Drag = false; }

		if(FlxG.mouse.pressed && held){
			if(!Drag) {
				heldTimer++;
				if(heldTimer > 6) Drag = true;
			}
		}
		else{
			held = false;
			heldTimer = 0;
			if(Drag) Hierarchy.instance.dropNode(this);

			Drag = false;
		}
		

		localMousePos.put();

		if(extended){
			for (node in children) {
				node.updateInputs(elapsed);
			}
		}
	}

	public function postUpdate(elapsed:Float) {
		if(!exists) return;

		if(LevelEditor.curEditedObject == objectReference) box.color = SELECTED;
		else if(over == 0) box.color = HOVER;
		else box.color = IDLE;

		if(extended){
			for (node in children) {
				node.postUpdate(elapsed);
			}
		}
	}

	override function draw() {
		super.draw();

		if(objectReference == null) { return; } // why does this get called twice after being destroyed???
		if(!objectReference.existsInLevel) { return; }

		GenericObjectVisualizer.inactiveIcon.visible = !objectReference.visible;

		box.draw();
		if(children.length > 0) rotateSymbol.draw();
		for (i in 0...icons.length) {
			if(!icons[i].visible) continue;
			icons[i].setPosition(x+box.width-15-(20*i),y+2.5);
			icons[i].draw();
		}
		label.draw();

		if(extended){
			for (node in children) {
				node.draw();
			}
		}
	}

}