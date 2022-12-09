package ui.premades;

import leveleditor.StaticObjectVisualizer;
import ui.elements.Checkbox;
import flixel.FlxCamera;
import leveleditor.GenericObjectVisualizer;
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
class Hierarchy extends Container {
    public static var instance:Hierarchy = null;
    public static var overlappedNode:HierarchyNode = null;

    static final nodesBaseY:Float = 120;
    static final nodesBaseX:Float = 25;

    var hierarchyCombinedHeight:Float = 0;


    public var topFlap:FlxSprite;
    public var bottomFlap:FlxSprite;

    public var line:FlxSprite;


    public var curLayer:DropdownList;

    public var nodes:FlxTypedGroup<HierarchyNode>;

    //-------------------------------------------------------

    public var layerEnabled:Checkbox;
    public var layerVisible:Checkbox; //in-editor only

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //creating/destroying

    override public function new() {
        super(0,0,400,600);

        bg.alpha = 0.85;
        instance = this;

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

        var addLayer = new Button(340,10,21,21,"+",createNewLayer);
        addLayer.setScrollFactor();
        add(addLayer);

        var removeLayer = new Button(370,10,21,21,"-",deleteLayer);
        removeLayer.setScrollFactor();
        add(removeLayer);

        curLayer.onSelect = changeToLayer;

        //------------------------------------------------------------------

        layerEnabled = new Checkbox(10,40,"Layer Enabled by default",setLayerEnabled);
        layerEnabled.checked = true;
        layerEnabled.setScrollFactor();
        add(layerEnabled);

        layerVisible = new Checkbox(10,70,"Layer Visible (editor only)",setLayerVisible);
        layerVisible.checked = true;
        layerVisible.setScrollFactor();
        add(layerVisible);

        //------------------------------------------------------------------

        add(curLayer);

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
        if(overlapped && focused){
            cam.scroll.y -= FlxG.mouse.wheel * 10;
            if(cam.scroll.y < 0) cam.scroll.y = 0;
        }

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

        super.update(elapsed);
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

        if(FlxG.mouse.justPressed && LevelEditor.tempCurEdited == null){
            LevelEditor.curEditedObject = null;
            LevelEditor.tempCurEdited = null;
        }

        if(FlxG.mouse.justPressedRight){
            var options:Array<ContextOption> = [];

            if(LevelEditor.curEditedObject != null) {
                
                
                options.push(new BasicContextOption("Create blank object", blankObject));
                if(!Std.isOfType(LevelEditor.curEditedObject, ObjectVisualizer)){
                    options.push(new BasicContextOption("Create static object", staticObject));
                }

                options.push(new BasicContextOption("Duplicate Object", duplicateObject));
                options.push(new BasicContextOption("Delete", deleteObject));
            }
            else{
                options.push(new BasicContextOption("Create blank object", blankObject));
                options.push(new BasicContextOption("Create static object", staticObject));
            }

            Context.create(options);
        }
    }

    override function postUpdate(elapsed:Float) {
        super.postUpdate(elapsed);

        for (node in nodes) {
            node.postUpdate(elapsed);
        }
    }

    @:access(flixel.FlxCamera)
    override function draw() {
        bg.draw();

        line.draw();

        //nodes---------------------------------------------------------------------------------
        var dragNode:HierarchyNode = null;

        var oldDefaultCameras = FlxCamera._defaultCameras;
		if (nodes.cameras != null)
		{
			FlxCamera._defaultCameras = nodes.cameras;
		}

        var i = 0;
        while (i < nodes.length) {
            final node = nodes.members[i];
            if(node != null && node.Drag) {dragNode = node; i++; continue;}
            if(node != null && node.exists && node.visible) node.draw();
            i++;
        }

        if(dragNode != null) dragNode.draw();

        FlxCamera._defaultCameras = oldDefaultCameras;
        //--------------------------------------------------------------------------------------

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

    function staticObject() {
        LevelEditor.instance.createStaticObject(LevelEditor.curEditedObject);
    }

    function deleteObject() {
        LevelEditor.instance.deleteObject(LevelEditor.curEditedObject);
    }

    function duplicateObject() {
        LevelEditor.instance.duplicateObject(LevelEditor.curEditedObject);
    }

    function createNewLayer() {
        curLayer.addChoice(Std.string(LevelEditor.instance.layers.length));
        LevelEditor.instance.layers.add(new LayerVisualizer());
    }

    function deleteLayer() {
        if(LevelEditor.instance.curLayer == 0) return;
        var layers:Array<String> = [];

        LevelEditor.instance.layers.members[LevelEditor.instance.curLayer].selected = false;
        LevelEditor.instance.layers.members[LevelEditor.instance.curLayer].destroy();
        LevelEditor.instance.layers.remove(LevelEditor.instance.layers.members[LevelEditor.instance.curLayer],true);

        for (i in 0...LevelEditor.instance.layers.length) {
            layers.push(Std.string(i));
        }

        if(LevelEditor.instance.curLayer >= LevelEditor.instance.layers.length) LevelEditor.instance.curLayer = LevelEditor.instance.layers.length-1;
        LevelEditor.instance.layers.members[LevelEditor.instance.curLayer].selected = true;
        switchLayerTo(LevelEditor.instance.layers.members[LevelEditor.instance.curLayer]);

        curLayer.setChoices(layers);
    }

    function changeToLayer(i:Int) {
        if(i == LevelEditor.instance.curLayer) return;
        if(i >= LevelEditor.instance.layers.length) return;
        if(LevelEditor.instance.layers.members[LevelEditor.instance.curLayer] != null) LevelEditor.instance.layers.members[LevelEditor.instance.curLayer].selected = false;
        LevelEditor.instance.curLayer = i;
        LevelEditor.instance.layers.members[LevelEditor.instance.curLayer].selected = true;
        switchLayerTo(LevelEditor.instance.layers.members[i]);
    }

    function setLayerEnabled(to:Bool) {
        LevelEditor.instance.layers.members[LevelEditor.instance.curLayer].enabledByDefault = to;
    }

    function setLayerVisible(to:Bool) {
        LevelEditor.instance.layers.members[LevelEditor.instance.curLayer].visible = to;
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

    function createNode(object:GenericObjectVisualizer, ?nesting:Int = 0):HierarchyNode {
        var node = new HierarchyNode(0,0);
        node.setReference(object);

        node.parent = this;

        for (childObject in object.children) {
            var child = createNode(childObject);
            node.children.push(child);
            child.hierarchyParent = node; //FUCKING FUCKITTY FUCK i'm a dumbass
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

        if(Std.isOfType(object, StaticObjectVisualizer)){
            node.icons.push(GenericObjectVisualizer.staticIcon);
        }
        
        node.icons.push(GenericObjectVisualizer.inactiveIcon);

        return node;
    }

    public function addNodeFor(object:GenericObjectVisualizer) {
        var parents:Array<GenericObjectVisualizer> = [];

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
        node.hierarchyParent = correctNode;
        correctNode.extended = true; correctNode.objectReference.extended = true;
    }

    public function switchLayerTo(layer:LayerVisualizer) {
        clearNodes();

        for (object in layer) {
            var node = createNode(object);
            nodes.add(node);
        }

        layerEnabled.checked = layer.enabledByDefault;
        layerVisible.checked = layer.visible;
    }

    //this took        SO         long.
    public function dropNode(node:HierarchyNode) {
        var localMousePos = FlxPoint.get(0,0);
        localMousePos = Utils.getMousePosInCamera(cam, localMousePos, topFlap);

        final nodeY = localMousePos.y - nodesBaseY;
        var theNodeToAddendum:HierarchyNode = nodes.members[0];
        var listDepth = 0;
        var depthIdx:Map<Int,Int> = [0 => 0];
        final goalCoords:Float = Math.floor(Math.round(nodeY) / 20) * 20;

        localMousePos.put();

        var coords:Float = 0;
        while (coords < goalCoords){
            if(coords > goalCoords) break;

            coords +=20;

            if(theNodeToAddendum.extended && theNodeToAddendum.children.length > 0){
                listDepth++;
                if(!depthIdx.exists(listDepth))depthIdx.set(listDepth,0);
                depthIdx[listDepth]=0;
                theNodeToAddendum = theNodeToAddendum.children[depthIdx[listDepth]];
            }
            else if(listDepth > 0 && theNodeToAddendum.hierarchyParent.children.length-1 == depthIdx[listDepth]){
                //reached end of sublist, go up one
                listDepth--;
                depthIdx[listDepth]++;
                if(listDepth > 0){
                    if(theNodeToAddendum.hierarchyParent.hierarchyParent.children[depthIdx[listDepth]] == null) { theNodeToAddendum = theNodeToAddendum.hierarchyParent.hierarchyParent; continue; }
                    theNodeToAddendum = theNodeToAddendum.hierarchyParent.hierarchyParent.children[depthIdx[listDepth]];
                }
                else{
                    if(nodes.members[depthIdx[listDepth]] == null) { theNodeToAddendum = theNodeToAddendum.hierarchyParent; continue; }
                    theNodeToAddendum = nodes.members[depthIdx[listDepth]];
                }

                //should perform a list exit loop until root is reached or more chilren exist, this is causing issues as is.
            }
            else if(listDepth > 0){
                depthIdx[listDepth]++;
                theNodeToAddendum = theNodeToAddendum.hierarchyParent.children[depthIdx[listDepth]];
            }
            else{
                depthIdx[listDepth]++;
                if(nodes.members[depthIdx[listDepth]] == null) continue;
                theNodeToAddendum = nodes.members[depthIdx[listDepth]];
            }
        }

        if(theNodeToAddendum == node) return;

        depthIdx.clear();
        depthIdx = null;

        final leeway = nodeY-(theNodeToAddendum.y-nodesBaseY);

        if(leeway >= 17 || leeway <= 3){
            //in-between.
            
            var type = 0;

            if(leeway >= 17) type = 1; //below
            if(leeway <= 3) type = -1; //above


            switch (type){
                case 1:
                    if(theNodeToAddendum.hierarchyParent == null){

                        deparentNode(node);

                        var idx = nodes.members.indexOf(theNodeToAddendum)+1;
                        nodes.insert(idx,node);
                        LevelEditor.instance.layers.members[LevelEditor.instance.curLayer].insert(idx,node.objectReference);
                    }
                    else{

                        if(node.objectReference.isStatic && !theNodeToAddendum.hierarchyParent.objectReference.isStatic) return;

                        deparentNode(node);

                        final idx = theNodeToAddendum.hierarchyParent.children.indexOf(theNodeToAddendum)+1;
                        theNodeToAddendum.hierarchyParent.objectReference.children.insert(idx,node.objectReference);
                        theNodeToAddendum.hierarchyParent.children.insert(idx,node);
                        node.hierarchyParent = theNodeToAddendum.hierarchyParent;
                    }
                case -1:
                    if(theNodeToAddendum.hierarchyParent == null){

                        deparentNode(node);

                        var idx = nodes.members.indexOf(theNodeToAddendum);
                        nodes.insert(idx,node);
                        LevelEditor.instance.layers.members[LevelEditor.instance.curLayer].insert(idx,node.objectReference);
                    }
                    else{

                        if(node.objectReference.isStatic && !theNodeToAddendum.hierarchyParent.objectReference.isStatic)

                        deparentNode(node);

                        final idx = theNodeToAddendum.hierarchyParent.children.indexOf(theNodeToAddendum);
                        theNodeToAddendum.hierarchyParent.objectReference.children.insert(idx,node.objectReference);
                        theNodeToAddendum.hierarchyParent.children.insert(idx,node);
                        node.hierarchyParent = theNodeToAddendum.hierarchyParent;
                    }
            }
        }
        else{
            if(node.objectReference.isStatic && !theNodeToAddendum.objectReference.isStatic) return;
            if(node.hierarchyParent != null){
                node.objectReference.parent.children.remove(node.objectReference,true);
                node.objectReference.parent = null;
                node.hierarchyParent.children.remove(node);
                node.hierarchyParent = null;
            }
            else{
                nodes.remove(node,true);
                LevelEditor.instance.layers.members[LevelEditor.instance.curLayer].remove(node.objectReference,true);
            }
            theNodeToAddendum.objectReference.children.add(node.objectReference);
            theNodeToAddendum.children.push(node);
            node.hierarchyParent = theNodeToAddendum;
            theNodeToAddendum.extended = theNodeToAddendum.objectReference.extended = true;
        }
    }

    function deparentNode(node:HierarchyNode){
        if(node.hierarchyParent != null){
            node.objectReference.parent.children.remove(node.objectReference,true);
            node.objectReference.parent = null;
            node.hierarchyParent.children.remove(node);
            node.hierarchyParent = null;
        }
        else{
            nodes.remove(node,true);
            LevelEditor.instance.layers.members[LevelEditor.instance.curLayer].remove(node.objectReference,true);
        }
    }
    
}