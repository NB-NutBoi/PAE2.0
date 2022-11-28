package leveleditor;

class TransformVisualizer {

    public var owner:ObjectVisualizer;

    //----------------------------------------

    public var internalX:Float;
    public var internalY:Float;

    @:isVar public var x(get,set):Float;
    @:isVar public var y(get,set):Float;
    public var localX:Float;
    public var localY:Float;

    public var z:Int;

    public var internalAngle:Float;

    public var angle(default,set):Float;

    public function new(owner:ObjectVisualizer) {
        this.owner = owner;
    }

    public function destroy() {
        owner = null;
    }

    //--------------------------------------------------------------------------------

    public function update(elapsed:Float) {
        if(owner.parent != null){
            internalX = localX + owner.parent.transform.internalX;
            internalY = localY + owner.parent.transform.internalY;
            internalAngle = angle + owner.parent.transform.internalAngle;
        }
        else {
            internalX = x;
            internalY = y;
            internalAngle = angle;
        }
    }
    
    //--------------------------------------------------------------------------------

	function set_x(value:Float):Float {
        if(owner.parent != null) return localX = value;
		return x = value;
	}

	function set_y(value:Float):Float {
		if(owner.parent != null) return localY = value;
		return y = value;
	}

	function get_x():Float {
		if(owner.parent != null) return localX;
		return x;
	}

	function get_y():Float {
		if(owner.parent != null) return localY;
		return y;
	}

    function set_angle(value:Float):Float {
		if(owner.parent != null) return angle = value-owner.parent.transform.internalAngle;
        return angle = value;
	}

    //--------------------------------------------------------------------------------

    public function setVisualPosition(X:Float, Y:Float) {
        if(owner.parent != null){
            x = X-owner.parent.transform.internalX;
            y = Y-owner.parent.transform.internalY;
        }
        else{
            x = X;
            y = Y;
        }
    }
}