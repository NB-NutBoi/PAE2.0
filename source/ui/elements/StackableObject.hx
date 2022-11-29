package ui.elements;

import flixel.FlxObject;

enum StackSide {
    X;
    Y;
}

class StackableObject extends FlxObject{

    public var rootX:Float;
    public var rootY:Float;

    public var combinedWidth:Float;
    public var combinedHeight:Float;

    public var stackSide:StackSide = Y;

    override public function new(x:Float, y:Float) {
        super(x,y);

        rootX = x;
        rootY = y;
    }

    public function setScrollFactor(x:Float = 0, y:Float = 0) {
        scrollFactor.set(x, y);
    }
}