package oop;

import oop.GenericObject;
import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.math.FlxVector;
import flixel.text.FlxText;
import utility.Utils;

typedef TransformCache = {
    var x:Float;
    var y:Float;
    var xAccel:Float;
    var yAccel:Float;

    var pps:Bool;

    var angle:Float;
    var angularVel:Float;
}

@:allow(oop.GenericObject)
//everything is 2d so why bother with 3d stuff
class Transform extends FlxBasic{

    private var owner:GenericObject;
    
    public var internalPosition(default, null):FlxVector;
    public var position(default, null):FlxVector;

    public var z:Int = 0; //Layering stuff. (DEPRECATED)



    /**
     * changes the system to use pixels per second rather than pixels per frame.
     */
    public var usePixelsPerSecond:Bool = false;

    public var velocity(default, null):FlxVector;
    public var angularVelocity:Float;



    public var internalAngle:Float;
    public var angle:Float;

    public var name(get,set):String;

    //debug-------------------------------------
    public var drawDebug(null,set):Bool;
    private var _drawDebug:Bool = false;
    private var debugTransform:FlxText = null;
    private var debugAxle:FlxSprite = null;


    override public function new(own:GenericObject, ?x:Float = 0, ?y:Float = 0) {
        super();

        owner = own;

        internalAngle = 0;
        angle = 0;

        position = new FlxVector(x,y);
        internalPosition = new FlxVector(0,0);

        velocity = new FlxVector(0,0);
    }

    override function destroy() {
        owner = null;

        position.destroy();
        internalPosition.destroy();

        velocity.destroy();

        super.destroy();
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    override function update(elapsed:Float) {
        super.update(elapsed);

        if(owner.parent != null){
            usePixelsPerSecond ? position.add(velocity.x*elapsed, velocity.y*elapsed) : position.add(velocity.x, velocity.y);
            internalPosition.set(owner.parent.transform.internalPosition.x + position.x, owner.parent.transform.internalPosition.y + position.y);

            angle += usePixelsPerSecond ? angularVelocity*elapsed : angularVelocity;
            internalAngle = angle + owner.parent.transform.internalAngle;

            internalAngle = internalAngle % 359;
        }
        else{
            usePixelsPerSecond ? position.add(velocity.x*elapsed, velocity.y*elapsed) : position.add(velocity.x, velocity.y);
            internalPosition.set(position.x,position.y);

            angle += usePixelsPerSecond ? angularVelocity*elapsed : angularVelocity;
            angle = angle % 359;
            
            internalAngle = angle;
        }

        Utils.clampPoint(internalPosition, -10000,10000, -10000,10000); //the ram guzzling machine has been stopped

        
        angle = angle % 359;
        internalAngle = internalAngle % 359;

        if(_drawDebug && Main.DEBUG){
            debugTransform.text = ("TRANSFORM NAME = "+name)+"\n"+
            ("LOCAL = X: " + position.x + " | Y: " + position.y + " | A: " + angle)+"\n"+
            ("INTERNAL = X: " + internalPosition.x + " | Y: " + internalPosition.y + " | A: " + internalAngle)+"\n\n"+
            ("VELOCITY = X: " + velocity.x + " | Y: " + velocity.y + " | A: " + angularVelocity);
            debugTransform.setPosition(internalPosition.x + 3, internalPosition.y + 3);
        }
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	function get_name():String {
		return owner.name;
	}

	function set_name(value:String):String {
		return owner.name = value;
	}

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

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

	function set_drawDebug(value:Bool):Bool {
        value = value && Main.DEBUG;
        var previousValue = _drawDebug;
        _drawDebug = value;

		if(value == true && previousValue == false && Main.DEBUG){
            debugTransform = new FlxText(0,0,0,"",14);
            debugTransform.font = "vcr";

            debugTransform.antialiasing = true;

            debugTransform.cameras = [FlxGamePlus.DebugCam];

            debugTransform.setPosition(internalPosition.x + 3, internalPosition.y + 3);
        }
        else if (value == false && previousValue == true ){
            debugTransform.destroy();
            debugTransform = null;
        }

        return _drawDebug;
	}
}