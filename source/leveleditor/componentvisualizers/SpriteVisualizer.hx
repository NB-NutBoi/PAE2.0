package leveleditor.componentvisualizers;

import flixel.util.FlxDestroyUtil;
import flixel.util.FlxColor;
import utility.Utils;
import flixel.math.FlxPoint;
import assets.ImageAsset;
import oop.Component;
import rendering.Sprite;

class SpriteVisualizer extends ComponentVisualizer {
    
    public var sprite:Sprite;

    override function copyJson(json:ComponentInstance) {
        super.copyJson(json);
        changeVariable("texture");
        changeVariable("width");
        changeVariable("tint");
        changeVariable("flipX");
    }

    override public function new(type:ComponentClass, parent:ObjectVisualizer) {
        super(type,parent);

        parent.usesSize = true;

        sprite = new Sprite(
            parent.transform.internalX+Component.getArray("offsetX", variables),
            parent.transform.internalY+Component.getArray("offsetY", variables),
            ImageAsset.get(Component.getArray("texture", variables)));

        sprite.setGraphicSize(
            Component.getArray("width", variables),
            Component.getArray("height", variables)
        );

        sprite.updateHitbox();
    }

    override function destroy() {
        owner.usesSize = false;
        sprite = FlxDestroyUtil.destroy(sprite);
        super.destroy();
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    override function changeVariable(key:String, ?inEditor:Bool = false) {
        switch(key){
            case "texture":
                var a = ImageAsset.get(Component.getArray("texture", variables));
                sprite.setAsset(a);

                if(inEditor){
                    //change size cause its driving me insane. (sorry if you relied on size not updating)
                    Component.setArray("width", a.defaultWidth, variables);
                    Component.setArray("height", a.defaultHeight, variables);
                    UPDATE_VARIABLES = true;
                }

                updateSize();
            case "width", "height":
                updateSize();
            case "tint":
                sprite.color = Component.getArray("tint", variables);
            case "flipX", "flipY":
                sprite.flipX = Component.getArray("flipX", variables);
                sprite.flipY = Component.getArray("flipY", variables);
        }
    }

    function updateSize() {
        sprite.setGraphicSize(
            Std.int(Component.getArray("width", variables)),
            Std.int(Component.getArray("height", variables))
        );
        sprite.updateHitbox();
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    override function onActiveLayerChange(to:Bool) {
        sprite.color = to ? Component.getArray("tint", variables) : FlxColor.GRAY;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    override function checkCollides(mousePos:FlxPoint):Bool {
        return Utils.overlapsSprite(sprite,mousePos,true);
    }

    override function handleScaling(axis:Int) {
        UPDATE_VARIABLES = true;
        switch(axis){
            case 0:
                //X
                Component.setArray("width", Component.getArray("width", variables)+FlxGamePlus.mouseMove[0], variables);
            case 1:
                //Y
                Component.setArray("height", Component.getArray("height", variables)+FlxGamePlus.mouseMove[1], variables);
            case 2:
                //BOTH
                Component.setArray("width", Component.getArray("width", variables)+FlxGamePlus.mouseMove[0], variables);
                Component.setArray("height", Component.getArray("height", variables)+FlxGamePlus.mouseMove[1], variables);
        }
        updateSize();
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    override function update(elapsed:Float) {
        super.update(elapsed);

        sprite.setPosition(
            owner.transform.internalX+Component.getArray("offsetX", variables),
            owner.transform.internalY+Component.getArray("offsetY", variables));

        sprite.angle = owner.transform.internalAngle;
    }

    override function draw() {
        sprite.draw();
    }

}