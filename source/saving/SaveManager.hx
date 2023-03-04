package saving;

import flixel.graphics.FlxGraphic;
import JsonDefinitions;
import gameside.dialogue.DialogueState.DialogueCache;
import gameside.inventory.ItemContainer.ItemContainerCache;
import CoreState.GlobalSaveables;
import assets.AssetCache;
import openfl.display.BitmapData;
import utility.LogFile;
import sys.FileSystem;
import sys.io.FileInput;
import sys.io.FileOutput;
import haxe.crypto.Base64;
import haxe.io.Bytes;
import sys.io.File;
import haxe.Json;
import common.Base64Util;
import utility.Utils;
import CorePlugin;
import levels.Level;
import haxe.DynamicAccess;
import lime.app.Event;

using StringTools;

typedef SaveMetadata = {
    public var graphic:Null<FlxGraphic>;
    public var image:Null<BitmapData>;
    public var imageStr:String;
    public var date:String;
}

typedef Save = {
    public var currentMap:String;
    public var mapSaveables:DynamicAccess<LevelSaveables>; //i know i'm gonna end up crying because of this one :sob:

    public var globals:GlobalSaveables;

    public var pluginSavedata:DynamicAccess<ScriptState>;
    public var itemStates:DynamicAccess<ScriptState>; //To save item class states

    public var dynamics:DynamicAccess<Dynamic>; //there it is, the "make your own save format yourself" field. good fucking luck managing any data in this.
}

class SaveManager {
    static final metadataSepparator:String = "\n##ENDOF#__META_END__#ENDOF##\n"; //sepparates the metadata from the rest of the save data so Json.parse doesn't have to do as much work.
    public static var curSaveData:Save = {
        currentMap: "",
        mapSaveables: new DynamicAccess(),

        globals: {
            scriptSaveables: new DynamicAccess(),
            dialogues: new DynamicAccess(),
            containers: new DynamicAccess()
        },

        pluginSavedata: new DynamicAccess(),
        itemStates: new DynamicAccess(),

        dynamics: new DynamicAccess()
    };

    //--------------------------------------------------------------------------------------
    //main 2

    public static function Save(to:String, ?image:BitmapData = null) {
        CoreState.Save(to);
        var fileContent:String;

        if(image == null) { image = FlxGamePlus.lastFrame; #if debug trace("Saved with null image"); #end }

        var metadata:SaveMetadata = {
            image: null,
            graphic: null,
            imageStr: Utils.getB64StringFromBitmap(image),
            date: Utils.getDate()
        }

        fileContent = Base64Util.Encode(Json.stringify(metadata,null," "))+metadataSepparator+Base64Util.Encode(Json.stringify(curSaveData,null," "));

        File.saveContent(to,fileContent);
    }

    public static final onFailLoad:Event<Int->Void> = new Event<Int->Void>();

    public static function Load(from:String):Bool {
        if(!FileSystem.exists(from) || FileSystem.isDirectory(from) || !from.endsWith(".save")){
            LogFile.error({ message: "The save file "+from+" Does not exist or is not a valid save file!", caller: "SaveManager", id: 44});
            return false;
        }

        //How loading is handled is dependant on source build + game files.
        var fileContent:String = File.getContent(from);

        try 
        {
            fileContent = fileContent.substr(fileContent.indexOf(metadataSepparator)+metadataSepparator.length);
            var Json:Save = cast Json.parse(Base64Util.Decode(fileContent));
            curSaveData = Json;
            CoreState.Load(from);
        }
        catch(e)
        {
            LogFile.error("Error thrown when loading save from file! |[ " + e.message + " ]|\n",true);
            onFailLoad.dispatch(1);
            return false;
        }

        return true;
    }

    //--------------------------------------------------------------------------------------
    //extras

    public static function getSaveMetadata(from:String):SaveMetadata {
        if(!FileSystem.exists(from) || FileSystem.isDirectory(from)) { LogFile.error("Cannot read "+from+" because it is not a valid file or doesn't exist!"); return null; }
        if(!from.endsWith(".save")) { LogFile.error("Cannot read file "+from+" because it is not a valid save file!"); return null; }

        try
        {
            final file:FileInput = File.read(from);
            var fileContent:String = file.readLine(); //first line should always just be the metadata. (optimization!)
            file.close();
    
            var metadata = Base64Util.Decode(fileContent);
            var metadata:SaveMetadata = cast Json.parse(metadata);

            metadata.image = Utils.getBitmapFromB64String(metadata.imageStr);
            metadata.imageStr = "";

            return metadata;
        }
        catch(e)
        {
            LogFile.error("Error thrown when loading save metadata from "+from+" |[ " + e.message + " ]|\n",true);
            onFailLoad.dispatch(2);
        }

        return null;
    }
}