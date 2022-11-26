package ui.premades.hierarchy;

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


	static final IDLE:Int = 0xFF303030;
    static final HOVER:Int = 0xFF414141;
	static final SELECTED:Int = 0xFF484474;


	public var objectReference:Null<ObjectVisualizer>;

	public var rotateSymbol:FlxSprite;
	
	public var hierarchyParent:Null<HierarchyNode>;
	public var children:Array<HierarchyNode>;


	public var extended:Bool = false;
	public var over:Int = -1;

	public var box:FlxSprite;

	override public function new(x:Float, y:Float) {
		super(x,y);

		children = [];

		rotateSymbol = new FlxSprite(0,0,"embed/ui/smallarrow.png");

		box = Utils.makeRamFriendlyRect(x,y,200,20,FlxColor.WHITE);
		height = 20;
		combinedHeight = 20;
	}

	override function destroy() {

		objectReference = null;

		for (node in children) {
			node.destroy();
		}


		rotateSymbol.destroy();

		super.destroy();
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	public function setReference(reference:ObjectVisualizer) {
		if(reference == null) return;
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	override function update(elapsed:Float) {
		if(!exists) return;
		super.update(elapsed);

		if(objectReference == null) { destroy(); return; }
		if(!objectReference.existsInLevel) { destroy(); return; }

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
		rotateSymbol.angle = extended == true ? 0 : 90;

		combinedHeight = height;

		box.setPosition(x,y);
		rotateSymbol.setPosition(x,y);

		if(extended){
			for (node in children) {
				node.setPosition(x+10,y+combinedHeight);
				node.update(elapsed);
				combinedHeight += node.combinedHeight;
			}
		}

		over = -1;
	}

	public function updateInputs(elapsed:Float) {
		if(!exists) return;

		var localMousePos = FlxPoint.get(0,0);
        localMousePos = Utils.getMousePosInCamera(parent == null ? camera : parent.cam, localMousePos, box);

		if(box.overlapsPoint(localMousePos)) over = 0;
		if(Utils.overlapsSprite(rotateSymbol,localMousePos,true)) over = 1;

		if(FlxG.mouse.justPressed){
			if(over == 1) extended = !extended;
			//if(over == 0) TODO!!!
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

		if(Inspector.curEditedObject == objectReference) box.color = SELECTED;
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

		box.draw();
		rotateSymbol.draw();

		if(extended){
			for (node in children) {
				node.draw();
			}
		}
	}

}