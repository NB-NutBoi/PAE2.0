package utility;

import openfl.net.FileFilter;
import lowlevel.FileBrowser;
import leveleditor.LevelEditor;
import flixel.FlxG;
import saving.SaveManager;
import FlxGamePlus.UIPlugin;
import openfl.display.PNGEncoderOptions;
import openfl.utils.ByteArray;
import pgr.dconsole.DC;
import sys.io.File;
import ui.DMenu;
import ui.premades.DebugMenu;

using Console.ConsoleStringTools;
using StringTools;

class ConsoleCommands {
    
    public static function setupConsole() {
        if(!Main.DEBUG) return;
        Console.registerCommand(takeDebugScreenshot, "screenshot", "", "Saves a screenshot of the game as an image.", "Saves a screenshot of the game as an image.");
        
        Console.registerCommand(testDebugSave, "save", "", "Saves the game to a test save file.", "Saves the game to a test save file.");
        Console.registerCommand(testDebugLoad, "load", "", "Loads a debug save file.", "Loads a debug save file.");

        Console.registerCommand(openWindow, "open", "", "Opens a DMenu.", "Opens a DMenu.\n
        Default menus are:\n\n
        DebugMenu - A debug menu with some stuff to modify the standard systems.");

        Console.registerCommand(closeWindow, "close", "", "Closes an open DMenu.", "Closes an open DMenu.");

        Console.registerCommand(closeGame, "closegame", "", "Closes the game window.", "Closes the game window.");
        Console.registerCommand(testCloseGameScreen, "testCloseGameScreen", "", "tests the closing game screen.", "tests the closing game screen.");


        Console.registerCommand(openLevelEditor, "openLevelEditor", "levelEditor", "Opens the level editor.", "Opens the level editor.");
        Console.registerCommand(openMainState, "openMain", "main", "Opens the Main state.", "Opens the Main state.");


        Console.registerCommand(toggleFps, "togglefps", "fps", "Toggles the debug fps viewer.", "Toggles the debug fps viewer.");
    }

    static function takeDebugScreenshot(args:Array<String>) {
        if(args[0] == null) args[0] = "TestImage";
        var filename = args[0];
        if(args.length > 1){
            for (i in 1...args.length) {
                filename += " "+args[i];
            }
        }

        if(!filename.endsWith(".png")) filename += ".png";
        
        var screenBitmap = FlxGamePlus.lastFrame;

		var bytes:ByteArray = new ByteArray();
		bytes = screenBitmap.encode(screenBitmap.rect, new PNGEncoderOptions(true), bytes);
		File.saveBytes(filename, bytes);

        Console.log(("Took screenshot and saved as: "+filename).toFunctionReply(), Console.FUNCTION_REPLY);

		bytes.clear();
		bytes = null;
    }

    static function testDebugSave(args:Array<String>) {
        if(args[0] == null) args[0] = "TestSave";
        var filename = args[0];
        if(args.length > 1){
            for (i in 1...args.length) {
                filename += " "+args[i];
            }
        }

        if(!filename.endsWith(".save")) filename += ".save";

        Console.log(("Saving game to file: "+filename+" ...").toFunctionReply(), Console.FUNCTION_REPLY);
        SaveManager.Save(filename);
    }

    static function testDebugLoad(args:Array<String>) {
        if(args[0] == null) args[0] = "TestSave";
        var filename = args[0];
        if(args.length > 1){
            for (i in 1...args.length) {
                filename += " "+args[i];
            }
        }

        if(!filename.endsWith(".save")) filename += ".save";

        Console.log(("Loading save file: "+filename+" ...").toFunctionReply(), Console.FUNCTION_REPLY);
        var meta = SaveManager.getSaveMetadata(filename);

        Utils.saveBitmapToImage(meta.image,"ReadOutput.png");
        Console.log(("Save date - "+meta.date).toFunctionReply(), Console.FUNCTION_REPLY);
        Console.log(("Saved metadata image test read as ReadOutput.png").toFunctionReply(), Console.FUNCTION_REPLY);

        SaveManager.Load(filename);
        Console.log(("Loaded save file "+filename).toFunctionReply(), Console.FUNCTION_REPLY);
    }


    static function openWindow(args:Array<String>) {
        if(args[0] == null){
            Console.log(("No dmenu argument given!").toFunctionReply(), Console.FUNCTION_REPLY_ERROR);
            return;
        }

        switch (args[0].toLowerCase()){//special cases
            case "level": loadLevel(); return; //no level dmenu can exist
        }


        final menu = getDMenu(args[0].toLowerCase());

        if(menu != null){
            if(!menu.open){
                UIPlugin.addContainer(menu);
                Console.log(("Opened DMenu "+ args[0]).toFunctionReply(), Console.FUNCTION_REPLY);
            }
        }
    }

    static function closeWindow(args:Array<String>) {
        if(args[0] == null){
            Console.log(("No window argument given!").toFunctionReply(), Console.FUNCTION_REPLY_ERROR);
            return;
        }


        final menu = getDMenu(args[0].toLowerCase());

        if(menu != null){
            if(menu.open){
                menu.close();
                Console.log(("Closed DMenu "+ args[0]).toFunctionReply(), Console.FUNCTION_REPLY);
            }
        }
    }

    static function getDMenu(id:String):DMenu {

        if(DMenu.menuKeys.exists(id)){
            final finalKey = DMenu.menuKeys.get(id);
            final menu = DMenu.menus.get(finalKey);
            return menu;
        }
        else{
            Console.log(("No DMenu registered with an id of "+id).toFunctionReply(), Console.FUNCTION_REPLY_WARN);
        }

        return null;
    }

    static function loadLevel() {
        FileBrowser.callback = loadLevelSelect;
        FileBrowser.browse([new FileFilter("Map files", "*.map")], false);
    }

    static function loadLevelSelect() {
        switch (FileBrowser.latestResult){
            case SAVE, CANCEL, ERROR: return;
            case SELECT: if(MainState.instance != null) MainState.instance.level.loadLevel(FileBrowser.filePath); 
        }
    }

    static function closeGame(args:Array<String>) {
        Main.CloseGame();
    }

    static function testCloseGameScreen(args:Array<String>) {
        Main.onTryCloseGame.dispatch();
    }

    static function openLevelEditor(args:Array<String>) {
        if(LevelEditor.instance == null) FlxG.switchState(new LevelEditor());
    }

    static function openMainState(args:Array<String>) {
        if(MainState.instance == null) FlxG.switchState(new MainState());
    }

    static function toggleFps(args:Array<String>) {
        Main.instance.toggleFps();
    }
}