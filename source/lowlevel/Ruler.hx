package lowlevel;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.shapes.FlxShapeLine;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import openfl.display.BitmapData;

//this fucking sucks but tell me a better way to draw lines
class Ruler extends FlxBasic {

    static var theRuler:Ruler;
    static var texts:Array<FlxText> = [];
    static var curText:Int = 0;

    public static function init() {
        FlxG.plugins.add(new Ruler());
    }

    public static function measure(from:FlxPoint, to:FlxPoint, color:FlxColor) {
        if(theRuler == null) init();
        
        from.subtractPoint(theRuler.camera.scroll);
        to.subtractPoint(theRuler.camera.scroll);
        FlxSpriteUtil.drawLine(theRuler._theLine, from.x, from.y, to.x, to.y, {thickness: 1, color: color});

        var distance = from.distanceTo(to);
        var text = null;

        if(texts[curText] == null){
            text = theRuler._makeText(Math.round(distance));
            text.camera = theRuler.camera;
            text.setPosition(from.x - ((from.x - to.x)*0.5),from.y - ((from.y - to.y)*0.5));
            text.color = color;

            texts.push(text);
        }
        else{
            text = texts[curText];
            text.text = Std.string(Math.round(distance));
            text.camera = theRuler.camera;
            text.setPosition(from.x - ((from.x - to.x)*0.5),from.y - ((from.y - to.y)*0.5));
            text.color = color;
        }

        curText++;

        text.draw();

        from.putWeak();
        to.putWeak();
        text = null;
    }

    @:allow(FlxGamePlus)
    private static function clear() {
        if(theRuler != null) theRuler._clear();
    }

    public static function _draw() {
        if(theRuler != null) theRuler.draw();
    }
    
    private var _theLine:FlxSprite;
    var bitmap:BitmapData;

    public function new() {
        super();

        theRuler = this;

        bitmap = new BitmapData(FlxG.width, FlxG.height, true, 0x00000000);
        var g = FlxGraphic.fromBitmapData(bitmap);
        g.destroyOnNoUse = false;
        g.persist = true;
        
        _theLine = new FlxSprite(0,0, g);
        _theLine.scrollFactor.set();

        camera = FlxGamePlus.DebugCam;
    }

    @:access(openfl.display.BitmapData)
    function _resize() {
        _theLine.setGraphicSize(FlxG.width, FlxG.height);
        bitmap.__resize(FlxG.width, FlxG.height);
        bitmap.image.resize(FlxG.width, FlxG.height);
    }

    function _clear() {
        for (i in curText...texts.length) {
            //remove unused this frame
            texts[i].destroy();
            texts.remove(texts[i]);
        }

        bitmap.fillRect(bitmap.rect, 0x00000000);
        curText = 0;
    }

    function _makeText(value:Int):FlxText {
        var t = new FlxText(0,0,0,Std.string(value),14);
        t.font = "vcr";
        t.antialiasing = true;
        t.scrollFactor.set();
        t.camera = camera;
        return t;
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        _theLine.update(elapsed);
    }

    override function draw() {
        if(_theLine.camera != camera) _theLine.camera = camera;
        _theLine.draw();
    }
    
    override function destroy() {
        theRuler = null;
        _theLine.destroy();
        super.destroy();
    }
}