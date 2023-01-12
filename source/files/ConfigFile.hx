package files;
//------------------------------------------------------------
//------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------|
/* This file is under protection and belongs to the PA: AUN project team.                                  |
 * You may learn from this code and / or modify the source code for redistribution with proper accrediting.|
 * -NUT                                                                                                    |
 *///                                                                                                      |
//---------------------------------------------------------------------------------------------------------|

import sys.FileSystem;
import sys.io.File;
import utility.LogFile;
import utility.Utils;

using StringTools;

class ConfigFile {

    public var configs:Map<String,String> = new Map();

	public function set(configFile:String):Void
	{
		if (configFile == "default")
		{ //idk what i tried to do here
			configFile = "
            ScriptExtension=.cool\n
            DoLogging=false\n
            MaxHeldMessages=20";
		}

		var lines = configFile.split("\n");
        var longComment:Bool = false;

        

		for (i in 0...lines.length)
		{
			var s = lines[i].trim();
            if (s == "" || s.length == 0)
                continue;
            
			if (s.startsWith("//"))
				continue;

            if(longComment){
                if(s.startsWith("*/") || s.endsWith("*/"))
                    longComment = false;

                continue;
            }

            if(s.startsWith("/*")){
                longComment = true;
                
				if (s.endsWith("*/"))
                    longComment = false;
                
                continue;
            }

            //actually register config
			var curConfig = s.split("=");
			
			configs.set(curConfig[0].trim(), s.substr(s.indexOf("=") + 1).trim());
		}
	}

    //ik its a typo it just won't let me type default
    public function getConfig(name:String,type:String,deafult:Any):Any {
        var thing = configs.get(name);
        if(thing == null)
			return deafult;
        
        switch (type.toLowerCase()){
            case "string":
                return thing;
            case "bool":
                return Utils.stringTrueFalse(thing);
            case "int":
                return Std.parseInt(thing);
            case "float":
                return Std.parseFloat(thing);
            default:
                return  thing;
        }
    }

    public function configExists(name:String):Bool {
        return configs.exists(name);
    }

	public function new(?filePath:String = "") {
        if(filePath == "" || filePath == null){
            //makes an empty config file.
            return;
        }
        if(filePath.endsWith(".cfg")){
            if(FileSystem.exists(filePath) && !FileSystem.isDirectory(filePath)){
                set(File.getContent(filePath).toString());
            }
            else{
                LogFile.warning("Config file " + filePath + " does not exist, could not set config.\n");
            }
        }
        else{
			// doesn't matter but let's stay focused
			LogFile.error("File " + filePath + " is not a config file!\n");
        }
    }

    public function destroy() {
        configs.clear();
        configs = null;
    }


    //NEW SAVEABLE CONFIG FILE SUPPORT------------------------------------
    public function addConfig(name:String, value:Any):Void {
        //values can save any but can only read the standards

        configs.set(name, Std.string(value));
    }

    public function saveFile(path:String):Void {
        if(!path.endsWith(".cfg")){
            LogFile.error("Cannot save configFile on path " + path + " because it does not end with .cfg!\n");
            return;
        }

        File.saveContent(path, stringifyCurrentConfig());
    }

    public function stringifyCurrentConfig():String {
        var finalString:String = "";
        for (s in configs.keys()) {
            finalString += s+"="+configs[s]+"\n";
        }
        finalString += "\n//This file was generated automatically by PAR "+Main.GameVersion;
        return finalString;
    }
}