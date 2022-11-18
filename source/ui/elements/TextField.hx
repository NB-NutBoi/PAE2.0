package ui.elements;

import common.Keyboard;
import common.Mouse;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.app.Event;
import lime.ui.KeyCode;
import ui.base.Container;
import ui.base.ContainerObject;
import utility.Utils;

using StringTools;

//this is shit and because of openfl i can't update scroll without updating text so it breaks very bad with values longer than the bar allows for, but oh well.
//THIS IS NOT FINISHED BUT WHO GIVES A SHIT
//oh yeah if it breaks with dconsole, disable the lines Lib.current.stage.focus = null; and Lib.current.stage.focus = txtPrompt;  
//not sure why this fixes it since it seemingly gets set to null every other second, but manually setting it breaks stuff for some reason???
//shitty workaround i know but not the first time i've had to tweak code on dconsole
class TextField extends FlxObject implements ContainerObject {
	public var parent:Null<Container>;

    static final IDLE:Int = 0xFF303030;
    static final HOVER:Int = 0xFF414141;
    

    public var over:Bool = false;
    public static var curSelected:Null<TextField> = null;

    public var box:FlxSprite;

    public var _caret:FlxSprite;
    private var caret:Int = 0;
    private var drawCaret:Bool = false;
    private var caretTimer:Float = 0;

    public var textField:FlxText;
    var lastScroll:Int = 0;
    var maxWidth:Int = 0;

    public var onPressEnter(default, null) = new Event<String->Void>();
	public var onType(default, null) = new Event<Void->Void>(); // don't pass every letter or every value, that sounds like a nightmare.

    override public function new(x:Float, y:Float, totalWidth:Int) {
        super(x,y);

        Keyboard.onUiTextInput.add(_type);
        Keyboard.onUiKeyDownUnfiltered.add(_onInput);

        maxWidth = totalWidth;

        box = Utils.makeRamFriendlyRect(0,0,totalWidth+4,27, FlxColor.WHITE);
        box.antialiasing = true;

        textField = new FlxText(0,0,maxWidth,"",18);
        textField.font = "vcr"; //i think i can get away with being cheap because this font has the exact same spacings across all characters
        //textField.clipRect = new FlxRect(0,0,totalWidth,textField.height);
        
        textField.textField.wordWrap = false;
		textField.textField.multiline = false;

        _caret = Utils.makeRamFriendlyRect(0,0,2, Std.int(textField.size + 2),FlxColor.WHITE);
        _caret.antialiasing = true;
        _caret.pixelPerfectRender = true;
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        if(caretTimer > 0){
            caretTimer -= elapsed;
            if(caretTimer <= 0) updateCaretTimer();
        }

        box.setPosition(x,y);
        textField.setPosition(x,y+4);

        over = false;
    }

	public function updateInputs(elapsed:Float) {
        var localMousePos = FlxPoint.get(0,0);
        localMousePos = Utils.getMousePosInCamera(parent == null ? camera : parent.cam, localMousePos, box);

        over = box.overlapsPoint(localMousePos);

        if(over && FlxG.mouse.justPressed){
            curSelected = this;
            localMousePos.x -= textField.textField.scrollH;
            getCaret(localMousePos);

            onUpdateText();
            drawCaret = true;
            caretTimer = 0.5;
        }

        localMousePos.put();
    }

    @:access(openfl.text.TextField, openfl.text._internal.TextEngine)
	public function postUpdate(elapsed:Float) {
        if(over){
            Mouse.setAs(IBEAM);
        }

        box.color = over ? HOVER : IDLE;

        if(curSelected != null){
            if(FlxG.mouse.justPressed && !over && !curSelected.over) curSelected = null;
            if(curSelected == this){
                
            }
        }
    }

    function updateCaretTimer() {
        if(curSelected != this) {drawCaret = false; return;}
        drawCaret = !drawCaret;
        caretTimer = 0.5;
    }

    @:access(flixel.text.FlxText, openfl.text.TextField, openfl.text._internal.TextEngine)
    function onUpdateText() {
        if(caret > textField.text.length) caret = textField.text.length;
        if(caret < 0) caret = 0;
        textField.textField.__caretIndex = caret;

        var caretX = (textField.x + 4 + (11 * caret));
        var diffW:Int = Std.int(caretX - maxWidth);
        if(diffW < 0) diffW = 0;
        textField.textField.scrollH = diffW;

        caretX -= textField.textField.scrollH; //this works for this font, somewhat surprisingly.
        _caret.setPosition(caretX ,textField.y);
    }

    @:access(openfl.text.TextField)
    override function draw() {
        super.draw();

        box.draw();

        
        //trace(textField.textField.__textEngine.textFormatRanges.length);
        //trace(textField.textField.scrollH);
        textField.draw();

       
        if(drawCaret) _caret.draw();
    }

    private function _type(what:String) {
        if(curSelected != this) return;

        var prevText = textField.text;
        textField.text = prevText.substr(0,caret) + what + prevText.substr(caret);
        caret += what.length;
        onUpdateText();
        onType.dispatch();
    }

    private function _onInput(key:KeyCode) {
        if(curSelected != this) return;

        switch (key){
            case BACKSPACE:
                if(caret > 0){
                    var prevText = textField.text;
                    textField.text = prevText.substr(0,caret-1)+prevText.substr(caret);
                    caret--;
                }
                onUpdateText();
            case LEFT:
                caret--;
                onUpdateText();
            case RIGHT:
                caret++;
                onUpdateText();
            case RETURN:
                onPressEnter.dispatch(textField.text);
            default:
                //idk
        }
    }

    private function getCaret(mousePos:FlxPoint) {
        var theX = mousePos.x - textField.x;
        var tempCaret = Math.round(theX / 11);
        if(tempCaret < 0) tempCaret = 0;
        if(tempCaret > textField.text.length) tempCaret = textField.text.length;
        caret = tempCaret;
    }

    override function destroy() {
        if(curSelected == this) curSelected = null;

        Keyboard.onUiTextInput.remove(_type);
        Keyboard.onUiKeyDownUnfiltered.remove(_onInput);

        box.destroy();
        textField.destroy();

        _caret.destroy();

        super.destroy();
    }

    override function set_camera(value:FlxCamera):FlxCamera {
        box.camera = value;
        textField.camera = value;
        _caret.camera = value;
        
        return super.set_camera(value);
    }

    override function set_cameras(value:Array<FlxCamera>):Array<FlxCamera> {
        box.cameras = value;
        textField.cameras = value;
        _caret.cameras = value;

        return super.set_cameras(value);
    }
    
}