package ui.elements;

import common.Mouse;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import ui.base.Container;
import ui.base.ContainerObject;
import utility.Utils;

class ContainerCloser extends FlxObject implements ContainerObject {

    public var parent:Null<Container>;
    
    static final IDLE:Int = 0xFFB41010;
    static final HOVER:Int = 0xFFF31818;

    var box:FlxSprite;
    static var box_X:FlxText; //no need to have multiple if they're all going to be the exact same, can just use one and move it to the correct positions on each draw call.

    var over:Bool = false;

    override public function new(x:Float,y:Float, owner:Container) {
        super(x,y);

        box = Utils.makeRamFriendlyRect(0,0,23,23,FlxColor.WHITE);
        box.color = IDLE;
        box.antialiasing = true;
        box.scrollFactor.set();

        if(box_X == null){
            box_X = new FlxText(0,0,0,"X",20);
            box_X.font = "vcr";
            box_X.antialiasing = true;
            box_X.scrollFactor.set();
        }

        owner.closer = this;
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        box.setPosition(x,y);

        over = false;
    }

    public function updateInputs(elapsed:Float) {
        var localMousePos = FlxPoint.get(0,0);
        localMousePos = Utils.getMousePosInCamera(parent == null ? camera : parent.cam, localMousePos, box);

        over = box.overlapsPoint(localMousePos);

        if(over && FlxG.mouse.justPressed){
            //CLOSE
            parent.close();
        }/*  */

        localMousePos.put();
    }

	public function postUpdate(elapsed:Float) {
        if(over){
            Mouse.setAs(BUTTON);
            box.color = HOVER;
            if(FlxG.mouse.justPressed){
                box.color = IDLE;
            }
        }
        else{
            box.color = IDLE;
        }
    }

    override function draw() {
        super.draw();

        box.draw();
        
        box_X.camera = camera;
        box_X.setPosition(x+2.5,y);
        box_X.draw();
    }

    override function destroy() {
        box.destroy();
        super.destroy();
    }

    override function set_camera(value:FlxCamera):FlxCamera {
        box.camera = value;
        //box_X.camera = value;
        
        return super.set_camera(value);
    }

    override function set_cameras(value:Array<FlxCamera>):Array<FlxCamera> {
        box.cameras = value;
        //box_X.cameras = value;

        return super.set_cameras(value);
    }

}