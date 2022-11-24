package utility;

import sys.io.File;
import openfl.display.PNGEncoderOptions;
import haxe.crypto.Base64;
import assets.AssetCache;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxGraphicAsset;
import haxe.ds.Either;
import haxe.io.Path;
import lime.app.Application;
import lime.graphics.opengl.GL;
import openfl.Assets as EmbedAssets;
import openfl.display.BitmapData;
import openfl.utils.ByteArray;
import rendering.Skybox;
import rendering.Sprite;
import sys.FileSystem;

using StringTools;

class Utils {
	
	public static function fancyOpenURL(schmancy:String)
	{
		// lol linux
		// got this from somewhere and it just included linux compatibility and so here we are
		#if linux
		Sys.command('/usr/bin/xdg-open', [schmancy, "&"]);
		#else
		FlxG.openURL(schmancy);
		#end
	}

	//SYSTEM SPECS------------------------------------------------------------------------------------------------------------------------

	public static function getSystemGpu():String
	{
		var gpu:String = "null";
		
		switch (Application.current.window.context.type){
			case OPENGL, OPENGLES, WEBGL:
				gpu = Application.current.window.context.gl.getString(GL.RENDERER);
			default:
				gpu = "COULD NOT GET GPU.";
		}

		return Std.string(gpu);
	}

	public static function getSystemCpu():String {
		var cpu:String = "Could not find CPU.";

		if(Sys.environment().exists("PROCESSOR_IDENTIFIER")){
			cpu = Sys.environment().get("PROCESSOR_IDENTIFIER");
		}
		
		return cpu;
	}

	public static function getThreads():Int {
		var threads = 1;

		if(Sys.environment().exists("NUMBER_OF_PROCESSORS")){
			threads = Std.parseInt(Sys.environment().get("NUMBER_OF_PROCESSORS"));
		}
		
		return threads;
	}

	public static inline function getPlatform():String {
		#if windows
		return "WINDOWS";
		#elseif mac
		return "MAC";
		#end
	}

    //SPRITES-----------------------------------------------------------------------------------------------------------------------------

	public static var ramFriendlyGraphic:FlxGraphic;
	public static function makeRamFriendlyRect(x:Float,y:Float,width:Int,height:Int, ?color:Int = 0xFFFFFFFF, ?antialiasing:Bool = false):FlxSprite {
		var s = new FlxSprite(x,y);
		if(ramFriendlyGraphic == null) ramFriendlyGraphic = makeBitmapGraphic(AssetCache.getImageCache("embed/debug/ramSaver.png"));
		s.loadGraphic(ramFriendlyGraphic);
		s.setGraphicSize(width,height);
		s.color = color;
		s.alpha = s.color.alpha;
		s.updateHitbox();
		s.antialiasing = antialiasing;
		return s;
	}

	//really stupid but comfy so idgaf
    public static inline function makeSparrowAtlas(source:FlxGraphicAsset, description:String):FlxFramesCollection {
        return FlxAtlasFrames.fromSparrow(source, description);
    }

    public static inline function makeBitmapGraphic(b:BitmapData):FlxGraphic {
        return FlxGraphic.fromBitmapData(b);
    }

	public static function getMousePosInCamera(cam:FlxCamera, ?point:FlxPoint = null, ?sprite:FlxSprite) {
        if(point == null)
            point = FlxPoint.weak(0,0);
        
        point = FlxG.mouse.getScreenPosition(cam,point);
		if(sprite == null)
		point.add(cam.scroll.x,cam.scroll.y);
		else
		point.add(cam.scroll.x * sprite.scrollFactor.x,cam.scroll.y * sprite.scrollFactor.y);
        //point.subtract(cam.x,cam.y);

        return point;
    }
    
    public static function overlapsSprite(spr:FlxSprite, mousePos:FlxPoint, ?pixelAccurate:Bool = false) {
        if(spr == null) return false;

		//i forgot this function kinda fucks up the point lol
		final ogX = mousePos.x;
		final ogY = mousePos.y;

        if(!pixelAccurate){
        	mousePos.rotate(spr.getGraphicMidpoint(FlxPoint.weak()),-spr.angle);

			var b = spr.overlapsPoint(mousePos);
			
			mousePos.x = ogX;
			mousePos.y = ogY;
			mousePos.putWeak();
            return b;
        }

		var previous = false;
		var isSprite = Std.isOfType(spr, Sprite);

		if(isSprite){
			previous = cast(spr, Sprite).lockFramePixels;

			cast(spr, Sprite).lockFramePixels = true; //prevent redraws
		}

        var frameData:BitmapData = spr.updateFramePixels();
        mousePos.rotate(spr.getGraphicMidpoint(FlxPoint.weak()), spr.angle == 0 ? 0 : -spr.angle);
        var rotatedPos:Array<Int> = [
            /*x*/Std.int((mousePos.x - spr.x - spr.offset.x) * spr.scale.x),
            /*y*/Std.int((mousePos.y - spr.y - spr.offset.y) * spr.scale.y)
        ];

		mousePos.x = ogX;
		mousePos.y = ogY;
        mousePos.putWeak();

		if(isSprite) cast(spr, Sprite).lockFramePixels = previous;

        return (frameData.getPixel32(rotatedPos[0],rotatedPos[1])!=0);
    }

	public static function drawSkybox(sky:Skybox) {
        drawBackground(sky,sky.scroll);
    }

	//https://youtu.be/LC9XCvMzYKA thank u trepang2 you kept me sane :opraise:

    public static function drawBackground(sprite:FlxSprite, ?extraOffset:FlxPoint) {
        if(sprite == null) return;

		//get all the data needed for the math.
        if(extraOffset == null) extraOffset = FlxPoint.weak(0,0);

        var viewRect = FlxRect.get();
        sprite.camera.getViewRect(viewRect);

        final startingX:Float = viewRect.x;
        final startingY:Float = viewRect.y;

        final bgWidth:Int = Math.ceil(Math.abs(sprite.width));
        final bgHeight:Int = Math.ceil(Math.abs(sprite.height));
        
        final xOffset = (sprite.camera.scroll.x * sprite.scrollFactor.x);
        final yOffset = (sprite.camera.scroll.y * sprite.scrollFactor.y);

        final pixelOffsetX = (extraOffset.x % bgWidth);
        final pixelOffsetY = (extraOffset.y % bgHeight);

        final screenWidth = viewRect.width;
        final screenHeight = viewRect.height;

		//preform the operation.
        final stepsHor:Int = Math.ceil(screenWidth / bgWidth)+1;
        final stepsVert:Int = Math.ceil(screenHeight / bgHeight)+1;
		
        var xi = -1;
        while (xi < stepsHor) {
            var yi = -1;
            while (yi < stepsVert) { //i forgot what the steps here even do but it works so idc.
                var x:Float = (bgWidth*xi+( bgWidth * Math.ceil(((startingX+xOffset)-pixelOffsetX) / bgWidth))) + pixelOffsetX;
                var y:Float = (bgHeight*yi+( bgHeight * Math.ceil(((startingY+yOffset)-pixelOffsetY) / bgHeight))) + pixelOffsetY;

				yi++;
				if(x > (viewRect.x+viewRect.width+xOffset) || y > (viewRect.y+viewRect.height+yOffset)) continue; //small optimization.
				if(x+bgWidth < viewRect.x+xOffset || y+bgHeight < viewRect.y+yOffset) continue; //another small optimization.

                sprite.setPosition(x,y);
                sprite.draw();
            }
            xi++;
        }

        extraOffset.putWeak();
        viewRect.put();
    }

    //FILES-------------------------------------------------------------------------------------------------------------------------------

	public static function checkAssetFilePreRequisites(path:String):Bool {
		if(!FileSystem.exists(path) && !path.startsWith("embed")) return false;
		if(Path.extension(path) != "asset") return false;

		return true;
	}

    public static function getEmbedImage(path:String):BitmapData {
        return EmbedAssets.getBitmapData("embed/"+path);
    }
    
    public static function getEmbedFile(path:String):String {
        return EmbedAssets.getText("embed/"+path);
    }

	public static function checkExternalHaxeFileValid(path:String):Bool {
		if(!FileSystem.exists(path)) return false;
		if(Path.extension(path) != "hx") return false;
		
		return true;
	}

    //BITMAP MAGIC------------------------------------------------------------------------------------------------------------------------

    public static function checkIfBitmapsMatch(b1:BitmapData,b2:BitmapData):Bool {
		if(b1 == null || b2 == null) return false;
		if(b1.image == null || b2.image == null) return false;

		var ba1:ByteArray = new ByteArray();
        ba1 = b1.encode(b1.rect, new flash.display.PNGEncoderOptions(), ba1);

		var ba2:ByteArray = new ByteArray();
        ba2 = b2.encode(b2.rect, new flash.display.PNGEncoderOptions(), ba2);

		if(ba1.toString() == ba2.toString()){

			ba1.clear();
			ba1 = null;
			ba2.clear();
			ba2 = null;

			return true;
		}

		ba1.clear();
		ba1 = null;
		ba2.clear();
		ba2 = null;

        return false;
	}

	public static function checkIfImageFileMatchesBitmap(filePath:String, bitmap:BitmapData):Bool {
		if(bitmap.image == null) return false;
		if(!(FileSystem.exists(filePath) && Path.extension(filePath) == "png")) return false;
		
		var b2 = BitmapData.fromFile(filePath);
		var result = checkIfBitmapsMatch(bitmap, b2);

		b2.dispose();
		b2 = null;

		return result;
	}

	public static function checkIfImageFilesMatch(path1:String, path2:String) {
		if(path1 == path2) return true;
		if(!(FileSystem.exists(path1) && Path.extension(path1) == "png")) return false;
		if(!(FileSystem.exists(path2) && Path.extension(path2) == "png")) return false;

		var b1 = BitmapData.fromFile(path1);
		var b2 = BitmapData.fromFile(path2);

		var result = checkIfBitmapsMatch(b1, b2);


		b1.dispose();
		b1 = null;
		b2.dispose();
		b2 = null;

		return result;
	}

	public static function getB64StringFromBitmap(bitmap:BitmapData):String {
		var ba:ByteArray = new ByteArray();
        ba = bitmap.encode(bitmap.rect, new flash.display.PNGEncoderOptions(), ba);

		var s = Base64.encode(ba);

		ba.clear();
		ba = null;

		return s;
	}

	public static function getBitmapFromB64String(s:String) {
		return BitmapData.fromBase64(s,"image/jpg");
	}

	public static function saveBitmapToImage(bitmap:BitmapData, filename:String) {
		var b:ByteArray = new ByteArray();
        b = bitmap.encode(bitmap.rect, new PNGEncoderOptions(true), b);
        File.saveBytes(filename,b);

		b.clear();
		b = null;
	}

    //MATHS--------------------------------------------------------------------------------------------------------------------------------------------

    inline public static function clamp(value:Float, min:Float, max:Float):Float {
		return Math.max(min, Math.min(max, value));
	}

	inline public static function clampPoint(point:FlxPoint, minY:Float, maxY:Float, minX:Float, maxX:Float):FlxPoint {
		point.x = clamp(point.x, minX, maxX);
		point.y = clamp(point.y, minY, maxY);
		return point;
	}

	public static function numberArray(max:Int, ?min = 0):Array<Int>
	{
		var dumbArray:Array<Int> = [];
		for (i in min...max)
		{
			dumbArray.push(i);
		}
		return dumbArray;
	}

	inline public static function deg2Rad(degree:Float):Float
	{
		return degree * (Math.PI / 180.0);
	}

	inline public static function rad2deg(radian:Float):Float
	{
		return radian * (180.0 / Math.PI);
	}

	//STRINGS--------------------------------------------------------------------------------------------------------------------------------------------

	public static function matchesAny<T>(example:T, options:Array<T>):Bool {
		var i = 0;
		while(options.length > i){
			if(options[i] == example) return true;
			i++;
		}

		return false;
	}

	public static inline function stringTrueFalse(s:String):Bool {
		if(s == null) return false;
        switch(s.toLowerCase().trim()){
            case "true":
                return true;
            case "false":
                return false;
			default:
				return false;
        }
    }

	public static function relativePath(path: String):String {
		//less flexible but more accurate.
		return path.replace("\\","/").replace(Sys.programPath().replace("\\","/").substr(0,Sys.programPath().replace("\\","/").lastIndexOf("/")+1),"");
	}

	//DATES--------------------------------------------------------------------------------------------------------------------------------------------

	static final months:Array<String> = [
		"January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"
	];

	public static function getDate():String
	{
		var curDate:String = "";
		var month:String = months[Date.now().getMonth()];

		var correctMinutes:String = Std.string(Date.now().getMinutes());
		if (correctMinutes.length < 2)
			correctMinutes = ("0" + correctMinutes);

		var correctHours:String = Std.string(Date.now().getHours());
		if (correctHours.length < 2)
			correctHours = ("0" + correctHours);

		curDate = (month + " " + Date.now().getDate() + ", " + (correctHours + ":" + correctMinutes));
		return curDate;
	}

	//DATA--------------------------------------------------------------------------------------------------------------------------------------------

	public static function arrayFromIterator<T>(iterator:Iterator<T>):Array<T> {
		if(iterator == null) return [];
		var array:Array<T> = [];
		for (iteratable in iterator) {
			array.push(iteratable);
		}
		return array;
	}
}

abstract OneOf<A, B>(Either<A, B>) from Either<A, B> to Either<A, B> {
	@:from inline static function fromA<A, B>(a:A):OneOf<A, B> {
	  return Left(a);
	}
	@:from inline static function fromB<A, B>(b:B):OneOf<A, B> {
	  return Right(b);  
	} 
	  
	@:to inline function toA():Null<A> return switch(this) {
	  case Left(a): a; 
	  default: null;
	}
	@:to inline function toB():Null<B> return switch(this) {
	  case Right(b): b;
	  default: null;
	}
  }