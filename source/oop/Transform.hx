package oop;

import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.math.FlxVector;
import flixel.text.FlxText;
import utility.Utils;

@:allow(oop.Object)
//everything is 2d so why bother with 3d stuff
class Transform extends FlxBasic{

    private var owner:Object;
    
    public var position(get, null):FlxVector;
    public var localPosition(get, null):FlxVector;
    private var _position(default, null):FlxVector;
    private var _localPosition(default, null):FlxVector;

    public var z:Int = 0; //Layering stuff.

    /**
     * changes the system to use pixels per second rather than pixels per frame.
     */
    public var usePixelsPerSecond:Bool = false;
    public var velocity(default, null):FlxVector;
    public var angularVelocity:Float;

    public var localAngle:Float;
    public var angle:Float;

    public var name(get,set):String;

    //debug
    public var drawDebug(null,set):Bool;
    private var _drawDebug:Bool = false;
    private var debugTransform:FlxText = null;
    private var debugAxle:FlxSprite = null;


    override public function new(own:Object, ?x:Float = 0, ?y:Float = 0) {
        super();

        owner = own;

        localAngle = 0;
        angle = 0;

        _position = new FlxVector(x,y);
        _localPosition = new FlxVector(0,0);

        velocity = new FlxVector(0,0);
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        if(owner.parent != null){
            usePixelsPerSecond ? _localPosition.add(velocity.x*elapsed, velocity.y*elapsed) : _localPosition.add(velocity.x, velocity.y);
            Utils.clampPoint(_localPosition, -10000,10000, -10000,10000); //the ram guzzling machine has been stopped
            _position.set(owner.parent.transform._position.x + _localPosition.x, owner.parent.transform._position.y + _localPosition.y);
            localAngle += usePixelsPerSecond ? angularVelocity*elapsed : angularVelocity;
            localAngle = localAngle % 359;

            angle = localAngle + owner.parent.transform.localAngle;
        }
        else{
            usePixelsPerSecond ? _position.add(velocity.x*elapsed, velocity.y*elapsed) : _position.add(velocity.x, velocity.y);

            localAngle += usePixelsPerSecond ? angularVelocity*elapsed : angularVelocity;
            localAngle = localAngle % 359;
            
            angle = localAngle;
        }

        Utils.clampPoint(_position, -10000,10000, -10000,10000);

        
        angle = angle % 359;

        if(_drawDebug && Main.DEBUG){
            debugTransform.text = ("TRANSFORM NAME = "+name)+"\n"+
            ("GLOBAL = X: " + _position.x + " | Y: " + _position.y + " | A: " + angle)+"\n"+
            ("LOCAL  = X: " + _localPosition.x + " | Y: " + _localPosition.y + " | A: " + localAngle)+"\n\n"+
            ("VELOCITY = X: " + velocity.x + " | Y: " + velocity.y + " | A: " + angularVelocity);
            debugTransform.setPosition(_position.x + 3, _position.y + 3);
        }
    }

    override function destroy() {
        owner = null;

        _position.destroy();
        _localPosition.destroy();

        velocity.destroy();

        super.destroy();
    }

    function get_position():FlxVector {
        if(owner.parent != null) return _localPosition;
		return _position;
	}

	function get_localPosition():FlxVector {
        if(owner.parent == null) return _position;
		return _localPosition;
	}
    

	function get_name():String {
		return owner.name;
	}

	function set_name(value:String):String {
		return owner.name = value;
	}

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------

    //utility functions

    public function setPosition(x:Float = 0, y:Float = 0) {
        position.set(x,y);
    }

    public function setPosition_point(point:FlxPoint) {
        if(point == null) return;

        position.set(point.x,point.y);

        point.putWeak();
    }

    public function addPosition(x:Float = 0, y:Float = 0) {
        position.add(x,y);
    }

    public function addPosition_point(point:FlxPoint) {
        if(point == null) return;

        position.add(point.x, point.y);

        point.putWeak();
    }

    //doing .position already gets you the relevant coordinates for moving in the child-parent coordinate space, make sure this is global space.
    /**
     * Gets the x coordinate of the global screen position, unlike .position or .localPosition, that gets the relevant coordinates for moving in the child-parent coordinate space.
     * @return Accurate x coordinate of the screen-space position of this object.
     */
    public function getPosition_x():Float {
       return _position.x;
    }

    /**
     * Gets the y coordinate of the global screen position, unlike .position or .localPosition, that gets the relevant coordinates for moving in the child-parent coordinate space.
     * @return Accurate y coordinate of the screen-space position of this object.
     */
    public function getPosition_y():Float {
        return _position.y;
    }


    public function setAngle(angle:Float) {
        localAngle = angle;
    }

	function set_drawDebug(value:Bool):Bool {
        value = value && Main.DEBUG;
        var previousValue = _drawDebug;
        _drawDebug = value;

		if(value == true && previousValue == false && Main.DEBUG){
            debugTransform = new FlxText(0,0,0,"",14);
            debugTransform.font = "vcr";

            debugTransform.antialiasing = true;

            debugTransform.cameras = [FlxGamePlus.DebugCam];

            debugTransform.setPosition(_position.x + 3, _position.y + 3);
        }
        else if (value == false && previousValue == true ){
            debugTransform.destroy();
            debugTransform = null;
        }

        return _drawDebug;
	}
}