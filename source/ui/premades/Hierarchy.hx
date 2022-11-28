package ui.premades;

import ui.elements.ContainerMover;
import leveleditor.LevelEditor;
import ui.elements.Context;
import flixel.FlxG;
import ui.base.Container;
import leveleditor.LayerVisualizer;
import leveleditor.ObjectVisualizer;
import flixel.group.FlxGroup.FlxTypedGroup;
import ui.premades.hierarchy.HierarchyNode;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;

//how the fuck do i handle this
//store a reference to the object and check every frame if the object's been deleted?
class Hierarchy extends DMenu {

    static final nodesBaseY:Float = 50;


    var hierarchyCombinedHeight:Float = 0;

    public var nodes:FlxTypedGroup<HierarchyNode>;

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //creating/destroying

    override public function new() {
        super(0,0,400,600);

        var mover:ContainerMover = new ContainerMover();
        super.mover = mover;

        canScroll = true;

        nodes = new FlxTypedGroup();
        nodes.camera = cam;
    }

    override function destroy() {
        nodes.destroy();
        nodes = null;

        super.destroy();
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //updating and shit

    override function update(elapsed:Float) {
        super.update(elapsed);

        var i = 0;
        while (i < nodes.length) {
            if(nodes.members[i] != null){
				if(!nodes.members[i].exists) { nodes.remove(nodes.members[i], true); i--; }
			}
			else{
				nodes.remove(nodes.members[i], true); i--;
			}
            i++;
        }

        hierarchyCombinedHeight = 0;

        nodes.forEach(updateNode);
        nodes.update(elapsed);
    }

    function updateNode(node:HierarchyNode) {
        node.setPosition(20/*temp x*/, nodesBaseY + hierarchyCombinedHeight);
        hierarchyCombinedHeight += node.combinedHeight;
    }

    override function updateInputs(elapsed:Float) {
        if(!visible) return;
        if(!overlapped) return;
        if(Container.contextActive) return;

        if(FlxG.mouse.justPressed && !mover.overlaps(null)){
            LevelEditor.tempCurEdited = null;
        }
        
        super.updateInputs(elapsed);
        for (node in nodes) {
            node.updateInputs(elapsed);
        }

        if(LevelEditor.tempCurEdited == null){
            LevelEditor.curEditedObject = null;
            LevelEditor.tempCurEdited = null;
        }

        if(FlxG.mouse.justPressedRight){
            var options:Array<ContextOption> = [
                new BasicContextOption("Create blank object", blankObject)
            ];

            if(LevelEditor.curEditedObject != null) options.push(new BasicContextOption("Delete", deleteObject));

            Context.create(options);
        }
    }

    override function postUpdate(elapsed:Float) {
        super.postUpdate(elapsed);

        for (node in nodes) {
            node.postUpdate(elapsed);
        }
    }

    override function draw() {
        super.draw();

        nodes.draw();
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //world modification

    function blankObject() {
        LevelEditor.instance.createBlankObject(LevelEditor.curEditedObject);
    }

    function deleteObject() {
        LevelEditor.instance.deleteObject(LevelEditor.curEditedObject);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //node management

    function clearNodes() {
        nodes.destroy();
        nodes = new FlxTypedGroup();
    }

    function createNode(object:ObjectVisualizer, ?nesting:Int = 0):HierarchyNode {
        var node = new HierarchyNode(0,0);
        node.setReference(object);

        node.parent = this;

        for (childObject in object.children) {
            var child = createNode(childObject);
            node.children.push(child);
        }

        //fix wrong positioning
        node.x = 20+(10*nesting);
        node.y = nodesBaseY + hierarchyCombinedHeight;
        node.box.color = HierarchyNode.IDLE;
        node.box.x = node.x;
        node.box.y = node.y;
        node.label.x = node.x+20;
        node.label.y = node.y+1;
        node.rotateSymbol.x = node.x+2.5;
        node.rotateSymbol.y = node.y+2.5;

        return node;
    }

    public function addNodeFor(object:ObjectVisualizer) {
        var parents:Array<ObjectVisualizer> = [];

        var curObj = object;
        while(curObj.parent != null){
            parents.unshift(curObj.parent);
            curObj = curObj.parent;
        }

        if(parents.length == 0){
            var node = createNode(object);
            nodes.add(node);
            return;
        }

        var correctNode:HierarchyNode = null;
        for (node in nodes) {
            if(node.objectReference == parents[0]) { correctNode = node; break; }
        }

        if(parents.length > 1){
            for (i in 1...parents.length) {
                for (node in correctNode.children) {
                    if(node.objectReference == parents[i]) { correctNode = node; break; }
                }
            }
        }

        var node = createNode(object,parents.length);

        correctNode.children.push(node);
        correctNode.extended = true;
    }

    public function switchLayerTo(layer:LayerVisualizer) {
        clearNodes();

        for (object in layer) {
            var node = createNode(object);
            nodes.add(node);
        }
    }
    
}