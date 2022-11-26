package ui.aligning;

import ui.elements.StackableObject;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.group.FlxGroup;
import ui.base.Container;
import ui.base.ContainerObject;

class ContainerStack extends FlxTypedGroup<StackableObject> implements ContainerObject{
	public var parent:Null<Container>;

	public function updateInputs(elapsed:Float) {}

	public function postUpdate(elapsed:Float) {}

    
}