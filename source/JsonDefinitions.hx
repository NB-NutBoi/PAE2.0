package;

import flixel.util.typeLimit.OneOfFour;

typedef JSONColor = {
    public var R:Int;
    public var G:Int;
    public var B:Int;
    public var A:Int;
}

typedef JSONTransform = {
    public var X:Float;
    public var Y:Float;
    public var Z:Int;

    public var A:Float;
}

typedef JSONScale = {
    public var W:Int;
    public var H:Int;
}

typedef ScriptVariable = OneOfFour<Float,String,Int,Bool>;