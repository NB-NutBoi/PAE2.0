package ui.elements;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxSprite;
import ui.base.Container;
import utility.Utils;

class ContainerMover extends FlxSprite{

    public var parent:Null<Container> = null;

    override public function new(x:Float = 3, y:Float = 3) {
        super(x,y, "embed/ui/mover.png");
        antialiasing = true;
        scrollFactor.set();
        graphic.destroyOnNoUse = false;
        graphic.persist = true;
    }
    
    override function overlaps(ObjectOrGroup:FlxBasic, InScreenSpace:Bool = false, ?Camera:FlxCamera):Bool {
		if (parent == null) return false;

        return Utils.overlapsSprite(this, Utils.getMousePosInCamera(parent.cam, null, this), false);
    }
}