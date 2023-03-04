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

        LogFile.log("Set cur lang to "+curLanguage, true);

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

    public static function getTextCats(key:String, categories:Array<String>) {
        return getText(categories.join(".")+"."+key);
    }

    public static function getProperty(key:String, type:String):Any {
        if(languages[curLanguage] == null) { LogFile.error("Could not get lang property as lang is missing!",true,true); return null; }
        return languages[curLanguage].getProperty(key, type);
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
    public var lang:Dynamic;

    public function new(pre:String, file:Dynamic) {
        prefix = pre;
        lang = file;
    }

    public function getText(key:String) {
        var fields = key.split(".");
        var entry:Dynamic = lang;
        
        for (s in fields) {
            if(entry == null) break;
            entry = Reflect.field(entry,s);
        }

        if(entry == null || !Std.isOfType(entry, String))
            return "LANG ENTRY MISSING";

        return Std.string(entry);
    }

    public function getProperty(key:String, type:String):Any {
        var fields = key.split(".");
        var entry:Dynamic = lang;
        
        for (s in fields) {
            if(entry == null) break;
            entry = Reflect.field(entry,s);
        }

        if(entry == null || !Std.isOfType(entry, String))
            return "PROPERTY ENTRY MISSING";

        switch (type.toLowerCase()){
            case "int": return cast(entry, Int);
            case "float": return cast(entry, Float);
            case "bool": return cast(entry, Bool);
            case "dynamic": return entry;
        }

        return Std.string(entry);
    }

    public function appendCategory(what:Dynamic, to:Dynamic) {
        for (s in Reflect.fields(what)) {
            if(Reflect.hasField(to, s)) appendCategory(Reflect.field(what, s), Reflect.field(to, s));
            else Reflect.setField(to, s, Reflect.field(what, s));
        }
    }

    public function append(otherfile:Language) {
        appendCategory(otherfile.lang,lang);

        otherfile.destroy(); //it has served its purpose.
    }

    public function destroy() {
        lang = null;
        prefix = null;
    }
}