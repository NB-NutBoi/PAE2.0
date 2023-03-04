package assets;

//Primitive asset type storage, shouldn't rely on flixel's less-than-ideal system.

import saving.SaveManager.SaveMetadata;
import flixel.graphics.FlxGraphic;
import openfl.Assets as BackupAssets;
import openfl.Assets;
import openfl.display.BitmapData;
import openfl.media.Sound;
import openfl.system.System;
import sys.FileSystem;
import sys.io.File;
import utility.LogFile;

using StringTools;

class AssetCache {
	///////////////////////////////////////////////////////////////////
	//--------------------------IMAGES---------------------------
	///////////////////////////////////////////////////////////////////
	private static var ImageCache:Map<String, BitmapData> = new Map();

	public static function getImageCache(key:String):BitmapData
	{
		var b = ImageCache.get(key);
		if (b != null)
		{
			if(b.image != null) // make sure it's readable
				return b;
			else {
				LogFile.warning("image cache " + key + " has been disposed! re-caching...", false);
				return cacheImage(key);
			}
		}

		LogFile.warning("no image cached with " + key + " exists!, caching.", false, true);
		return cacheImage(key);
	}

	public static function imageCacheExists(key:String):Bool
	{
		return ImageCache.exists(key);
	}

	public static function cacheImage(key:String):BitmapData
	{
		if(ImageCache[key] != null){
			if(ImageCache[key].image != null)
				return ImageCache[key];
			else{
				ImageCache[key] = null;
				ImageCache.remove(key);
			}
		}

		if(key.startsWith("embed") && Assets.exists(key)){
			var bmd = Assets.getBitmapData(key,false);
			ImageCache.set(key, bmd);
			return bmd;
		}

		if (!FileSystem.exists(key))
		{
			LogFile.warning("No image file exists at the path "+ key+".");
			#if debug trace("NO FILE EXIST, PREVENTED CRASH"); #end
			if(Main.crash_prevention_bitmap.image == null) Main.crash_prevention_bitmap = BackupAssets.getBitmapData("embed/Image_not_found.png");
			return Main.crash_prevention_bitmap.clone();
		}

		var bmd:BitmapData = BitmapData.fromFile(key);
		ImageCache.set(key, bmd);
		return bmd;
	}

	public static function removeImageCache(key:String):Void
	{
		if(ImageCache[key] == null) return;
		
		ImageCache[key].dispose();
		ImageCache.remove(key);
		System.gc();
	}

	public static function flushImageCache():Void
	{
		for (s in ImageCache.keys()) {
			ImageCache[s].dispose();
			ImageCache[s] = null;
		}
		ImageCache.clear();

		System.gc();
	}

	///////////////////////////////////////////////////////////////////
	//--------------------------PLAIN TEXT---------------------------
	///////////////////////////////////////////////////////////////////
	private static var DataCache:Map<String, String> = new Map();

	public static function getDataCache(key:String):String
	{
		var d = DataCache.get(key);
		if (d != null)
		{
			return Std.string(d);
		}

		LogFile.warning("no data cached with " + key + " exists!, caching.", false, true);
		return cacheData(key);
	}

	public static function dataCacheExists(key:String):Bool
	{
		return DataCache.exists(key);
	}

	public static function cacheData(key:String):String
	{
		if(key.startsWith("embed") && Assets.exists(key)){
			var s = Assets.getText(key);
			DataCache.set(key, s);
			return Std.string(s);
		}

		if (!FileSystem.exists(key))
		{
			#if debug trace("NO FILE EXIST, PREVENTED CRASH"); #end
			return Std.string(Main.crash_prevention_string);
		}

		var s:String = File.getContent(key).toString();
		DataCache.set(key, s);
		return Std.string(s);
	}

	public static function cacheDataAs(key:String, content:String):String 
	{
		DataCache.set(key, content);
		return Std.string(content);
	}

	public static function removeDataCache(key:String):Void
	{
		DataCache.remove(key);
		System.gc();
	}

	public static function flushDataCache():Void
	{
		DataCache.clear();
		System.gc();
	}

	///////////////////////////////////////////////////////////////////
	//--------------------------SOUNDS---------------------------
	///////////////////////////////////////////////////////////////////
	private static var SoundCache:Map<String, Sound> = new Map();

	@:access(openfl.media.Sound)
	public static function getSoundCache(key:String):Sound
	{
		var s = SoundCache.get(key);
		if (s != null)
		{
			if(s.__buffer != null) // make sure it has an audio buffer
				return s;
			else {
				LogFile.warning("sound cache " + key + " has been disposed! re-caching...", false);
				return cacheSound(key);
			}
		}

		LogFile.warning("no sound cached with " + key + " exists!, caching.", false, true);
		return cacheSound(key);
	}

	public static function soundCacheExists(key:String):Bool
	{
		return SoundCache.exists(key);
	}

	@:access(openfl.media.Sound)
	public static function cacheSound(key:String):Sound
	{
		if(SoundCache[key] != null){
			if(SoundCache[key].__buffer != null)
				return SoundCache[key];
			else{
				SoundCache[key] = null;
				SoundCache.remove(key);
			}
		}

		if(key.startsWith("embed") && Assets.exists(key)){
			var s:Sound = Assets.getSound(key, false);
			SoundCache.set(key, s);
			return s;
		}

		if (!FileSystem.exists(key) || !key.endsWith(".ogg"))
		{
			return Main.crash_prevention_sound;
		}

		var s:Sound = Sound.fromFile(key);
		SoundCache.set(key, s);
		return s;
	}

	public static function removeSoundCache(key:String):Void
	{
		SoundCache[key] = null;
		SoundCache.remove(key);
		System.gc();
	}

	public static function flushSoundCache():Void
	{
		for (s in SoundCache.keys()) {
			SoundCache[s] = null;
		}
		SoundCache.clear();
		System.gc();
	}

	///////////////////////////////////////////////////////////////////
	//----------------------------HELPERS-----------------------------
	///////////////////////////////////////////////////////////////////

	public static function cacheImageAssetSimple(pathNoExt:String) {
		cacheData(pathNoExt+".asset");
		cacheImage(pathNoExt+".png");
	}

	public static function cacheAnimatedAssetSimple(pathNoExt:String) {
		cacheData(pathNoExt+".asset");
		cacheImage(pathNoExt+".png");
		cacheData(pathNoExt+".xml");
	}

	///////////////////////////////////////////////////////////////////
	//--------------------------OTHER DATA---------------------------
	///////////////////////////////////////////////////////////////////
	// use to store caches of misc data like saves and temp graphics (save image graphics.)
	private static var MiscCache:Map<String, Any> = new Map();

	public static function getMiscCache(key:String, ?optData:String = null):Any
	{
		var m = MiscCache.get(key);
		if (m != null)
		{
			switch (optData.toLowerCase())
			{
				case null: return null;
				case "string": return Std.string(m);
				case "int": return cast(m,Int);
				case "float": return cast(m,Float);
				case "bool": return cast(m,Bool);
				case "savemetadata":
					var mt:SaveMetadata = null;
					return mt= cast m;
				case "flxgraphic":
					return cast(m,FlxGraphic);
				default:
					LogFile.error("Misc data does not support the type " + optData, true);
					return null;
			}
		}

		LogFile.warning("no misc cached with " + key + " exists! brace for potential crash!",true);
		return null;
	}

	public static function miscCacheExists(key:String):Bool
	{
		return MiscCache.exists(key);
	}

	public static function cacheMisc(key:String, data:Any):Any
	{
		var finalData:Any = data;
		MiscCache.set(key, data);
		return finalData;
	}

	public static function flushMisc()
	{
		MiscCache.clear();

		System.gc();
	}
}