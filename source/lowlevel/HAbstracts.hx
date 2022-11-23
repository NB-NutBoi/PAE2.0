package lowlevel;

import oop.ComponentPackages.InputPackageKeyCode;
import haxe.DynamicAccess;

/**
 * Collection of static functions and static vars so hscript can implement abstracts.
 */
class HAbstracts {

    public static var KeyCode:Class<InputPackageKeyCode> = InputPackageKeyCode;
    
    //i really hate that i can't import abstracts to HScript
    public static function newDynamicAccess():DynamicAccess<Dynamic> {
        return new DynamicAccess<Dynamic>();
    }

}