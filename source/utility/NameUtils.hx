package utility;

using StringTools;

class NameUtils {
    /*

    NAME EXAMPLE : trash_bin_34
    how to identify: make sure last numbers are numeric (go backwards and identify numbers)

    */

    static var numerics:Array<String> = ["0","1","2","3","4","5","6","7","8","9"];

    public static function isNumeric(s:String):Bool {
        return numerics.contains(s);
    }

    public static function endsInNumerics(s:String):Bool {
        return isNumeric(s.charAt(s.length-1));
    }

    public static function endsInFormattedNumerics(s:String):Bool {
        //basically any length of numbers preceded by a _
        if(!endsInNumerics(s)) return false;

        var i = s.length-1;

        while (isNumeric(s.charAt(i))){

            i--;
        }

        if(s.charAt(i) != "_") return false;
        
        return true;
    }

    public static function getNumber(fullName:String):Int {

        if(!endsInFormattedNumerics(fullName))
            return -1;

        var i = fullName.length-1;

        while (isNumeric(fullName.charAt(i))){

            i--;
        }

        if(Std.parseInt(fullName.substr(i+1)) == null) return -1;

        var number:Int = Std.parseInt(fullName.substr(i+1));

        return number;
    }

    public static function removeFormattedNumber(fullName:String):String {
        if(!endsInFormattedNumerics(fullName))
            return fullName;

        var i = fullName.length-1;

        while (isNumeric(fullName.charAt(i))){

            i--;
        }

        return fullName.substr(0,i);
    }
}