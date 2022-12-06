//-------------------------------------------------------
//                   IMPORTS
//-------------------------------------------------------
import("CoreState", "core");
import("MainState", "Main");
import("utility.LogFile", "Log");
import("Console", "Console");
import("assets.AssetCache", "AssetCache");
import("sys.io.File", "File");
import("oop.Component", "Component");
//-------------------------------------------------------
//-------------------------------------------------------

function OnAwake()
{
	//hook up custom plugin updater
	core.tryUpdatePlugin = PluginUpdate;
	
	//add useful stuff to the end of component scripts
	Component.componentStandard = File.getContent("assets/script/main/util/componentstandard.hx");
	
	Console.log("\n------------------------------\nMAIN SCRIPT PROCESS\n", Console.CONSOLE_COLOR_1);
	Log.log("Hooks set.");
	
	//Pretty essential and its like 9 pixels worth of memory, who's gonna complain??
	AssetCache.cacheImage("embed/debug/ramSaver.png");
	
	#if debug
		//fuck the debug warnings.
		AssetCache.cacheData("embed/debug/TestSliced.asset");
		AssetCache.cacheImage("embed/debug/testSliced.png");

		AssetCache.cacheImage("embed/ui/default_item.png");
		AssetCache.cacheData("embed/ui/default_item.asset");
		
		AssetCache.cacheImage("embed/components/Sprite.png");
	#end
}

function OnStart()
{
	Log.log("Main script init.");
}

function OnUpdate(elapsed:Float)
{

}

function OnLateUpdate(elapsed:Float)
{

}

function PluginUpdate(plugin:String):Bool
{	
	return true;
}

function OnDraw()
{

}

function OnDestroy()
{

}

function OnSave()
{

}

function OnLoad()
{

}