package;

import files.HXFile;
import files.HXFile.HaxeScript;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.graphics.tile.FlxGraphicsShader;
import flixel.util.FlxColor;
import lime._internal.backend.native.NativeCFFI;
import lime.app.Application;
import lime.graphics.Image;
import lime.graphics.RenderContext;
import lime.graphics.cairo.CairoImageSurface;
import lime.graphics.opengl.GLTexture;
import oop.Component;
import oop.Object;
import oop.premades.AudioListenerComponent;
import oop.premades.AudioSourceComponent;
import oop.premades.SpriteComponent;
import openfl.Lib;
import openfl.Vector;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.Graphics;
import openfl.display.GraphicsBitmapFill;
import openfl.display.GraphicsGradientFill;
import openfl.display.GraphicsPath;
import openfl.display.GraphicsQuadPath;
import openfl.display.GraphicsShaderFill;
import openfl.display.GraphicsSolidFill;
import openfl.display.GraphicsStroke;
import openfl.display.GraphicsTrianglePath;
import openfl.display.OpenGLRenderer;
import openfl.display.PNGEncoderOptions;
import openfl.display.Stage;
import openfl.display._internal.DrawCommandReader;
import openfl.display._internal.DrawCommandType;
import openfl.display._internal.ShaderBuffer;
import openfl.geom.ColorTransform;
import openfl.utils.ByteArray;
import sys.io.File;

class DebugState extends CoreState
{

	var screenTexture:BitmapData;

	var obj:Object;
	var obj2:Object;

	var haxeScript:HaxeScript;

	override public function create()
	{
		super.create();

		var funnysquare = new FlxSprite(300, 300).makeGraphic(100, 100, FlxColor.WHITE);
		var r = FlxColor.RED;
		funnysquare.setColorTransform(r.redFloat,r.greenFloat,r.blueFloat,1,/*mul*/      /*offsets*/0,0,0,0);
		add(funnysquare);

		var aa = new FlxSprite(678, 463).makeGraphic(100, 100, FlxColor.WHITE);
		aa.color = FlxColor.CYAN;
		add(aa);


		Component.componentClasses.set("Test1", {name: "Test1", key: "Test1", icon: null, script: "assets/data/componentscript.txt", editableVars: null, defaultVars: null, specialOverrideClass: null, specialOverrideArgs: null, static_vars: null});
		Component.componentClasses.set("Test2", {name: "Test2", key: "Test2", icon: null, script: "assets/data/componentscript2.txt", editableVars: null, defaultVars: null, specialOverrideClass: null, specialOverrideArgs: null, static_vars: null});


		/*
		obj = new Object();
		var comp1:Component = Component.makeComponentOfType("Test1", obj);
		obj.componets.add(comp1);

		var comp3:SpriteComponent = cast Component.makeComponentOfType("Sprite", obj);
		obj.componets.add(comp3);

		comp3.texture = "assets/images/JennTest.asset";

		obj.name = "Jenn";
		obj.transform.drawDebug = true;

		obj2 = new Object();
		var comp2:Component = Component.makeComponentOfType("Test2", obj2);
		obj2.componets.add(comp2);

		var comp4 = new AudioListenerComponent(obj2);
		obj2.componets.add(comp4);

		obj2.name = "AudioListener";
		

		obj.children.add(obj2);

		add(obj);
		*/
		/*

		obj.transform.angularVelocity = 2;
		obj.transform.velocity.x = 3;
		obj.transform.velocity.y = 2;

		obj2.transform.position.x = -20;
		obj2.transform.position.y = -20;
		*/

		haxeScript = HXFile.fromFile("assets/script/test/New1.hx");
		var haxeScript2:HaxeScript = HXFile.fromFile("assets/script/test/New2.hx");
		haxeScript.backend.setScriptVar("otherScript",haxeScript2);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.F12)
		{
			haxeScript.backend.doFunction("test");
		}
	}

	@:access(openfl.display.DisplayObjectRenderer, openfl.display.Sprite, openfl.display.Stage, lime._internal.backend.native.NativeCFFI, lime._internal.backend.native.NativeWindow, lime.ui.Window, openfl.display.Graphics)
	function screenshit() {
		
		trace("screenshot");

		var screenBitmap = FlxGamePlus.lastFrame;
		//var actuallyReadable = new BitmapData(Application.current.window.width, Application.current.window.height, true, 0xFFFFFFFF);

		//FUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU
		//Main.instance.stage.context3D.drawToBitmapData(actuallyReadable);

		var bytes:ByteArray = new ByteArray();
		bytes = screenBitmap.encode(screenBitmap.rect, new PNGEncoderOptions(true), bytes);
		File.saveBytes("TestImage.png", bytes);
		
		//actuallyReadable.dispose();
		//actuallyReadable = null;

		bytes.clear();
		bytes = null;
	}

}
