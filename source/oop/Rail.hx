package oop;

import levels.Level;
import flixel.FlxBasic;

//TODO
//find a use for this and actually finish it -nut

class Rail extends FlxBasic {

    public var name:String;

    public var startNode:RailNode;
    public var endNode:RailNode;

    public var length(get,never):Int;
    public var nodes:Array<RailNode>;

    override public function new(instance:RailStructure) {
        super();

        name = instance.name;

        startNode = new RailNode(instance.startNode);

        var end = startNode;
        nodes.push(end);
        while(end.next != null){
            end = end.next;
            nodes.push(end);
        }
    }

    function get_length():Int {
        return nodes.length;
    }

}

class RailNode {

    public var x:Float;
    public var y:Float;

    public var speedMul:Float;

    public var previous:Null<RailNode>;
    public var next:Null<RailNode>;
    
    public function new(instance:RailNodeStructure, ?prev:RailNode = null) {

        previous = prev;

        x = instance.x;
        y = instance.y;

        speedMul = instance.speedMul;

        next = instance.nextNode == null ? null : new RailNode(instance.nextNode, this);
    }

}