package ui.elements;

import ui.base.Container;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.math.FlxPoint;
import utility.Utils;
import flixel.util.FlxArrayUtil;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxG;
import flixel.FlxObject;

//thanks mario & luigi dream team for keeping me alive https://youtu.be/OwpQEfoqYgk :praise:

//it's a bit more different than other elements, rather than staying once created, this appears as a list of choices and gets destroyed once selected or mouse stops hovering.
@:allow(ui.elements.BasicContextOption, ui.elements.CollapsableContextOption)
class Context extends StackableObject {
    public static var instance:Context;

    static final SELECTED:Int = 0xFF303030;
    static final BACKGROUND:Int = 0xFF141414;
    
    private static var mousePos:FlxPoint;
    private static var requestedDestroy:Bool = false;

    var options:FlxTypedGroup<ContextOption>;

    var box:FlxSprite;
    public var selectBox:FlxSprite;

    public static function create(options:Array<ContextOption>) {
        if(instance != null){
            for (option in options) {
                option.destroy();
            }

            FlxArrayUtil.clearArray(options);
            options = null;

            return;
        }

        if(options.length == 0) return;

        var c = new Context(options);
        instance = c;
    }

    private function new(_options:Array<ContextOption>) {
        var mousePos = FlxPoint.get(0,0);
        Utils.getMousePosInCamera(FlxGamePlus.OverlayCam, mousePos);
        super(mousePos.x - 5, mousePos.y - 5);
        mousePos.put();

        requestedDestroy = false;

        combinedHeight = height;
        combinedWidth = width;

        options = new FlxTypedGroup();
        options.camera = FlxGamePlus.OverlayCam;

        for (option in _options) {
            option.setPosition(x, y+combinedHeight);
            combinedHeight += option.combinedHeight;
            if(option.combinedWidth > combinedWidth) combinedWidth = option.combinedWidth;
            options.add(option);
        }

        for (option in options) { //set for multiselect.
            option.combinedWidth = combinedWidth;
        }

        box = Utils.makeRamFriendlyRect(x,y,Std.int(combinedWidth),Std.int(combinedHeight)); box.camera = FlxGamePlus.OverlayCam; box.color = BACKGROUND;
        selectBox = Utils.makeRamFriendlyRect(x,y,Std.int(combinedWidth),Std.int(_options[0].combinedHeight)); selectBox.camera = FlxGamePlus.OverlayCam; selectBox.color = SELECTED;

        for (option in options) {
            option.onAdd();
        }

        _options = null;

        Container.contextActive = true;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    override function update(elapsed:Float) {
        super.update(elapsed);

        mousePos = FlxPoint.get(0,0);
        Utils.getMousePosInCamera(FlxGamePlus.OverlayCam, mousePos);

        if((!FlxMath.pointInCoordinates(mousePos.x, mousePos.y, x,y, combinedWidth, combinedHeight) && !overlapsAny()) || requestedDestroy){
            mousePos.put();
            mousePos = null;

            destroy();
            return;
        }

        //--------------------------------------------------------------

        options.update(elapsed);

        //--------------------------------------------------------------

        mousePos.put();
        mousePos = null;
    }

    public function overlapsAny():Bool {
        var result = false;
        for (option in options) {
            result = result || option.over();
        }

        return result;
    }

    override function draw() {
        super.draw();

        box.draw();
        for (option in options) {
            option.preDraw();
        }
        selectBox.draw();
        options.draw();
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    override function destroy() {

        instance = null;

        options.destroy();
        options = null;

        box.destroy();
        box = null;

        selectBox.destroy();
        selectBox = null;

        Container.contextActive = false;

        super.destroy();
    }

}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

class ContextOption extends StackableObject {

    public var label:FlxText;

    public function onAdd() {
        
    }

    public function preDraw() {
        
    }
    
    public function over():Bool {
        return false;
    }

}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

class BasicContextOption extends ContextOption {

    public var callback:Void->Void;
    
    public function new(name:String, _callback:Void->Void) {

        super(0,0);

        callback = _callback;
        
        label = new FlxText(0,0,0,name,20);
        label.font = "vcr";
        label.antialiasing = true;

        combinedHeight = height = label.height;
        combinedWidth = width = label.width;
    }

    override function destroy() {

        callback = null;

        label.destroy();
        label = null;

        super.destroy();
    }

    override function onAdd() {
        label.setPosition(x,y);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    override function update(elapsed:Float) {
        super.update(elapsed);

        label.setPosition(x,y);

        if(FlxMath.pointInCoordinates(Context.mousePos.x, Context.mousePos.y, x,y, combinedWidth, combinedHeight)){
            Context.instance.selectBox.setGraphicSize(Std.int(combinedWidth), Std.int(combinedHeight));
            Context.instance.selectBox.updateHitbox();
            Context.instance.selectBox.setPosition(x,y);
            if(FlxG.mouse.justPressed) press();
        }
    }

    override function draw() {
        super.draw();

        label.draw();
    }

    function press() {
        if(callback != null) callback();
        Context.requestedDestroy = true;
    }

}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

class CollapsableContextOption extends ContextOption {
    
    public var secondMenuSprite:FlxSprite;
    public var secondMenuObject:StackableObject;
    public var secondMenu:FlxTypedGroup<ContextOption>;

    public var extended:Bool = false;

    public function new(name:String, options:Array<ContextOption>) {
        super(0,0);

        label = new FlxText(0,0,0,name+"   >",20);
        label.font = "vcr";
        label.antialiasing = true;

        combinedHeight = height = label.height;
        combinedWidth = width = label.width;

        //----------------------------------------------

        secondMenu = new FlxTypedGroup();
        secondMenuObject = new StackableObject(0,0);

        secondMenuObject.combinedHeight = 0;
        secondMenuObject.combinedWidth = 0;

        for (option in options) {
            secondMenu.add(option);
        }
        
    }

    override function destroy() {

        label.destroy();
        label = null;

        secondMenu.destroy();
        secondMenu = null;

        secondMenuObject.destroy();
        secondMenuObject = null;

        super.destroy();
    }

    override function onAdd() {
        label.setPosition(x,y);

        for (option in secondMenu) {
            option.setPosition(x+combinedWidth, y+secondMenuObject.combinedHeight);
            secondMenuObject.combinedHeight += option.combinedHeight;
            if(option.combinedWidth > secondMenuObject.combinedWidth) secondMenuObject.combinedWidth = option.combinedWidth;
        }

        for (option in secondMenu) { //set for multiselect.
            option.combinedWidth = secondMenuObject.combinedWidth;
        }

        secondMenuSprite = Utils.makeRamFriendlyRect(x,y,Std.int(secondMenuObject.combinedWidth),Std.int(secondMenuObject.combinedHeight)); secondMenuSprite.color = Context.BACKGROUND;

        secondMenuSprite.setPosition(x+combinedWidth,y);

        for (option in secondMenu) {
            option.onAdd();
        }
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    override function update(elapsed:Float) {
        super.update(elapsed);

        label.setPosition(x,y);

        if(FlxMath.pointInCoordinates(Context.mousePos.x, Context.mousePos.y, x,y, combinedWidth, combinedHeight)){
            Context.instance.selectBox.setGraphicSize(Std.int(combinedWidth), Std.int(combinedHeight));
            Context.instance.selectBox.updateHitbox();
            Context.instance.selectBox.setPosition(x,y);
            if(FlxG.mouse.justPressed) extended = !extended;
        }

        if(extended){
            secondMenu.update(elapsed);
        }
    }

    override function preDraw() {
        if(extended) {
            secondMenuSprite.draw();
            for (option in secondMenu) {
                option.preDraw();
            }
        }
    }

    override function draw() {
        super.draw();

        if(extended){
            
            if(Context.instance.selectBox.x != x || Context.instance.selectBox.y != y){
                final prevX=Context.instance.selectBox.x;
                final prevY=Context.instance.selectBox.y;
                final prevW=Std.int(Context.instance.selectBox.width);
                final prevH=Std.int(Context.instance.selectBox.height);

                Context.instance.selectBox.setGraphicSize(Std.int(combinedWidth), Std.int(combinedHeight));
                Context.instance.selectBox.updateHitbox();
                Context.instance.selectBox.setPosition(x,y);
                Context.instance.selectBox.draw();

                Context.instance.selectBox.setGraphicSize(prevW, prevH);
                Context.instance.selectBox.updateHitbox();
                Context.instance.selectBox.setPosition(prevX,prevY);
            }

            secondMenu.draw();
        }

        label.draw();
    }

    override function over():Bool {
        if(extended){
            if(FlxMath.pointInCoordinates(Context.mousePos.x, Context.mousePos.y, x+combinedWidth,y, secondMenuObject.combinedWidth, secondMenuObject.combinedHeight)) return true;
            return overlapsAny();
        }
        return false; //we can always return false since we know it's already out of bounds if it's called.
    }

    function overlapsAny() {
        var result = false;
        for (option in secondMenu) {
            result = result || option.over();
        }

        return result;
    }
}

