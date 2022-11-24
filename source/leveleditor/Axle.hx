package leveleditor;

import flixel.FlxSprite;

enum AxleState {
    MOVE;
    SCALE;
    ROTATE;
}

class Axle {

    var state:AxleState = MOVE;

    var centerAxle:FlxSprite;

    var xMoveAxle:FlxSprite;
    var yMoveAxle:FlxSprite;

    var xScaleAxle:FlxSprite;
    var yScaleAxle:FlxSprite;

    var rotateAxle:FlxSprite;
    var rotateDirAxle:FlxSprite;

    public var angle:Float;
    public var onChangeAngle:Void->Void = null;

    public var x:Float;
    public var y:Float;
    public var onMove:Void->Void = null;

    public var onScale:Void->Void = null;

    public var visible:Bool = false;

    public function new() {
        centerAxle = new FlxSprite(0,0,"embed/ui/leveleditor/small_square.png");

        xMoveAxle = new FlxSprite(0,0,"embed/ui/leveleditor/arrow.png"); xMoveAxle.angle = -90;
        yMoveAxle = new FlxSprite(0,0,"embed/ui/leveleditor/arrow.png");


        xScaleAxle = new FlxSprite(0,0, "embed/ui/leveleditor/arrow_scale.png"); xScaleAxle.angle = -90;
        yScaleAxle = new FlxSprite(0,0, "embed/ui/leveleditor/arrow_scale.png");


        rotateAxle = new FlxSprite(0,0, "embed/ui/leveleditor/circle.png");
        rotateDirAxle = new FlxSprite(0,0, "embed/ui/leveleditor/circleLine.png");
    }

    public function update(elapsed:Float) {
        rotateDirAxle.angle = angle;

        switch (state){
            case MOVE:
            case SCALE:
            case ROTATE:
        }
    }

    public function draw() {
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
}