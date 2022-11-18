package;

import flixel.util.typeLimit.OneOfFour;

typedef JSONColor = {
    public var R:Int;
    public var G:Int;
    public var B:Int;
    public var A:Int;
}

typedef ScriptVariable = OneOfFour<Float,String,Int,Bool>;