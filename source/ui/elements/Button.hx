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
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import ui.base.Container;
import ui.base.ContainerObject;
import utility.Utils;

class Button extends StackableObject implements ContainerObject{
    static final IDLE:Int = 0xFF303030;
    static final HOVER:Int = 0xFF414141;
    static final DISABLED:Int = 0xFF141414;

    var box:FlxSprite;
    var label:FlxText;
    var callback:Void->Void;
	public var parent:Null<Container> = null;

    public var over:Bool = false;
    public var disabled:Bool = false;

    override public function new(x:Float, y:Float, width:Int, height:Int, label:String, callback:Void->Void) {
        super(x,y);

        this.callback = callback;

        box = Utils.makeRamFriendlyRect(x,y,width,height,FlxColor.WHITE);
        super.height = combinedHeight = height;

        this.label = new FlxText(x,y,label, Std.int(height * 0.65));
        this.label.font = "vcr";
        this.label.antialiasing = true;
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        if(box.width-label.width < 0){
            box.setGraphicSize(Std.int(label.width+10),Math.ceil(box.height));
            box.updateHitbox();
        }

        label.setPosition(x+((box.width*0.5)-(label.width*0.5)-1),y+((box.height*0.5)-(label.height*0.5)-1.5));
        box.setPosition(x,y);

        over = false;
    }

    public function updateInputs(elapsed:Float) {
        if(disabled) return;
        var localMousePos = FlxPoint.get(0,0);
        localMousePos = Utils.getMousePosInCamera(parent == null ? camera : parent.cam, localMousePos, box);

        over = box.overlapsPoint(localMousePos);

        if(over && FlxG.mouse.justPressed){
            callback();
        }

        localMousePos.put();
    }

    public function postUpdate(elapsed:Float) {
        if(disabled){
            box.color = DISABLED;
            label.color = HOVER;
            return;
        }

        label.color = 0xFFFFFFFF;

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
        label.draw();
    }

    override function setScrollFactor(x:Float = 0, y:Float = 0) {
        super.setScrollFactor(x, y);
        box.scrollFactor.set(x,y);
        label.scrollFactor.set(x,y);
    }

    override function destroy() {
        box.destroy();
        label.destroy();
        super.destroy();
    }
    
}