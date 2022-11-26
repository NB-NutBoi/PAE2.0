package ui.premades;

import leveleditor.LayerVisualizer;
import leveleditor.ObjectVisualizer;
import flixel.group.FlxGroup.FlxTypedGroup;
import ui.premades.hierarchy.HierarchyNode;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;

//how the fuck do i handle this
//store a reference to the object and check every frame if the object's been deleted?
class Hierarchy extends DMenu {

    static final nodesBaseY:Float = 0;
    var hierarchyCombinedHeight:Float = 0;

    public var nodes:FlxTypedGroup<HierarchyNode>;

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //creating/destroying

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

        elapsed_UpdateNode = elapsed;
        nodes.forEach(updateNode);
    }

    var elapsed_UpdateNode:Float = 0;

    function updateNode(node:HierarchyNode) {
        node.setPosition(20/*temp x*/, nodesBaseY + hierarchyCombinedHeight);
        node.update(elapsed_UpdateNode);
        hierarchyCombinedHeight += node.combinedHeight;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //node management

    function clearNodes() {
        nodes.destroy();
        nodes = new FlxTypedGroup();
    }

    function createNode(object:ObjectVisualizer):HierarchyNode {
        var node = new HierarchyNode(0,0);
        node.setReference(object);

        for (childObject in object.children) {
            var child = createNode(childObject);
            node.children.push(child);
        }

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

        var node = createNode(object);

        correctNode.children.push(node);
    }

    public function switchLayerTo(layer:LayerVisualizer) {
        clearNodes();

        for (object in layer) {
            var node = createNode(object);
            nodes.add(node);
        }
    }
    
}