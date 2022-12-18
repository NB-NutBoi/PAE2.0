package lowlevel;

import flixel.util.FlxColor;
import oop.ComponentPackages.InputPackageKeyCode;
import haxe.DynamicAccess;

/**
 * Collection of static functions and static vars so hscript can implement abstracts.
 */
class HAbstracts {

    public static var KeyCode:Class<InputPackageKeyCode> = InputPackageKeyCode;
    public static var Color:Class<HscriptColor> = HscriptColor;
    
    //i really hate that i can't import abstracts to HScript
    public static function newDynamicAccess():DynamicAccess<Dynamic> {
        return new DynamicAccess<Dynamic>();
    }

    public static function newAnonymous():Dynamic {
        return {};
    }

}

//literally just ports the FlxColor abstract to a class cause hscript dont like abstracts.
class HscriptColor {

	public static var RED = FlxColor.RED;
	public static var WHITE = FlxColor.WHITE;
	public static var BLACK = FlxColor.BLACK;
	public static var GRAY = FlxColor.GRAY;
	public static var BLUE = FlxColor.BLUE;
	public static var CYAN = FlxColor.CYAN;
	public static var GREEN = FlxColor.GREEN;
	public static var LIME = FlxColor.LIME;
	public static var YELLOW = FlxColor.YELLOW;
	public static var ORANGE = FlxColor.ORANGE;
	public static var PURPLE = FlxColor.PURPLE;
	public static var MAGENTA = FlxColor.MAGENTA;
	public static var BROWN = FlxColor.BROWN;
	public static var PINK = FlxColor.PINK;
	public static var TRANSPARENT = FlxColor.TRANSPARENT;

	public static function fromRGB(r:Int, g:Int, b:Int, a:Int = 1):FlxColor {
    	return FlxColor.fromRGB(r, g, b, a);
  	}

	public static function fromRGBFloat(r:Float, g:Float, b:Float, a:Float = 1):FlxColor {
		return FlxColor.fromRGBFloat(r, g, b, a);
	}

	public static function fromCMYK(c:Float, m:Float, y:Float, k:Float, a:Float = 1):FlxColor {
		return FlxColor.fromCMYK(c, m, y, k, a);
	}

	public static function fromHSB(h:Float, s:Float, b:Float, a:Float = 1):FlxColor {
		return FlxColor.fromHSB(h, s, b, a);
	}

	public static function fromHSL(h:Float, s:Float, l:Float, a:Float = 1):FlxColor {
		return FlxColor.fromHSL(h, s, l, a);
	}

	public static function fromString(s:String):FlxColor {
		return FlxColor.fromString(s);
	}

	public static function fromInt(i:Int):FlxColor {
		return FlxColor.fromInt(i);
	}

	public static function interpolate(c1:FlxColor, c2:FlxColor, f:Float):FlxColor {
		return FlxColor.interpolate(c1, c2, f);
	}
}