package ui.premades;

import ui.elements.Button;
import ui.elements.DropdownList;
import flixel.text.FlxText;
import flixel.math.FlxPoint;
import utility.Utils;
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

    static final nodesBaseY:Float = 120;
    static final nodesBaseX:Float = 25;

    var hierarchyCombinedHeight:Float = 0;


    public var topFlap:FlxSprite;
    public var bottomFlap:FlxSprite;

    public var line:FlxSprite;


    public var curLayer:DropdownList;

    public var nodes:FlxTypedGroup<HierarchyNode>;

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //creating/destroying

    override public function new() {
        super(0,0,400,600);

        var mover:ContainerMover = new ContainerMover();
        super.mover = mover;

        topFlap = Utils.makeRamFriendlyRect(0,0,400,100,0xFF1F1F1F);
        topFlap.scrollFactor.set();
        topFlap.camera = cam;

        bottomFlap = Utils.makeRamFriendlyRect(0,500,400,100,0xFF1F1F1F);
        bottomFlap.scrollFactor.set();
        bottomFlap.camera = cam;

        line = Utils.makeRamFriendlyRect(13,0,2,600,0xFFFFFFFF);
        line.scrollFactor.set();
        line.camera = cam;

        var label = new FlxText(66,10,0,"Current layer",18); label.font = "vcr";
        label.scrollFactor.set();
        add(label);

        curLayer = new DropdownList(220,10,["0"],100);
        curLayer.setScrollFactor();
        add(curLayer);

        var addLayer = new Button(340,10,21,21,"+",createNewLayer);
        addLayer.setScrollFactor();
        add(addLayer);

        var removeLayer = new Button(370,10,21,21,"-",deleteLayer);
        removeLayer.setScrollFactor();
        add(removeLayer);

        curLayer.onSelect = changeToLayer;

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

        cam.scroll.y -= FlxG.mouse.wheel * 10;
        if(cam.scroll.y < 0) cam.scroll.y = 0;

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
        node.setPosition(nodesBaseX, nodesBaseY + hierarchyCombinedHeight);
        hierarchyCombinedHeight += node.combinedHeight;
    }

    override function updateInputs(elapsed:Float) {
        if(!visible) return;
        if(!overlapped) return;
        if(Container.contextActive) return;

        var overlaps = false;

        var localMousePos = FlxPoint.get(0,0);
        localMousePos = Utils.getMousePosInCamera(cam, localMousePos, topFlap);

        overlaps = topFlap.overlapsPoint(localMousePos) || bottomFlap.overlapsPoint(localMousePos);

        localMousePos.put();

        if(FlxG.mouse.justPressed && !mover.overlaps(null) && !overlaps && exclusiveInputs == null){
            LevelEditor.tempCurEdited = null;
        }
        
        super.updateInputs(elapsed);

        if(exclusiveInputs != null) return;

        if(!overlaps){
            for (node in nodes) {
                node.updateInputs(elapsed);
            }
        }

        //--------------------------------------------------------

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
        bg.draw();

        line.draw();
        nodes.draw();

        topFlap.draw();
        bottomFlap.draw();

        if(mover != null)
            mover.draw();
        if(closer != null)
            closer.draw();
        stuffs.draw();
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

    function createNewLayer() {
        curLayer.addChoice(Std.string(LevelEditor.instance.layers.length));
        LevelEditor.instance.layers.add(new LayerVisualizer());
    }

    function deleteLayer() {
        if(LevelEditor.instance.curLayer == 0) return;
        var layers:Array<String> = [];

        LevelEditor.instance.layers.members[LevelEditor.instance.curLayer].destroy();
        LevelEditor.instance.layers.remove(LevelEditor.instance.layers.members[LevelEditor.instance.curLayer],true);

        for (i in 0...LevelEditor.instance.layers.length) {
            layers.push(Std.string(i));
        }

        curLayer.setChoices(layers);

        if(LevelEditor.instance.curLayer > LevelEditor.instance.layers.length) LevelEditor.instance.curLayer = LevelEditor.instance.layers.length;
        changeToLayer(LevelEditor.instance.curLayer);
    }

    function changeToLayer(i:Int) {
        if(i == LevelEditor.instance.curLayer) return;
        if(i > LevelEditor.instance.layers.length) return;
        LevelEditor.instance.layers.members[LevelEditor.instance.curLayer].selected = false;
        LevelEditor.instance.curLayer = i;
        LevelEditor.instance.layers.members[LevelEditor.instance.curLayer].selected = true;
        switchLayerTo(LevelEditor.instance.layers.members[i]);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //node management

    function clearNodes() {
        nodes.destroy();
        nodes = new FlxTypedGroup();
        nodes.camera = cam;
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
        node.x = nodesBaseX+(10*nesting);
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
        correctNode.extended = true; correctNode.objectReference.extended = true;
    }

    public function switchLayerTo(layer:LayerVisualizer) {
        clearNodes();

        for (object in layer) {
            var node = createNode(object);
            nodes.add(node);
        }
    }
    
}