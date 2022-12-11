package utility;

import haxe.io.Path;
import assets.AssetPaths;
import flixel.util.FlxSignal;
import haxe.DynamicAccess;
import haxe.Json;
import sys.io.File;

using StringTools;

class LanguageManager {

    private static var langFolder:String;
    private static var languages:Map<String,Language> = new Map();

    public static var curLanguage:String;

    public static var listeners:FlxSignal = new FlxSignal();

    public static function set(langFolder:String) {
        languages.clear();

        LanguageManager.langFolder = langFolder;

        var langs = AssetPaths.getPathList(langFolder,null,["lang"]);
        for (path in langs) {
            var f = parseFile(path);

            if(f == null){
                LogFile.fatalError("Language file failed to create.\n",20);
                return;
            }

            var lang = new Language(new Path(path).file.toLowerCase(), f);

            languages.set(lang.prefix, lang);
        }
    }

    //adds lang on top and replaces existing ones.
    public static function appendLang(langFolder:String) {
        var langs = AssetPaths.getPathList(langFolder,null,["lang"]);
        
        for (path in langs) {
            try{
                var f = parseFile(path);

                if(f == null){
                    LogFile.fatalError("Language file failed to append.\n",20);
                    return;
                }

                var lang = new Language(new Path(path).file.toLowerCase(), f);
    
                if(languages[lang.prefix] == null){
                    languages.set(lang.prefix,lang);
                }
                else{
                    languages[lang.prefix].append(lang);
                }
            }
            catch(e){
                LogFile.fatalError("Language file failed to append: "+e.message+"\n",21);
            }
        }
    }

    public static function setCurLanguage(prefix:String) {
        prefix = prefix.toLowerCase();
        if(languages[prefix] == null || prefix == curLanguage) return;
        curLanguage = prefix;

        trace("set cur lang to "+curLanguage);

        listeners.dispatch();
    }

    public static function getLanguageList():Array<String> {
        var l:Array<String> = [];
        for (s in languages.keys()) {
            l.push(s);
        }
        return l;
    }

    public static function getText(key:String) {
        if(languages[curLanguage] == null) return "LANG_MISSING";
        return languages[curLanguage].getText(key);
    }

    public static function getTextCat(key:String, category:String) {
        return getText(category+"."+key);
    }

    //-------------------------------------------------------------------------------------------------------------------------------------------------------------
    //-------------------------------------------------------------------------------------------------------------------------------------------------------------
    //-------------------------------------------------------------------------------------------------------------------------------------------------------------

    static function parseFile(filePath:String):Dynamic {
        var ogContent = File.getContent(filePath);

        var parserType = ogContent.substr(0,ogContent.indexOf("\n")).trim();
        var content = ogContent.substr(ogContent.indexOf("\n"));

        var file:Dynamic = null;
        switch(parserType.toUpperCase().trim()){
            case "JSON": file = tryJsonParse(content);
            default:LogFile.log("Language file type "+parserType+" has no parser associated, trying json!");
            file = tryJsonParse(ogContent); //try json as last resort since it's guaranteed a safe return.
        }

        return file;
    }

    static function tryJsonParse(content:String):Dynamic {
        var file:Dynamic = null;

        try
        {
            while (!content.endsWith("}"))
            {
                content = content.substr(0, content.length - 1);
            }
            
            file = cast Json.parse(content);
        }
        catch(e){
            LogFile.error("Error parsing json lang file! : "+e.message);
            file = {}
        }

        return file;
    }

    static function tryCustomParse(content:String):Dynamic {
        var file:Dynamic = null;

        return file;
    }
}

class Language {
    public var prefix:String = "english";
    public var entries:Map<String,String> = new Map();

    public function new(pre:String, file:Dynamic) {
        prefix = pre;
        parseCategory("",file);
    }

    function parseCategory(cat:String, category:Dynamic) {
        final append:String = cat == "" ? "" : ".";

        for (s in Reflect.fields(category)) {
            var a:Dynamic = Reflect.field(category,s);
            if(Std.isOfType(a, String)) entries.set(cat+append+s,a);
            else parseCategory(cat+append+s,a);
        }
    }

    public function getText(key:String) {
        var s = entries[key];
        if(s == null)
            return "LANG ENTRY MISSING";

        return s;
    }

    public function append(otherfile:Language) {
        for (s in otherfile.entries.keys()) {
            entries.set(s,otherfile.entries[s]);
        }

        otherfile.destroy(); //it has served its purpose.
    }

    public function destroy() {
        entries.clear();
        entries = null;
        prefix = null;
    }
}