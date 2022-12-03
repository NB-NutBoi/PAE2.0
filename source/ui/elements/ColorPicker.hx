package ui.elements;

import flixel.FlxSprite;
import flixel.util.FlxColor;
import ui.base.Container;
import ui.base.ContainerObject;

class ColorPicker extends StackableObject implements ContainerObject {
    static final RIM:Int = 0xFF303030;


	public var parent:Null<Container>;


    public var color:FlxColor;

    public var box:FlxSprite;
    public var colorBox:FlxSprite;


    override function update(elapsed:Float) {

        colorBox.color = color;

        super.update(elapsed);
    }

	public function updateInputs(elapsed:Float) {}

	public function postUpdate(elapsed:Float) {}

    
}