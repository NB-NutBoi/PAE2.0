package common;
//------------------------------------------------------------
//------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------|
/* This file is under protection and belongs to the PA: AUN project team.                                  |
 * You may learn from this code and / or modify the source code for redistribution with proper accrediting.|
 * -NUT                                                                                                    |
 *///                                                                                                      |
//---------------------------------------------------------------------------------------------------------|

import openfl.errors.Error;
import sys.FileSystem;
import sys.io.File;

class Base64Util {
    public static inline function Encode(string:String):String {return haxe.crypto.Base64.encode(haxe.io.Bytes.ofString(string));}

    public static inline function Decode(string:String, ?complement:Bool = true):String {return haxe.crypto.Base64.decode(string, complement).toString();}

    public static function DecodeFile(path:String):String {
		if (!FileSystem.exists(path) || FileSystem.isDirectory(path))
            throw  new Error(path + " is not a valid file path!",9);
        
        return Decode(File.getContent(path).toString());
    }

	public static function EncodeStringToFile(string:String,path:String){File.saveContent(path, Encode(string));}
}