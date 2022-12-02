package leveleditor;

class TransformVisualizer {

    public var owner:GenericObjectVisualizer;

    //----------------------------------------

    public var internalX:Float;
    public var internalY:Float;

    public var x:Float;
    public var y:Float;

    public var z:Int; //is z really required at this point? we can just move the order of objects around in the editor lol

    public var internalAngle:Float;
    public var angle:Float;

    public function new(owner:GenericObjectVisualizer) {
        this.owner = owner;
    }

    public function destroy() {
        owner = null;
    }

    //--------------------------------------------------------------------------------

    public function update(elapsed:Float) {
        if(owner.parent != null){
            internalX = x + owner.parent.transform.internalX;
            internalY = y + owner.parent.transform.internalY;
            internalAngle = angle + owner.parent.transform.internalAngle;
        }
        else {
            internalX = x;
            internalY = y;
            internalAngle = angle;
        }
    }
    
    //--------------------------------------------------------------------------------

    

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

    public function setVisualAngle(A:Float):Float {
		if(owner.parent != null) return angle = A-owner.parent.transform.internalAngle;
        return angle = A;
	}
}