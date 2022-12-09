package leveleditor;

import oop.Object.StaticSpriteDataStructure;
import sys.FileSystem;
import oop.StaticObject;
import assets.ImageAsset;
import utility.Utils;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.FlxSprite;
import rendering.Sprite;

using StringTools;

class StaticObjectVisualizer extends GenericObjectVisualizer {

    //is a purely visual static sprite
    //TODO better integration with leveleditor

    public var spritePath:String;
    public var sprite:FlxSprite;

    public var width:Int = 0;
    public var height:Int = 0;

    public static function fromJson(json:StaticSpriteDataStructure):GenericObjectVisualizer {
        var o = new StaticObjectVisualizer();

        o.name = json.name;

        o.transform.x = json.transform.X;
        o.transform.y = json.transform.Y;
        o.transform.z = json.transform.Z; //Deprecated
        o.transform.angle = json.transform.A;
    
        o.extended = json.extended;
        o.drawOrder = json.drawOrder;
        o.visible = json.active;

        o.width = json.scale.W;
        o.height = json.scale.H;

        o.setSprite(LevelEditor.instance.staticAssets[json.bitmapIndex]);

        for (childInstance in json.children) {
            var child = GenericObjectVisualizer.makefromJson(childInstance);

            o.children.add(child);
        }

        return o;
    }
    
    override public function new() {
        super();

        isStatic = true;

        usesSize = true;

        sprite = new FlxSprite(transform.internalX,transform.internalY);
        setSprite("assets/images/Testbox3.png");
    }

    override function destroy() {

        sprite = FlxDestroyUtil.destroy(sprite);

        super.destroy();
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    override function update(elapsed:Float) {
        transform.update(elapsed);
        sprite.setPosition(transform.internalX,transform.internalY);
        sprite.angle = transform.internalAngle;
        sprite.update(elapsed);
        children.update(elapsed);
    }

    override function drawObject() {
        sprite.draw();
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    override public function onActiveLayerChange(to:Bool) {
        sprite.color = to ? FlxColor.WHITE : FlxColor.GRAY;

        super.onActiveLayerChange(to);
    }

    override public function checkIsHit(mousePos:FlxPoint):GenericObjectVisualizer {
        switch (drawOrder){
            default: //also known as 0
                var initResult = super.checkIsHit(mousePos);
                if(initResult != null) return initResult;

                if(Utils.overlapsSprite(sprite,mousePos,true)) return this;
            case 1:
                if(Utils.overlapsSprite(sprite,mousePos,true)) return this;

                var initResult = super.checkIsHit(mousePos);
                if(initResult != null) return initResult;
        }

        return null;
    }

    override function handleScaling(axis:Int) {
        switch(axis){
            case 0:
                //X
                width += Std.int(FlxGamePlus.mouseMove[0]);
            case 1:
                //Y
                height += Std.int(FlxGamePlus.mouseMove[1]);
            case 2:
                //BOTH
                width += Std.int(FlxGamePlus.mouseMove[0]);
                height += Std.int(FlxGamePlus.mouseMove[1]);
        }
        updateSize();
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public function setSprite(to:String) {
        if(!to.endsWith(".png")) return;
        spritePath = to;
        var g = StaticObject.getAsset(to);
        sprite.loadGraphic(g);

        if(width <= 0 || height <= 0){
            width = g.width;
            height = g.height;
        }

        updateSize();
    }

    function updateSize() {
        sprite.setGraphicSize(width,height);
        sprite.updateHitbox();
    }
    
}