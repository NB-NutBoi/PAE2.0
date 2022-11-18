package ui.premades;

import flixel.util.FlxColor;
import flixel.math.FlxPoint;
import lowlevel.Ruler;
import flixel.FlxBasic;

class MeasuringTool extends FlxBasic{
    
    var mainQuill:Quill;
    var secondQuill:Quill;

    var measuringDistance:Bool = false;

    override public function new(x:Float, y:Float) {
        super();
        mainQuill = new Quill(x,y);
        secondQuill = new Quill(x,y);

        mainQuill.onRuler = onTryMeasure;
        secondQuill.isRuler = true;
        secondQuill.onRuler = onStopMeasure;

        secondQuill.color = 0xFFA0B7E0;
    }

    override function update(elapsed:Float) {
        super.update(elapsed);
        mainQuill.update(elapsed);
        if(measuringDistance) secondQuill.update(elapsed);
    }

    override function draw() {
        super.draw();
        mainQuill.draw();
        if(measuringDistance) {
            secondQuill.draw();
            Ruler.measure(FlxPoint.weak(mainQuill.measureX,mainQuill.measureY),FlxPoint.weak(secondQuill.measureX,secondQuill.measureY), 0xFF71ACD6);
        }
    }

    function onTryMeasure() {
        measuringDistance = true;
        secondQuill.dragging = true;
        secondQuill.setPosition(mainQuill.x,mainQuill.y);
    }

    function onStopMeasure() {
        measuringDistance = false;
        secondQuill.dragging = false;
    }
    
    override function destroy() {
        super.destroy();
        mainQuill.destroy();
        secondQuill.destroy();
    }

}