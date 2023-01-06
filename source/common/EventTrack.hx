package common;

class Track {
    
    var doesEnd:Bool = true;
    var doesRepeat:Bool = true;
    var over:Bool = true;

    public var toWait:Float = 0;

    public var nodes:Array<BaseTrackNode>;
    public var curNode:Int = 0;

    public function new(nodes:Array<BaseTrackNode>, ?ends:Bool = true, ?repeats:Bool = true) {
        this.nodes = nodes;
        doesEnd = ends;
        doesRepeat = repeats;
    }

    public function start() {
        over = false;
    }

    public function end() {
        over = true;
    }
    
    public function update(elapsed:Float) {
        if(over) return;

        if(toWait <= 0)
            if(nodes[curNode] == null){
                if(doesRepeat) curNode = 0;
                else if(doesEnd) end();
            } 
            else if(nodes[curNode].exec(this)) curNode++;
        else
            toWait -= elapsed;
    }

    //-------------------------------------------------------------------------------

    public function addNode(node:BaseTrackNode){
        nodes.push(node);
    }

    public function removeNode(node:BaseTrackNode) {
        nodes.remove(node);
        if(curNode >= nodes.length) curNode--;
        if(curNode < 0) curNode = 0;
    }
}

class BaseTrackNode {

    /**
     * EXECUTE THIS NODE
     * @param track the track this node was executed in
     * @return true if track should update node automatically, false if this node modifies it.
     */
    public function exec(track:Track):Bool { return true; }

    public function new() {}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

class WaitNode extends BaseTrackNode {

    var time:Float;
    
    override public function new(time:Float) {
        super();
        this.time = time;
    }

    override function exec(track:Track):Bool {
        track.toWait = time;
        return true;
    }
}

class WaitForNode extends BaseTrackNode {
    
    public var done:Bool = false;

    override function exec(track:Track):Bool {
        return done;
    }
}

class FunctionNode extends BaseTrackNode {
    
    var func:(FunctionNode, Track)->Void;

    override public function new(func:(FunctionNode, Track)->Void) {
        super();
        this.func = func;
    }

    override function exec(track:Track):Bool {
        if(func != null) func(this, track);
        return true;
    }

}

class SkipNode extends BaseTrackNode {
    
    var by:Int;

    override public function new(?by:Int = 1) {
        super();
        this.by = by;
    }

    override function exec(track:Track):Bool {
        track.curNode += 1+by;
        return false;
    }

}

class BiNode extends BaseTrackNode {

    //executes previous and next node and skips one ahead
    
    override function exec(track:Track):Bool {

        if(track.nodes[track.curNode-1] != null) track.nodes[track.curNode-1].exec(track);
        if(track.nodes[track.curNode+1] != null) track.nodes[track.curNode+1].exec(track);

        track.curNode += 2;
        return false;
    }
}

class GotoNode extends BaseTrackNode {

    //similar to skip node except this sets the position rather than offsetting it
    
    var to:Int = 0;

    override public function new(to:Int) {
        super();
        this.to = to;
    }

    override function exec(track:Track):Bool {
        track.curNode = to;
        if(track.curNode >= track.nodes.length) track.curNode = track.nodes.length-1;
        if(track.curNode < 0) track.curNode = 0;
        return false;
    }

}