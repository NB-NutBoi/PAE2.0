package lowlevel;

import haxe.DynamicAccess;

class HDynamicAccess {
    
    //i really hate that i can't import abstracts to HScript
    public static function makeNewDynamicAccess():DynamicAccess<Dynamic> {
        return new DynamicAccess<Dynamic>();
    }

}