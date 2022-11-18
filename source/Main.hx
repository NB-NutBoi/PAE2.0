package;

import Discord;
import FlxGamePlus;
import assets.AssetPaths;
import common.ConfigFile;
import common.Keyboard;
import flixel.FlxG;
import flixel.math.FlxPoint;
import flixel.text.FlxText.FlxTextFormat;
import flixel.text.FlxText.FlxTextFormatMarkerPair;
import flixel.util.FlxColor;
import haxe.ds.StringMap;
import haxe.io.Path;
import lime.app.Application;
import lime.app.Event;
import lime.graphics.Image;
import lowlevel.Ruler;
import lowlevel.Vector2D.Vector2DTest;
import oop.Component;
import openfl.Lib;
import openfl.display.BitmapData;
import openfl.display.Sprite;
import openfl.media.Sound;
import openfl.system.System;
import openfl.text.Font;
import openfl.utils.Assets;
import sys.FileSystem;
import ui.DMenu;
import utility.ConsoleCommands;
import utility.FpsMemory;
import utility.LogFile;

using StringTools;

class Main extends Sprite
{										//always indev if it's a debug build.
	public static final buildType:BuildType = #if debug INDEV; #else INDEV; #end
	public static var instance:Main;						//modify the second one.

	public static final defaultFunctions:Array<String> = ["OnAwake", "OnUpdate", "OnDraw", "OnDestroy", "OnStart", "OnUpdateInputs", "OnPostUpdate"];
	public static final GameVersion:String = "2.0";
	public static var discordRPC_id:String = "897169048599666718";

	public static var DEBUG:Bool = false;

	public static var Paused(default,set):Bool = false;
	public static var onPauseGame(default,null):Event<Void->Void> = new Event<Void->Void>();
	public static var onUnpauseGame(default,null):Event<Void->Void> = new Event<Void->Void>();

	public static var onTryCloseGame(default,null):Event<Void->Void> = new Event<Void->Void>();
	public static var ConfigsAvailable:StringMap<String> = new StringMap();

	public static var crash_prevention_bitmap:BitmapData;
	public static var crash_prevention_string:String;
	public static var crash_prevention_sound:Sound;

	public static var SetupConfig:ConfigFile;

	//default
	static var greenFormat = new FlxTextFormat(FlxColor.GREEN);
    static var limeGreenFormat = new FlxTextFormat(FlxColor.LIME);
    static var redFormat = new FlxTextFormat(FlxColor.RED);
    static var yellowFormat = new FlxTextFormat(FlxColor.YELLOW);
    static var boldFromat = new FlxTextFormat(null,true,false);
	static var defaultTextFormat:Array<FlxTextFormatMarkerPair> = [
        new FlxTextFormatMarkerPair(greenFormat, "<G>"),
        new FlxTextFormatMarkerPair(limeGreenFormat, "<LG>"),
        new FlxTextFormatMarkerPair(redFormat, "<R>"),
        new FlxTextFormatMarkerPair(yellowFormat, "<Y>"),
        //dunno if this one works, it does nothing from testing (it requires a supported font bruhg)
        new FlxTextFormatMarkerPair(boldFromat, "<BOLD>")
    ];

    public static var textFormat:Array<FlxTextFormatMarkerPair> = [];

	static function makeFormat(format:String, color:FlxColor) {
		trace(format + ", "+ color.toHexString());
		var nFormat = new FlxTextFormat(color);
		var marker = new FlxTextFormatMarkerPair(nFormat,format);
		switch (format){ //allow overriding defaults
			case "<G>":
				textFormat[0] = marker;
			case "<LG>":
				textFormat[1] = marker;
			case "<R>":
				textFormat[2] = marker;
			case "<Y>":
				textFormat[3] = marker;
			case "<BOLD>":
				textFormat[4] = marker;
			default:
				textFormat.push(marker);
		}
		
	}

	public static var memPeak:Float;
	public static var mempeak:String;
	public static var mempeakGaugue:String;

	var nofps = false;

	public static function main():Void
	{
		//first called when launching the game.
		Keyboard.initialize();
		Component.registerStandardComponents();

		Lib.current.addChild(new Main());

		//make sure game can't be closed accidentally, as long as this is added to the event, it won't close.
		Application.current.window.onClose.add(OnTryCloseGame);
	}

	public static var game:FlxGamePlus;
	static var fps:FPS_Mem;

	public function new()
	{
		super();
		instance = this;

		crash_prevention_bitmap = Assets.getBitmapData("embed/assetPrevention/Image_not_found.png");
		crash_prevention_string = Assets.getText("embed/assetPrevention/Data_not_found.txt").toString();
		crash_prevention_sound = Assets.getSound("embed/assetPrevention/Sound_not_found.ogg");

		configure();
		addEventListener(openfl.events.Event.ENTER_FRAME, onEnter);

		
		
		game = new FlxGamePlus(
			SetupConfig.getConfig("GameWidth", "int", 1920),
			SetupConfig.getConfig("GameHeight", "int", 1080),DebugState,
			SetupConfig.getConfig("Zoom", "float", -1),
			SetupConfig.getConfig("Framerate", "int", 61),
			SetupConfig.getConfig("Framerate", "int", 61),
			SetupConfig.getConfig("SkipSplash", "bool", true),
			//SetupConfig.getConfig("StartFullscreen", "bool", false)
			false
		);

		addChild(game);

		if(!nofps){
			fps = new FPS_Mem(10, 3, 0xFFFFFF);
			addChild(fps);

			fps.visible = true;
		}

		ConsoleCommands.setupConsole();
		Console.bringToFront();

		FlxG.autoPause = false;
		FlxG.mouse.useSystemCursor = true;

		#if windows
		if(SetupConfig.getConfig("discordRPC_enabled", "bool", false) == true)
			DiscordClient.initialize();
		#end
	}

	//configuring steps are fine as is but it's not really ideal, someone should look at a better loading system or steps.
	private function configure()
	{
		textFormat.resize(0);
		textFormat = defaultTextFormat.copy();

		var args = Sys.args();

		

		var configFolder:String = "config";

		for (arg in args) {
			switch (arg){
				case "-livereload": //no idea what it is
					continue;
				case "-nofps":
					nofps = true;
				case "debug", "-debug":
					DEBUG = true;
				default:
					if(FileSystem.exists(arg)){
						if(FileSystem.isDirectory(arg)){
							//assume it's a config folder.
							configFolder = arg;
						}
						else{
							//add some sort of single-file control?
						}
					}
			}
		}

		//------------------------------------------------------------------------------------------------------------------------------------------------------------
		//------------------------------------------------------------------------------------------------------------------------------------------------------------

		
		
		var allConfigsPresent:Bool = true;

		var files:Array<String> = AssetPaths.getPathList(configFolder,null,["cfg"]);
		for (s in files) {
			ConfigsAvailable.set(new Path(s).file,s);
		}

		if(!ConfigsAvailable.exists("Setup")) LogFile.fatalError("The required config Setup.cfg was not found!\n",1);
		
		SetupConfig = new ConfigFile(ConfigsAvailable.get("Setup"));

		if(ConfigsAvailable.exists("Markups")) {
			var textFormats = new ConfigFile(ConfigsAvailable.get("Markups"));
			
			trace(textFormats.configs);

			for (s in textFormats.configs.keys()) {
				makeFormat(s,FlxColor.fromString(textFormats.getConfig(s,"string","#372257")));
			}
		}

		LogFile.logCallerAndID = SetupConfig.getConfig("LogCallerAndID","bool",false);

		DEBUG = SetupConfig.getConfig("Debug", "bool", false);
		#if windows
		discordRPC_id = SetupConfig.getConfig("discordRPC_id", "String", "897169048599666718");
		#else
		discordRPC_id = "";
		#end

		#if debug
		DEBUG = true;
		#end

		//vcr font since the engine uses it as default.
		final defaultFont = Assets.getFont("embed/fonts/vcr.ttf",false);
		defaultFont.fontName = "vcr";
		Font.registerFont(defaultFont);

		Console.init(SetupConfig.getConfig("ConsoleFont","STRING","vcr"));

		LogFile.Init();

		LogFile.log("Launch args = "+args, true);
		LogFile.log("CONFIG FILES FOUND: "+ConfigsAvailable);

		if(!nofps && !DEBUG) nofps = true; 

		if(DEBUG) trace("DEBUG ENABLED");
		
		//EXTERNAL FONTS
		for (s in AssetPaths.getPathList(SetupConfig.getConfig("FontDirectory","STRING","assets/fonts"),null,["ttf","otf"])) {
			//trace(s);
			Font.registerFont(Font.fromFile(s));
			LogFile.log("Registered font "+s);
		}

		Component.registerComponents(SetupConfig.getConfig("ComponentFolder","STRING","assets/components"));
		
		//--------------------------------------------------------------------------------------

		Application.current.window.setIcon(_getWindowIcon(SetupConfig.getConfig("WindowIcon", "string", "embed/defaults/icon32.png")));
		Application.current.window.title = SetupConfig.getConfig("WindowName", "string", "PAE 2.0");

	}

	//guarantees a return, no matter how fucked the input is.
	function _getWindowIcon(path:String):Image {
		if(path.startsWith("embed") && Assets.exists(path)) return lime.utils.Assets.getImage(path);
		if(!FileSystem.exists(path)) return lime.utils.Assets.getImage("embed/defaults/icon32.png");
		return Image.fromFile(path);
	}

	public function onEnter(_) {
		
		//since FPSmem shouldn't exist on non-debug modes, we need to keep total ram used here.
		var mem = Math.round(System.totalMemory / 1024 / 1024 * 100) / 100;
		
		if (mem > memPeak)
		{
			memPeak = mem;

			mempeakGaugue = " MB";

			if ((memPeak / 1024) > 1)
			{
				mempeak = Std.string((memPeak / 1024));
				mempeakGaugue = " GB";
			}
			else
			{
				mempeak = Std.string(memPeak);
			}

			mempeak = mempeak + mempeakGaugue;
		}


		if (!nofps) fps.mempeak = mempeak;

	}

	public static function PreCloseGame() {

		//disable anti-window close.
		Application.current.window.onClose.remove(OnTryCloseGame);
		

		//DISCORD RICH PRESENCE
		#if windows
		close_discord();
		#end
		
		LogFile.log({message: "\nClosing Game\n-------------------------------\n\nMEM PEAK: " + mempeak + "\n", caller: "Main", id: 0});
	}

	public static function CloseGame() {
		PreCloseGame();

		trace("Closed game successfully.");
		Application.current.window.close();
		openfl.system.System.exit(0);
	}

	//will always stop the game from closing so long as it's added to the window close event
	public static function OnTryCloseGame() {
		if(DEBUG || onTryCloseGame.__listeners.length <= 0){
			CloseGame(); //Debug shouldn't have to go through the funny screen.
		}
		else{
			Application.current.window.onClose.cancel();
			onTryCloseGame.dispatch();
		}
	}

	#if windows
	static function close_discord() {
		DiscordClient.shutdown();
	}
	#end

	static function set_Paused(value:Bool):Bool {
		var changed = value != Paused;
		Paused = value;

		if(changed){
			switch (Paused){
				case true:
					onPauseGame.dispatch();
				case false:
					onUnpauseGame.dispatch();
			}
		}

		return Paused;
	}
}

enum BuildType {
	INDEV;
	PRIVATE_BUILD;
	TESTER_BUILD;
	PRE_RELEASE;
	RELEASE;
}