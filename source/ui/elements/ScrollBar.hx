package ui.elements;

import ui.elements.ColorPicker;
import common.Mouse;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import lime.ui.MouseCursor;
import ui.base.Container;
import ui.base.ContainerObject;
import utility.Utils;

enum ScrollDirection {
    VERTICAL;
    HORIZONTAL;
}

class ScrollBar extends StackableObject implements ContainerObject {
    static final IDLE:Int = 0xFF3A3A3A;
    static final HOVER:Int = 0xFF4B4B4B;
    static final BACKGROUND:Int = 0xFF292929;
    
    public var onScroll:Float->Void; //every frame that it's scrolling.
    public var onDrop:Float->Void; //when you drop scrolling.
	public var parent:Null<Container>;

    public var min:Float = 0;
    public var max:Float = 1;
    public var step:Float = 0.1;

    var direction:ScrollDirection;
    public var invertValue(default,set):Bool = false;

    var box:FlxSprite;
    var bg:FlxSprite;

    public var over:Bool = false;
    public var dragging:Bool = false;
    public var value:Float = 0;

    override public function new(x:Float, y:Float, width:Int, height:Int, style:ScrollDirection, ?scrollerSize:Int = 10) {
        super(x,y);

        direction = style;

        bg = Utils.makeRamFriendlyRect(x,y,width,height);
        bg.color = BACKGROUND;
        box = Utils.makeRamFriendlyRect(x,y,direction == HORIZONTAL ? scrollerSize : width ,direction == VERTICAL ? scrollerSize : height );

        super.height = combinedHeight = height;
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        bg.setPosition(x,y);

        if(dragging && FlxG.mouse.justReleased) { dragging = false; if(onDrop != null) onDrop(value); }
        over = false;
    }

	public function updateInputs(elapsed:Float) {
        if(ColorWheel.instance != null || Container.dropdownActive) return;
        var localMousePos = FlxPoint.get(0,0);
        localMousePos = Utils.getMousePosInCamera(parent == null ? camera : parent.cam, localMousePos, box);

        over = box.overlapsPoint(localMousePos);

        if(over){
            if(!dragging && FlxG.mouse.justPressed) dragging = true;
        }

        localMousePos.put();
    }

	public function postUpdate(elapsed:Float) {
        if(over || dragging){
            if(direction == VERTICAL) Mouse.setAs(MouseCursor.RESIZE_NS); else Mouse.setAs(MouseCursor.RESIZE_WE);
            box.color = HOVER;
        }
        else{
            box.color = IDLE;
        }

        if(dragging){

            var localMousePos = FlxPoint.get(0,0);
            localMousePos = Utils.getMousePosInCamera(parent == null ? camera : parent.cam, localMousePos, box);

            switch (direction){
                case HORIZONTAL:
                    if(step == 0) box.x = (localMousePos.x-(box.width*0.5));
                    else{
                        final stepLength = ((bg.width-box.width) / ((Math.abs(min)+Math.abs(max)) / step));
                        final steps = Math.round(((localMousePos.x-(box.width*0.5))-bg.x)/stepLength);
                        if(steps >= 0) box.x = bg.x + (stepLength*steps);
                    }

                    if(box.x > (bg.x+bg.width-box.width)) box.x = (bg.x+bg.width-box.width);
                    if(box.x < bg.x) box.x = bg.x;
                case VERTICAL:
                    if(step == 0) box.y = (localMousePos.y-(box.height*0.5));
                    else{
                        final stepLength = ((bg.height-box.height) / ((Math.abs(min)+Math.abs(max)) / step));
                        final steps = Math.round(((localMousePos.y-(box.height*0.5))-bg.y)/stepLength);
                        if(steps >= 0) box.y = bg.y + (stepLength*steps);
                    }

                    if(box.y > (bg.y+bg.height-box.height)) box.y = (bg.y+bg.height-box.height);
                    if(box.y < bg.y) box.y = bg.y;
            }

            calcValue();

            if(onScroll != null) onScroll(value);

            localMousePos.put();
        }
    }

    override function draw() {
        super.draw();

        bg.draw();
        box.draw();
    }

    override function destroy() {
        box.destroy();
        bg.destroy();
        super.destroy();
    }


    function calcValue() {
        //val = ((percent * (max - min) / maxPercent) + min)

        final usableWidth = (direction == HORIZONTAL ? (bg.width-box.width) : (bg.height-box.height));
        final remainingWidth = usableWidth - (direction == HORIZONTAL ? box.x-bg.x : box.y-bg.y);
        final percent = remainingWidth / usableWidth;

        value = doInvert(((percent * (max - min) / 1) + min));
    }

    function doInvert(f:Float, ?inInvert:Bool = false):Float {
        if(invertValue == inInvert) return f;
        
        final middle = (min + max)*0.5;
        final diff = f-middle;
        return middle-diff;
    }

    public function setValue(inValue:Float) {
        if(inValue > max) inValue = max;
        if(inValue < min) inValue = min;

        value = inValue;

        final percentage = ((doInvert(value,true) - min) * 1) / (max - min);
        final usableWidth = (direction == HORIZONTAL ? (bg.width-box.width) : (bg.height-box.height));

        if(direction == HORIZONTAL)
            box.x = bg.x + usableWidth*percentage;
        else 
            box.y = bg.y + usableWidth*percentage;
    }
    

	function set_invertValue(value:Bool):Bool {
        invertValue = value;
        calcValue();
		return invertValue;
	}

    override function setPosition(X:Float = 0, Y:Float = 0) {
        super.setPosition(X, Y);

        final diffX = X - bg.x;
        final diffY = Y - bg.y;
        bg.setPosition(x,y);

        switch (direction){
            case HORIZONTAL:
                box.y = bg.y;
                box.x += diffX;
            case VERTICAL:
                box.x = bg.x;
                box.y += diffY;
        }
    }
}