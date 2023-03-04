package assets;

import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import haxe.Json;
import haxe.io.Path;
import openfl.Assets;
import utility.LogFile;
import utility.Utils;

using StringTools;

typedef AnimatedAssetFile = {
    public var flags:Null<Array<Null<String>>>;
    public var texture:Null<String>;
    public var xml:Null<String>;
    public var anims:Null<Array<Array<Null<Dynamic>>>>;
    /**
        FORMAT: [ANIM_NAME,ANIM_IDX_NAME,FRAMERATE,LOOPED]
        EXTRA ARGS: [X_OFFSET,Y_OFFSET]
    **/
    public var defaultWidth:Null<Int>;
    public var defaultHeight:Null<Int>;
}

class AnimatedAsset extends ImageAsset {

    private static var AnimatedAssets:Map<String, AnimatedAsset> = new Map();
    public static var defaultAnimatedAsset(default,null):AnimatedAsset;

    static function parseFile(file:String, ?rawData:String = null):AnimatedAssetFile {
        var returnable:AnimatedAssetFile = null;

        try {
            var rawJson:String = rawData == null ? AssetCache.getDataCache(file) : rawData;

            while (!rawJson.endsWith("}"))
            {
                rawJson = rawJson.substr(0, rawJson.length - 1);
            }
            
            returnable = cast Json.parse(rawJson);
            if(returnable.texture == null) return null;
            if(returnable.xml == null) return null;
            if(returnable.anims == null) return null;
            //if(returnable.anims.length == 0) return null; actually it doesnt matter if its 0

            return returnable;
        }
        catch(e){
            LogFile.error("Error parsing animated asset: "+e.message, true, true);
            returnable = null;
            return null;
        }
    }

    static function fixFile(file:AnimatedAssetFile, ogPath:String):AnimatedAssetFile {
        if(file.flags != null){
            if(file.flags.contains("LOCALFILES")){
                file.texture = Path.directory(ogPath) + "/" + file.texture;
                file.xml = Path.directory(ogPath) + "/" + file.xml;
            }
            if(file.flags.contains("SAMENAME")){
                file.texture += Path.withoutDirectory(ogPath).replace(".asset",".png");
                file.xml += Path.withoutDirectory(ogPath).replace(".asset",".xml");
            }
        }

        return file;
    }
    
    public static function loadFromFile(file:String, ?cache:Bool = false):AnimatedAsset {
        if(AnimatedAssets.exists(file)) return AnimatedAssets[file];
        if(!Utils.checkAssetFilePreRequisites(file)) return getDefault();
        if(cache && !AssetCache.dataCacheExists(file)) AssetCache.cacheData(file);
        var assetFile:AnimatedAssetFile = parseFile(file);
        if(assetFile == null) return getDefault();
        assetFile = fixFile(assetFile, file);

        if(cache && !AssetCache.imageCacheExists(assetFile.texture)) AssetCache.cacheImage(assetFile.texture);
        if(cache && !AssetCache.dataCacheExists(assetFile.xml)) AssetCache.cacheData(assetFile.xml);
        var asset:AnimatedAsset = new AnimatedAsset(assetFile, file);
        AnimatedAssets.set(file, asset);
        return asset;
    }

    public static function get(file:String):AnimatedAsset {
        if(!AnimatedAssets.exists(file)) return loadFromFile(file);
        var asset = AnimatedAssets[file];
        if(asset.graphic.bitmap.image == null){ #if debug trace("Animated asset Bitmap missing!"); #end asset.graphic.bitmap = AssetCache.getImageCache(asset._texture);}
        return asset;
    }

    public static function exists(file:String):Bool {
        return AnimatedAssets.exists(file);
    }

    public static function getDefault() {
        if(defaultAnimatedAsset != null){
            //return it.
            if(defaultAnimatedAsset.graphic.bitmap.image == null){LogFile.error("Missing asset image has been disposed! Run in terror! aaaaghh!!", true);}
            return defaultAnimatedAsset;
        }
        //create it.

        var assetFile:AnimatedAssetFile = parseFile(null, Assets.getText("embed/assetPrevention/Asset_not_found_animated.asset"));
        if(assetFile == null) return null;

        defaultAnimatedAsset = new AnimatedAsset(assetFile, "missing_animated");

        return defaultAnimatedAsset;
    }

    //--------------------------------------------------------------------------------------------------------------------------------------------------------------------

    public var availableAnimations:Map<String, Array<Dynamic>> = new Map();
    public var xml(get,set):String;
    private var _xml:String;

    override public function new(file:AnimatedAssetFile, key:String) {
        super(null, key);

        animated = true;

        _texture = file.texture;
        xml = file.xml;
        flags = file.flags == null ? [] : file.flags.copy();

        if(file.flags.contains("MISSING")){
            if(FlxG.bitmap.get("missing_bitmap") != null) graphic = FlxG.bitmap.get("missing_bitmap");
            else graphic = FlxGraphic.fromBitmapData(Main.crash_prevention_bitmap, false, "missing_bitmap");
            important = true;
        }
        else{
            graphic = FlxGraphic.fromBitmapData(AssetCache.getImageCache(file.texture), false, file.texture);
        }

        if(file.flags.contains("FORCENOAA")){
            forceNoAA = true;
        }

        graphic.persist = true;

        if(file.defaultHeight != null) defaultHeight = file.defaultHeight; else  defaultHeight = graphic.height;
        if(file.defaultWidth != null) defaultWidth = file.defaultWidth; else defaultWidth = graphic.width;

        for (anim in file.anims) {
            availableAnimations.set(anim[0], anim);
        }
    }

    override function destroy() {
        if(this == defaultAnimatedAsset) return;
        
        graphic.persist = false;
        AssetCache.removeImageCache(_texture);
        AssetCache.removeDataCache(_xml);
        AnimatedAssets.remove(key);
        FlxG.bitmap.remove(graphic);

        availableAnimations.clear();
        _texture = null;
        _xml = null;
    }

    //--------------------------------------------------------------------------------------------------------------------------------------------------------------------

	function get_xml():String {
		return _xml;
	}

	function set_xml(value:String):String {
        return _xml = AssetCache.getDataCache(value);
	}
}