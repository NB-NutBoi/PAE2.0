package ui.premades;

import common.Mouse;
import flixel.FlxG;
import flixel.math.FlxPoint;
import utility.Utils;
import flixel.text.FlxText;
import flixel.FlxSprite;

class Quill extends FlxSprite {
    
    public var measureX:Float;
    public var measureY:Float;

    public var isRuler:Bool = false;
    public var onRuler:Void->Void = null;

    public var dragging:Bool;

    var coords:FlxText;

    override public function new(x:Float, y:Float) {
        super(x,y,"embed/debug/quill.png");

        measureX = x;
        measureY = y;

        x = x-(width*0.5);
        y = y-height;

        coords = new FlxText(x-3,y-17,0,"X: "+measureX+" | Y: "+(measureY-0.5),15);
        coords.font = "vcr";
        coords.antialiasing = true;
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        var localMousePos = FlxPoint.get(0,0);
        localMousePos = Utils.getMousePosInCamera(camera, localMousePos, this);

        if(!dragging){
            
            var over = overlapsPoint(localMousePos);

            if(over){
                if(FlxG.mouse.justPressed){
                    if(isRuler) onRuler();
                    else{
                        dragging = true;
                    }
                }
                else if(FlxG.mouse.justPressedRight){
                    if(!isRuler) onRuler();
                    else {
                        dragging = true;
                    }
                }   
            }
        }
        else {
            if(FlxG.mouse.justReleased || FlxG.mouse.justReleasedRight) dragging = false;
        }

        if(dragging) {
            Mouse.setAs(HAND);
            x = localMousePos.x-(width*0.5);
            y = localMousePos.y-(height*0.5);
        }

        localMousePos.put();

        measureX = x+(width*0.5);
        measureY = y+height;

        coords.setPosition(x-3,y-17);
        coords.text = "X: "+measureX+" | Y: "+(measureY-0.5);
    }

    override function draw() {
        super.draw();
        coords.draw();
    }

    override function destroy() {
        super.destroy();
        coords.destroy();

        onRuler = null;
    }

}