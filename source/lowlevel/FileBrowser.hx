package lowlevel;

import haxe.io.Path;
import sys.io.File;
import utility.LogFile;
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

    static var _file:FileReferencePlus;
    static var isUsing:Bool = false;
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
        _file = new FileReferencePlus();
        _file.addEventListener(Event.CANCEL, onCancel);
        _file.addEventListener(IOErrorEvent.IO_ERROR, onError);
        isUsing = true;
    }

    public static function browse(?filter:Array<FileFilter> = null, ?load:Bool = true) {
        if(isUsing) { LogFile.warning("cannot use file browser at this time: it is already in use."); return; }
        prepare();
        _file.addEventListener(Event.SELECT, selectFile);

        FileBrowser.load = load;

        latestResult = SELECT; //temp for other functions

        _file.browse(filter);
    }

    /**
     * [Description]
     * @param content content to save, null if you want the path.
     * @param defaultName 
     */
    public static function save(content:Dynamic, ?defaultName:Null<String>) {
        if(isUsing) { LogFile.warning("cannot use file browser at this time: it is already in use."); return; }
        prepare();
        _file.addEventListener(Event.SELECT, saveFile);

        latestResult = SAVE; //temp for other functions

        _file.save(content, defaultName);
    }

    //-------------------------------------------------------------------------------------------------
    //-------------------------------------------------------------------------------------------------

    static function saveFile(_) {
        latestResult = SAVE;

        filePath = Utils.relativePath(_file.__path);

        //clean
        _file.removeEventListener(Event.SELECT, saveFile);
        _file.removeEventListener(Event.CANCEL, onCancel);
        _file.removeEventListener(IOErrorEvent.IO_ERROR, onError);
        _file = null;

        isUsing = false;

        final thCallback = callback;
        callback = null;
        if(thCallback != null) thCallback();
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

        isUsing = false;

        final thCallback = callback;
        callback = null;
        if(thCallback != null) thCallback();
    }

    //-------------------------------------------------------------------------------------------------

    static function onCancel(_) {

        //clean
        if(latestResult == SELECT) _file.removeEventListener(Event.SELECT, selectFile);
        else if(latestResult == SAVE) _file.removeEventListener(Event.SELECT, saveFile);
        _file.removeEventListener(Event.CANCEL, onCancel);
        _file.removeEventListener(IOErrorEvent.IO_ERROR, onError);
        _file = null;

        latestResult = CANCEL; //set after check.

        isUsing = false;

        final thCallback = callback;
        callback = null;
        if(thCallback != null) thCallback();
    }

    static function onError(_) {

        //clean
        if(latestResult == SELECT) _file.removeEventListener(Event.SELECT, selectFile);
        else if(latestResult == SAVE) _file.removeEventListener(Event.SELECT, saveFile);
        _file.removeEventListener(Event.CANCEL, onCancel);
        _file.removeEventListener(IOErrorEvent.IO_ERROR, onError);
        _file = null;

        latestResult = ERROR; //set after check.

        isUsing = false;

        final thCallback = callback;
        callback = null;
        if(thCallback != null) thCallback();
    }
}

class FileReferencePlus extends FileReference {

    override private function saveFileDialog_onSelect(path:String):Void
    {
        #if desktop
        name = Path.withoutDirectory(path);

        if (__data != null)
        {
            File.saveBytes(path, __data);

            __data = null;
            __path = path; //WHY WAS THIS SO HARD TO HAVE BY DEFAULT!?!?!?!?
        }
        else
        {
            __path = path; //dont be fooled, you can't save nulls >:(
        }
        #end

        dispatchEvent(new Event(Event.SELECT));
    }

}