package leveleditor;

import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import utility.Utils;
import flixel.FlxG;
import flixel.math.FlxPoint;
import flixel.FlxSprite;

enum AxleState {
    MOVE;
    SCALE;
    ROTATE;
}

class Axle {

    static final CENTER_IDLE:Int = FlxColor.fromString("#110DD9");
    static final CENTER_HOVER:Int = FlxColor.fromString("#1A1AF0");
    static final X_IDLE:Int = FlxColor.fromString("#DE1027");
    static final X_HOVER:Int = FlxColor.fromString("#F51D1D");
    static final Y_IDLE:Int = FlxColor.fromString("#14DE6B");
    static final Y_HOVER:Int = FlxColor.fromString("#23F543");
    static final ROTATE_IDLE:Int = 0xFF4DBEFF;
    static final ROTATE_HOVER:Int = 0xFF14A9FF;

    public var state:AxleState = MOVE;

    var centerAxle:FlxSprite;

    var xMoveAxle:FlxSprite;
    var yMoveAxle:FlxSprite;

    var xScaleAxle:FlxSprite;
    var yScaleAxle:FlxSprite;

    var rotateAxle:FlxSprite;
    var rotateDirAxle:FlxSprite;

    public var angle:Float = 0;
    public var onChangeAngle:Void->Void = null;

    public var x:Float;
    public var y:Float;
    public var nonVisualX:Float;
    public var nonVisualY:Float;
    public var onMove:Void->Void = null;

    public var onScale:Int->Void = null;

    public var visible:Bool = false;
    var dragging:Bool = false;
    var moving:Int = -1;

    public function new() {
        centerAxle = new FlxSprite(0,0,"embed/ui/leveleditor/small_square.png");

        xMoveAxle = new FlxSprite(0,0,"embed/ui/leveleditor/arrow.png"); xMoveAxle.angle = -90;
        yMoveAxle = new FlxSprite(0,0,"embed/ui/leveleditor/arrow.png");


        xScaleAxle = new FlxSprite(0,0, "embed/ui/leveleditor/arrow_scale.png"); xScaleAxle.angle = 90;
        yScaleAxle = new FlxSprite(0,0, "embed/ui/leveleditor/arrow_scale.png"); yScaleAxle.angle = 180;


        rotateAxle = new FlxSprite(0,0, "embed/ui/leveleditor/circle.png");
        rotateDirAxle = new FlxSprite(0,0, "embed/ui/leveleditor/circleLine.png");
    }

    public function update(elapsed:Float) {
        rotateDirAxle.angle = angle;

        if(!visible) return;

        var mousePos = FlxPoint.get(FlxG.mouse.x, FlxG.mouse.y);

        if(FlxG.mouse.justReleased) { dragging = false; moving = -1; nonVisualX = x; nonVisualY = y; }

        switch (state){
            case MOVE:

                xMoveAxle.y = y - (185*0.5);
                xMoveAxle.x = x - (185*0.575);

                yMoveAxle.y = y - 185;
                yMoveAxle.x = x - (32*0.5);

                centerAxle.x = x - (35*0.5);
                centerAxle.y = y - (35*0.5);

                xMoveAxle.update(elapsed);
                yMoveAxle.update(elapsed);
                centerAxle.update(elapsed);

                //------------------------------------

                var overlap = -1;

                if(moving == 0 || Utils.overlapsSprite(xMoveAxle,mousePos,true)){
                    overlap = 0;
                }

                if(moving == 1 || Utils.overlapsSprite(yMoveAxle,mousePos,true)){
                    overlap = 1;
                }

                if(moving == 2 || Utils.overlapsSprite(centerAxle,mousePos,true)){
                    overlap = 2;
                }

                centerAxle.color = CENTER_IDLE;
                xMoveAxle.color = X_IDLE;
                yMoveAxle.color = Y_IDLE;

                switch (overlap){
                    case 0: xMoveAxle.color = X_HOVER;
                    case 1: yMoveAxle.color = Y_HOVER;
                    case 2: centerAxle.color = CENTER_HOVER;
                }

                if(FlxG.mouse.justPressed && overlap > -1) {
                    dragging = true;
                    moving = overlap;
                }

                if(dragging){
                    switch (moving){
                        case 0:
                            x += FlxGamePlus.mouseMove[0];
                            nonVisualX += FlxGamePlus.mouseMove[0];
                            if(onMove != null) onMove();
                        case 1:
                            y += FlxGamePlus.mouseMove[1];
                            nonVisualY += FlxGamePlus.mouseMove[1];
                            if(onMove != null) onMove();
                        case 2:
                            x += FlxGamePlus.mouseMove[0];
                            y += FlxGamePlus.mouseMove[1];
                            nonVisualX += FlxGamePlus.mouseMove[0];
                            nonVisualY += FlxGamePlus.mouseMove[1];
                            if(onMove != null) onMove();
                        default:
                    }
                }
            case SCALE:

                xScaleAxle.y = y - (185*0.5);
                xScaleAxle.x = x + (185*0.425);

                yScaleAxle.y = y;
                yScaleAxle.x = x - (32*0.5);

                centerAxle.x = x - (35*0.5);
                centerAxle.y = y - (35*0.5);

                xScaleAxle.update(elapsed);
                yScaleAxle.update(elapsed);
                centerAxle.update(elapsed);

                //------------------------------------

                var overlap = -1;

                if(moving == 0 || Utils.overlapsSprite(xScaleAxle,mousePos,true)){
                    overlap = 0;
                }

                if(moving == 1 || Utils.overlapsSprite(yScaleAxle,mousePos,true)){
                    overlap = 1;
                }

                if(moving == 2 || Utils.overlapsSprite(centerAxle,mousePos,true)){
                    overlap = 2;
                }

                centerAxle.color = CENTER_IDLE;
                xScaleAxle.color = X_IDLE;
                yScaleAxle.color = Y_IDLE;

                switch (overlap){
                    case 0: xScaleAxle.color = X_HOVER;
                    case 1: yScaleAxle.color = Y_HOVER;
                    case 2: centerAxle.color = CENTER_HOVER;
                }

                if(FlxG.mouse.justPressed && overlap > -1) {
                    dragging = true;
                    moving = overlap;
                }

                if(dragging){
                    if(onScale != null) onScale(moving);
                }

            case ROTATE:

                rotateAxle.x = x - (185*0.5);
                rotateAxle.y = y - (185*0.5);

                rotateDirAxle.x = x - (185*0.5);
                rotateDirAxle.y = y - (185*0.5);

                rotateAxle.update(elapsed);
                rotateDirAxle.update(elapsed);

                //------------------------------------

                rotateDirAxle.color = X_IDLE;
                rotateAxle.color = ROTATE_IDLE;

                var overlap = false;

                if(moving == 0 || Utils.overlapsSprite(rotateAxle,mousePos,true)){
                    overlap = true;
                }

                if(overlap) rotateAxle.color = ROTATE_HOVER;

                if(FlxG.mouse.justPressed && overlap) {
                    dragging = true;
                    moving = 0;
                }

                if(dragging){
                    angle = FlxAngle.angleBetweenPoint(rotateDirAxle,mousePos,true)+90;
                    if(onChangeAngle != null) onChangeAngle();
                }
        }

        mousePos.put();
    }

    public function draw() {
        if(!visible) return;
        switch (state){
            case MOVE:
                xMoveAxle.draw();
                yMoveAxle.draw();
                centerAxle.draw();
            case SCALE:
                xScaleAxle.draw();
                yScaleAxle.draw();
                centerAxle.draw();
            case ROTATE:
                rotateDirAxle.draw();
                rotateAxle.draw();
        }
    }

    public function destroy() {
        centerAxle.destroy();

        xMoveAxle.destroy();
        yMoveAxle.destroy();

        xScaleAxle.destroy();
        yScaleAxle.destroy();

        rotateAxle.destroy();
        rotateDirAxle.destroy();


        onMove = null;
        onScale = null;
        onChangeAngle = null;
    }

    public function setPosition(X:Float, Y:Float) {
        nonVisualX = x = X;
        nonVisualY = y = Y;
    }
}