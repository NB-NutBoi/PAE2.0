package ui.elements;
//------------------------------------------------------------
//------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------|
/* This file is under protection and belongs to the PA: AUN project team.                                  |
 * You may learn from this code and / or modify the source code for redistribution with proper accrediting.|
 * -NUT                                                                                                    |
 *///                                                                                                      |
//---------------------------------------------------------------------------------------------------------|

import common.Mouse;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import ui.base.Container;
import ui.base.ContainerObject;
import utility.Utils;

class Checkbox extends StackableObject implements ContainerObject {

    static final IDLE:Int = 0xFF303030;
    static final HOVER:Int = 0xFF414141;
    static final DISABLED:Int = 0xFF141414;

    public var checked:Bool = false;
    var callback:Bool->Void;

    var box:FlxSprite;
    var tick:FlxSprite;
    var label:FlxText;
    
	public var parent:Null<Container>;
    public var over:Bool = false;
    public var disabled:Bool = false;

    override public function new(x:Float,y:Float,label:String,callback:Bool->Void) {
        super(x,y);

        box = new FlxSprite(0,0,"embed/ui/checkbox.png");
        box.color = IDLE;
        box.graphic.destroyOnNoUse = false;
        box.graphic.persist = true;
        
        tick = new FlxSprite(0,0,"embed/ui/tick.png");
        tick.antialiasing = true;
        tick.graphic.destroyOnNoUse = false;
        tick.graphic.persist = true;

        height = combinedHeight = box.height;

        if(label != null){
            this.label = new FlxText(0,0,label,17);
            this.label.font = "vcr";
            this.label.antialiasing = true;
        }

        if(callback != null){
            this.callback = callback;
        }
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        box.setPosition(x,y);
        tick.setPosition(x,y);
        if(label != null){
            label.setPosition(x+27,y+2);
        }
        
        over = false;
    }

    override function draw() {
        super.draw();

        box.draw();
        if(checked) tick.draw();
        if(label != null){
            label.draw();
        }
    }

    public function updateInputs(elapsed:Float) {
        if(disabled) return;
        var localMousePos = FlxPoint.get(0,0);
        localMousePos = Utils.getMousePosInCamera(parent == null ? camera : parent.cam, localMousePos, box);

        over = box.overlapsPoint(localMousePos);

        if(over && FlxG.mouse.justPressed && visible){
            checked = !checked;

            if(callback != null){
                callback(checked);
            }
        }

        localMousePos.put();
    }

	public function postUpdate(elapsed:Float) {
        if(disabled){
            box.color = DISABLED;
            if(label != null){
                label.color = HOVER;
            }
            return;
        }

        if(label != null){
            label.color = 0xFFFFFFFF;
        }
        
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

    override function destroy() {
        box.destroy();
        tick.destroy();
        if(label != null){
            label.destroy();
        }
        super.destroy();
    }

    override function set_camera(value:FlxCamera):FlxCamera {
        box.camera = value;
        tick.camera = value;
        if(label != null){
            label.camera = value;
        }
        
        return super.set_camera(value);
    }

    override function set_cameras(value:Array<FlxCamera>):Array<FlxCamera> {
        box.cameras = value;
        tick.cameras = value;
        if(label != null){
            label.cameras = value;
        }

        return super.set_cameras(value);
    }
}