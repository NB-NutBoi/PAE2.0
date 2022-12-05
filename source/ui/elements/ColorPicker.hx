package ui.elements;

import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.util.FlxGradient;
import flixel.util.FlxSpriteUtil;
import openfl.display.BitmapData;
import common.Mouse;
import flixel.math.FlxPoint;
import utility.Utils;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import ui.base.Container;
import ui.base.ContainerObject;

class ColorPicker extends StackableObject implements ContainerObject {
    static final IDLE:Int = 0xFF303030;
    static final HOVER:Int = 0xFF414141;


	public var parent:Null<Container>;


    public var color:FlxColor;

    public var box:FlxSprite;
    public var colorBox:FlxSprite;

    public var over:Bool = false;
    public var extended:Bool = false;

    public var onUpdateColor:FlxColor->Void = null;

    override public function new(x:Float, y:Float, defaultColor:FlxColor) {
        super(x,y);

        color = defaultColor;

        box = Utils.makeRamFriendlyRect(x,y,30,30,IDLE);
        colorBox = Utils.makeRamFriendlyRect(x+2,y+2,26,26,color);

        height = combinedHeight = box.height;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    override function update(elapsed:Float) {

        if(ColorWheel.instance != null) { ColorWheel.instance.update(elapsed); parent.overlapped = true; }

        box.setPosition(x,y);
        colorBox.setPosition(x+2,y+2);

        colorBox.color = color;

        super.update(elapsed);

        over = false;
    }

	public function updateInputs(elapsed:Float) {
        if(extended) return;
        var localMousePos = FlxPoint.get(0,0);
        localMousePos = Utils.getMousePosInCamera(parent == null ? camera : parent.cam, localMousePos, box);

        over = box.overlapsPoint(localMousePos);

        if(over && FlxG.mouse.justPressed){
            localMousePos = Utils.getMousePosInCamera(FlxGamePlus.OverlayCam, localMousePos, box);
            ColorWheel.bringUp(this,localMousePos.x-10, localMousePos.y-10);
            extended = true;
            parent.exclusiveInputs = this;
        }

        localMousePos.put();
    }

	public function postUpdate(elapsed:Float) {
        box.color = over ? HOVER : IDLE;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    override function draw() {
        super.draw();

        box.draw();
        colorBox.draw();

        if(over) Mouse.setAs(BUTTON);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public function updateColor(to:FlxColor) {
        color = to;
        if(onUpdateColor != null) onUpdateColor(color);
    }
    
}

//color "wheel" brought up when clicked
class ColorWheel extends FlxObject {

    static final BG:Int = 0xFF242424;
    public static var instance:ColorWheel;
    
    public static function bringUp(owner:ColorPicker,x:Float,y:Float) {
        instance = new ColorWheel(owner,x,y);
    }

    var owner:ColorPicker;

    public var box:FlxSprite;
    public var colorBox:FlxSprite;

    public var pointer:FlxSprite;
    public static var primaryColorBox:FlxSprite;
    public static var primaryColorBoxBitmap:BitmapData;

    public static var secondaryColorBox:FlxSprite;
    public var caret:FlxSprite;

    //more color-specifics
    public var hue:Float = 0; //caret y | 0-359
    public var saturation:Float = 0; //pointer x | 0-100
    public var brightness:Float = 100; //pointer y | 0-100


    //misc
    var dragging:Int = -1;

    private function new(parent:ColorPicker,x:Float,y:Float) {
        super(x,y);

        owner = parent;

        hue = owner.color.hue;
        saturation = owner.color.saturation;
        brightness = owner.color.brightness;

        generatePrimaryBox();
        if(secondaryColorBox == null){
            var b = new BitmapData(26,360,false,0xFFFFFFFF);
            for (hue in 0...360) {
                var y = 359-hue;
                for (x in 0...26) {
                    b.setPixel(x,y,FlxColor.fromHSB(hue,1,1).to24Bit());
                }
            }

            secondaryColorBox = new FlxSprite(x+140,y+10,FlxGraphic.fromBitmapData(b,false,"_UNIQUE_SECONDCOLORPICKER_###"));
            secondaryColorBox.setGraphicSize(26,180);
            secondaryColorBox.updateHitbox();
            secondaryColorBox.camera = FlxGamePlus.OverlayCam;
        }

        box = Utils.makeRamFriendlyRect(x,y,200,200,BG);
        box.camera = FlxGamePlus.OverlayCam;

        colorBox = Utils.makeRamFriendlyRect(x+10,y+120,20,20,owner.color);
        colorBox.camera = FlxGamePlus.OverlayCam;

        caret = new FlxSprite(x+166,y+((359-hue)*secondaryColorBox.scale.y)+10-(7.5), "embed/ui/smallarrow.png");
        caret.angle = 90;
        caret.camera = FlxGamePlus.OverlayCam;

        pointer = new FlxSprite(x+10+(saturation*100)-7.5,y+10+(100-(brightness*100))-7.5, "embed/ui/smallcircle.png");
        pointer.camera = FlxGamePlus.OverlayCam;
        pointer.antialiasing = true;
    }

    override function destroy() {
        box.destroy();
        box = null;

        colorBox.destroy();
        colorBox = null;

        caret.destroy();
        caret = null;

        pointer.destroy();
        pointer = null;


        instance = null;
        owner.extended = false;
        owner.parent.exclusiveInputs = null;
        owner = null;

        super.destroy();
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        box.setPosition(x,y);
        colorBox.setPosition(x+10,y+120);
        primaryColorBox.setPosition(x+10,y+10);
        pointer.setPosition(x+10+((saturation*100)-7.5),y+10+((100-(brightness*100))-7.5));
        secondaryColorBox.setPosition(x+140,y+10);
        caret.setPosition(x+166,y+((359-hue)*secondaryColorBox.scale.y)+10-(7.5));

        var localMousePos = FlxPoint.get(0,0);
        localMousePos = Utils.getMousePosInCamera(FlxGamePlus.OverlayCam, localMousePos, box);
        
        if(!box.overlapsPoint(localMousePos)){
            destroy();
            return;
        }

        var over = -1;

        if(primaryColorBox.overlapsPoint(localMousePos)) over = 1;
        if(secondaryColorBox.overlapsPoint(localMousePos)) over = 2;

        switch (over){
            case 1: if(FlxG.mouse.justPressed) dragging = 1;
            case 2: if(FlxG.mouse.justPressed) dragging = 2;
        }

        if(FlxG.mouse.justReleased) dragging = -1;
        switch (dragging){
            case 1:
                var x = localMousePos.x-x-10;
                var y = localMousePos.y-y-10;

                x = Utils.clamp(x,0,100);
                y = Utils.clamp(y,0,100);

                saturation = x/100;
                brightness = (100-y)/100;
                onUpdateColor();
            case 2:
                final prevHue = hue;
                
                var y = 359-((localMousePos.y-y-10)/secondaryColorBox.scale.y);

                y = Utils.clamp(y,0,359);

                hue = y;
                if(hue != prevHue){
                    generatePrimaryBox();
                }
                onUpdateColor();
        }

        localMousePos.put();
    }

    override function draw() {
        super.draw();

        box.draw();
        colorBox.draw();
        primaryColorBox.draw();
        pointer.draw();
        secondaryColorBox.draw();
        caret.draw();
    }

    function generatePrimaryBox() {
        if(primaryColorBox == null){
            primaryColorBoxBitmap = new BitmapData(100,100,false,0xFFFFFFFF);
            primaryColorBox = new FlxSprite(x+10,y+10, FlxGraphic.fromBitmapData(primaryColorBoxBitmap,false,"_UNIQUE_PRIMARYCOLORPICKER_###"));
            primaryColorBox.camera = FlxGamePlus.OverlayCam;
        }

        primaryColorBoxBitmap.fillRect(primaryColorBoxBitmap.rect, 0xFFFFFFFF);

        //SATURATION

        FlxGradient.overlayGradientOnBitmapData(primaryColorBoxBitmap,100,100,[FlxColor.WHITE, FlxColor.fromHSB(hue,1,1)],0,0,1,0);
        FlxGradient.overlayGradientOnBitmapData(primaryColorBoxBitmap,100,100,[FlxColor.BLACK, FlxColor.TRANSPARENT],0,0,1,-90);
    }

    function onUpdateColor() {
        owner.updateColor(FlxColor.fromHSB(hue,saturation,brightness));
        colorBox.color = owner.color;
    }

}