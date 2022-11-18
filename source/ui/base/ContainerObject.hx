package ui.base;

import flixel.FlxBasic;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;

interface ContainerObject {
    public var parent:Null<Container>;
    public function updateInputs(elapsed:Float):Void;
    public function postUpdate(elapsed:Float):Void;
}