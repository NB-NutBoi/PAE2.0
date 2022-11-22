package lowlevel;

import openfl.Lib;
import utility.Utils;
import openfl.events.IOErrorEvent;
import openfl.events.Event;
import openfl.net.FileFilter;
import openfl.net.FileReference;

using StringTools;

enum FileResult {
    SELECT;
    SAVE;
    CANCEL;
    ERROR;
}

//helper class to more efficiently save/load files with the lime/openfl fileReference window.
@:access(openfl.net.FileReference)
class FileBrowser {

    static var _file:FileReference;
    static var load:Bool = false; //optional loading (might only need the path idk)

    /**
     * Result of the latest operation.
     * ERROR by default.
     */
    public static var latestResult:FileResult = ERROR; //ERROR is default, as nothing's been loaded or saved yet.

    /**
     * Path to the last referenced file. (save/browse)
     */
    public static var filePath:String = ""; 

    /**
     * Data from the last loaded file. (browse)
     */
    public static var fileData:String = "";

    /**
     * Single-use callback that gets called after any process end(save/load)
     * 
     * Will get reset after.
     */
    public static var callback:Void->Void;

    static function prepare() {
        _file = new FileReference();
        _file.addEventListener(Event.CANCEL, onCancel);
        _file.addEventListener(IOErrorEvent.IO_ERROR, onError);
    }

    public static function browse(?filter:Array<FileFilter> = null, ?load:Bool = true) {
        prepare();
        _file.addEventListener(Event.SELECT, selectFile);

        FileBrowser.load = load;

        latestResult = SELECT; //temp for other functions

        _file.browse(filter);
    }

    public static function save(content:Dynamic, ?defaultName:Null<String>) {
        prepare();
        _file.addEventListener(Event.COMPLETE, saveFile);

        latestResult = SAVE; //temp for other functions

        _file.save(content, defaultName);
    }

    //-------------------------------------------------------------------------------------------------
    //-------------------------------------------------------------------------------------------------

    static function saveFile(_) {

        latestResult = SAVE;

        filePath = Utils.relativePath(_file.__path);

        //clean
        _file.removeEventListener(Event.COMPLETE, saveFile);
        _file.removeEventListener(Event.CANCEL, onCancel);
        _file.removeEventListener(IOErrorEvent.IO_ERROR, onError);
        _file = null;

        if(callback != null) callback();
        callback = null;
    }

    static function selectFile(_) {
        
        latestResult = SELECT;

        filePath = Utils.relativePath(_file.__path);

        if(load){
            _file.load();
            fileData = _file.data.toString().trim();
        }

        //clean
        _file.removeEventListener(Event.SELECT, selectFile);
        _file.removeEventListener(Event.CANCEL, onCancel);
        _file.removeEventListener(IOErrorEvent.IO_ERROR, onError);
        _file = null;

        if(callback != null) callback();
        callback = null;
    }

    //-------------------------------------------------------------------------------------------------

    static function onCancel(_) {

        //clean
        if(latestResult == SELECT) _file.removeEventListener(Event.SELECT, selectFile);
        else if(latestResult == SAVE) _file.removeEventListener(Event.COMPLETE, saveFile);
        _file.removeEventListener(Event.CANCEL, onCancel);
        _file.removeEventListener(IOErrorEvent.IO_ERROR, onError);
        _file = null;

        latestResult = CANCEL;

        if(callback != null) callback();
        callback = null;
    }

    static function onError(_) {

        //clean
        if(latestResult == SELECT) _file.removeEventListener(Event.SELECT, selectFile);
        else if(latestResult == SAVE) _file.removeEventListener(Event.COMPLETE, saveFile);
        _file.removeEventListener(Event.CANCEL, onCancel);
        _file.removeEventListener(IOErrorEvent.IO_ERROR, onError);
        _file = null;

        latestResult = ERROR;

        if(callback != null) callback();
        callback = null;
    }
}