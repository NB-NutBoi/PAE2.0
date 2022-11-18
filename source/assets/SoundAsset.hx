package assets;

import flixel.FlxG;
import haxe.Json;
import haxe.io.Path;
import openfl.media.Sound;
import openfl.utils.Assets;
import utility.Utils;

using StringTools;

typedef SoundAssetFile = {
    public var flags:Null<Array<Null<String>>>;
    public var isPlayableSong:Null<Bool>;
    public var bpm:Null<Int>;
    public var instrumental:Null<String>;
    public var voiceTracks:Null<Array<String>>;
    public var loop:Null<Bool>;
}

class SoundAsset {
    
    private static var SoundAssets:Map<String, SoundAsset> = new Map();
    public static var defaultSoundAsset(default,null):SoundAsset;

    static function parseFile(file:String, ?rawData:String = null):SoundAssetFile {
        var returnable:SoundAssetFile = null;

        try {
            var rawJson:String = rawData == null ? AssetCache.getDataCache(file) : rawData;

            while (!rawJson.endsWith("}"))
            {
                rawJson = rawJson.substr(0, rawJson.length - 1);
            }
            
            returnable = cast Json.parse(rawJson);
            if(returnable.instrumental == null) return null;
            if(returnable.bpm == null) return null;

            return returnable;
        }
        catch(e){
            trace(e.message);
            returnable = null;
            return null;
        }
    }

    static function fixFile(file:SoundAssetFile, ogPath:String):SoundAssetFile {
        if(file.flags != null){
            if(file.flags.contains("LOCALFILES")){
                file.instrumental = Path.directory(ogPath) + "/" + file.instrumental;
                if(file.voiceTracks != null){
                    for (i in 0...file.voiceTracks.length) {
                        file.voiceTracks[i] = Path.directory(ogPath) + "/" + file.voiceTracks[i];
                    }
                }
            }
            if(file.flags.contains("SAMENAME")){
                file.instrumental += Path.withoutDirectory(ogPath).replace(".asset",".ogg")+"-INSTRUMENTAL";
                if(file.voiceTracks != null){
                    for (i in 0...file.voiceTracks.length) {
                        file.voiceTracks[i] += Path.withoutDirectory(ogPath).replace(".asset",".ogg")+"-VOICES"+i;
                    }
                }
            }
        }

        return file;
    }

    public static function loadFromFile(file:String):SoundAsset {
        if(SoundAssets.exists(file)) return SoundAssets[file]; //won't get stuck in a loop, i promise >:D
        if(!Utils.checkAssetFilePreRequisites(file)) return getDefault();
        var assetFile:SoundAssetFile = parseFile(file);
        if(assetFile == null) return getDefault();
        assetFile = fixFile(assetFile, file);

        var asset:SoundAsset = new SoundAsset(assetFile, file);
        SoundAssets.set(file, asset);
        return asset;
    }

    public static function get(file:String):SoundAsset {
        if(!SoundAssets.exists(file)) return loadFromFile(file);
        var asset = SoundAssets[file];
        return asset;
    }

    public static function getDefault() {
        if(defaultSoundAsset != null){
            //return it.
            return defaultSoundAsset;
        }
        //create it.

        var assetFile:SoundAssetFile = parseFile(null, Assets.getText("embed/assetPrevention/Asset_not_found_sound.asset"));
        if(assetFile == null) return null;

        defaultSoundAsset = new SoundAsset(assetFile, "missing_sound");

        return defaultSoundAsset;
    }

    //--------------------------------------------------------------------------------------------------------------------------------------------------------------------

    public var key:String;
    public var inst:Sound;
    public var vocals(default,never):Array<Sound> = [];

    public var loop:Bool;
    public var important:Bool;
    public var bpm:Int;

    public function new(file:SoundAssetFile, key:String) {
        
        this.key = key;
        loop = file.loop;

        important = false;
        bpm = file.bpm;

        if(file.flags.contains("MISSING")){
            inst = Main.crash_prevention_sound;
        }
        else{
            inst = AssetCache.getSoundCache(file.instrumental);
            for (s in file.voiceTracks) {
                vocals.push(AssetCache.getSoundCache(s));
            }
        }
    }

    public function destroy() {
        if(this == defaultSoundAsset) return;
        
        SoundAssets.remove(key);

        inst = null;
        while(vocals[0] != null){
            vocals.remove(vocals[0]);
        }
    }

}