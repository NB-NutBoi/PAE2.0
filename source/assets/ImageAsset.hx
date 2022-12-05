package assets;

import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import haxe.Json;
import haxe.io.Path;
import openfl.utils.Assets;
import utility.LogFile;
import utility.Utils;

using StringTools;

typedef ImageAssetFile = {
    public var flags:Null<Array<Null<String>>>;
    public var texture:Null<String>;
    public var defaultWidth:Null<Int>;
    public var defaultHeight:Null<Int>;
}

class ImageAsset {

    private static var ImageAssets:Map<String, ImageAsset> = new Map();
    public static var defaultImageAsset(default,null):ImageAsset;

    //best way of doing this without parsing twice?
    static var isMostRecentAnimated:Bool = false;

    static function parseFile(file:String, ?rawData:String = null):ImageAssetFile {
        var returnable:ImageAssetFile = null;

        try {
            var rawJson:String = rawData == null ? AssetCache.getDataCache(file) : rawData;

            while (!rawJson.endsWith("}"))
            {
                rawJson = rawJson.substr(0, rawJson.length - 1);
            }
            
            final thing = Json.parse(rawJson);
            if(thing.xml != null || thing.anims != null) isMostRecentAnimated = true;
            returnable = cast thing;
            if(returnable.texture == null) return null;
            //if(returnable.anims.length == 0) return null; actually it doesnt matter if its 0

            return returnable;
        }
        catch(e){
            trace(e.message);
            returnable = null;
            return null;
        }
    }

    static function fixFile(file:ImageAssetFile, ogPath:String):ImageAssetFile {
        if(file.flags != null){
            if(file.flags.contains("LOCALFILES")){
                file.texture = Path.directory(ogPath) + "/" + file.texture;
            }
            if(file.flags.contains("SAMENAME")){
                file.texture += Path.withoutDirectory(ogPath).replace(".asset",".png");
            }
        }

        return file;
    }

    public static function loadFromFile(file:String):ImageAsset {
        if(ImageAssets.exists(file)) return ImageAssets[file];
        if(!Utils.checkAssetFilePreRequisites(file)) return getDefault();
        var assetFile:ImageAssetFile = parseFile(file);
        if(isMostRecentAnimated) {
            isMostRecentAnimated = false; //reset it.
            LogFile.warning("Tried getting animated asset "+file+" as static image asset, corrected.");

            assetFile = null;
            
            return AnimatedAsset.get(file);
        }
        if(assetFile == null) return getDefault();
        assetFile = fixFile(assetFile, file);

        var asset:ImageAsset = new ImageAsset(assetFile, file);
        ImageAssets.set(file, asset);
        return asset;
    }

    public static function get(file:String):ImageAsset {
        if(!ImageAssets.exists(file)) return loadFromFile(file);
        var asset = ImageAssets[file];
        if(asset.graphic.bitmap.image == null){trace("Bitmap missing!"); asset.graphic.bitmap = AssetCache.getImageCache(asset._texture);}
        return asset;
    }
    
    public static function getDefault() {
        if(defaultImageAsset != null){
            //return it.
            if(defaultImageAsset.graphic.bitmap.image == null){ LogFile.error("Missing asset image has been disposed! Run in terror! aaaaghh!!", true); }
            return defaultImageAsset;
        }
        //create it.

        var assetFile:ImageAssetFile = parseFile(null, Assets.getText("embed/assetPrevention/Asset_not_found_image.asset"));
        if(assetFile == null) return null;

        defaultImageAsset = new ImageAsset(assetFile, "missing_image");

        return defaultImageAsset;
    }

    public var important:Bool = false;
    public var flags:Array<String>;

    public var animated:Bool;
    public var graphic:FlxGraphic;
    public var key:String;

    public var texture(get,set):String;
    private var _texture:String;

    public var forceNoAA:Bool = false;

    public var defaultWidth:Int = 0;
    public var defaultHeight:Int = 0;

    public var users:Int = 0;

    public function new(file:ImageAssetFile, key:String) {
        this.key = key;
        animated = false;

        if(file == null) return;

        flags = file.flags == null ? [] : file.flags.copy();

        if(file.flags.contains("MISSING")){
            graphic = FlxGraphic.fromBitmapData(Main.crash_prevention_bitmap);
            important = true;
        }
        else{
            graphic = FlxGraphic.fromBitmapData(AssetCache.getImageCache(file.texture));
        }

        if(file.flags.contains("FORCENOAA")){
            forceNoAA = true;
        }

        graphic.persist = true;

        if(file.defaultHeight != null) defaultHeight = file.defaultHeight; else  defaultHeight = graphic.height;
        if(file.defaultWidth != null) defaultWidth = file.defaultWidth; else defaultWidth = graphic.width;
    }


    public function destroy() {
        if(this == defaultImageAsset) return;
        
        graphic.persist = false;
        AssetCache.removeImageCache(_texture); //probably should dispose.
        ImageAssets.remove(key);
        FlxG.bitmap.remove(graphic);

        _texture = null;
    }

    function get_texture():String {
		return _texture;
	}

	function set_texture(value:String):String {
		_texture = value;
        graphic.bitmap = AssetCache.getImageCache(_texture);
        return _texture;
	}
}