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

    override function changeVariable(key:String) {
        switch(key){
            case "texture":
                sprite.setAsset(ImageAsset.get(Component.getArray("texture", variables)));
                updateSize();
            case "width", "height":
                updateSize();
            case "tint":
                sprite.color = Component.getArray("tint", variables);
        }
    }

    function updateSize() {
        sprite.setGraphicSize(
            Component.getArray("width", variables),
            Component.getArray("height", variables)
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