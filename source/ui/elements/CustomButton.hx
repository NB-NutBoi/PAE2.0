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

class CustomButton extends FlxObject implements ContainerObject{
    static final IDLE:Int = 0xFF303030;
    static final HOVER:Int = 0xFF414141;

    var box:FlxSprite;
    public var content:Array<FlxObject> = [];
    var callback:Void->Void;
	public var parent:Null<Container> = null;

    public var over:Bool = false;

    override public function new(x:Float, y:Float, width:Int, height:Int, callback:Void->Void) {
        super(x,y);

        this.callback = callback;

        box = Utils.makeRamFriendlyRect(x,y,width,height,FlxColor.WHITE);

    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        for (object in content) {
            object.update(elapsed);
        }
        box.setPosition(x,y);

        over = false;
    }

    public function updateInputs(elapsed:Float) {
        var localMousePos = FlxPoint.get(0,0);
        localMousePos = Utils.getMousePosInCamera(parent == null ? camera : parent.cam, localMousePos, box);

        over = box.overlapsPoint(localMousePos);

        if(over && FlxG.mouse.justPressed){
            callback();
        }

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
        for (object in content) {
            final ogX = object.x;
            final ogY = object.y;
            object.x = box.x + ogX;
            object.y = box.y + ogY;
            object.draw();
            object.x = ogX;
            object.y = ogY;
        }
    }

    override function destroy() {
        box.destroy();
        content.resize(0);
        content = null;
        super.destroy();
    }
    
}