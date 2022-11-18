package common;

import lime.app.Application;
import lime.app.Event;
import lime.ui.KeyCode;
import lime.ui.KeyModifier;
import openfl.Lib;

class Keyboard {

    public static function initialize() {
		Application.current.window.onTextInput.add(_onTextInput, false, 1000); //try to have higher priority than whatever cancels it normally
		Application.current.window.onKeyDown.add(_onKeyDown);
		Application.current.window.onKeyUp.add(_onKeyUp);
    }



    public static var shift:Bool = false;
	public static var alt:Bool = false;
    public static var control:Bool = false;

	public static var ui_only:Bool = false;

	//------------------------------------------------------------------------- global
	public static var onTextInput(default, null) = new Event<String->Void>();
	public static var onKeyDown(default, null) = new Event<KeyCode->Void>();
	public static var onKeyUp(default, null) = new Event<KeyCode->Void>();

	public static var onKeyDownUnfiltered(default, null) = new Event<KeyCode->Void>();
	public static var onKeyUpUnfiltered(default, null) = new Event<KeyCode->Void>();

	//------------------------------------------------------------------------- UI
	public static var onUiTextInput(default, null) = new Event<String->Void>();
	public static var onUiKeyDown(default, null) = new Event<KeyCode->Void>();
	public static var onUiKeyUp(default, null) = new Event<KeyCode->Void>();

	public static var onUiKeyDownUnfiltered(default, null) = new Event<KeyCode->Void>();
	public static var onUiKeyUpUnfiltered(default, null) = new Event<KeyCode->Void>();


	static var keys:Map<KeyCode, Bool> = new Map(); //shouldn't ever get out of hand??? unless having every key accounted for isn't what you're after.
	//never seen memory usage increase when pressing keys.

	static function _onTextInput(s:String) {
        //ACCURATE FOR TYPING!!! may be useful for inputs but onKeyDown is still preferred
		onUiTextInput.dispatch(s);
		if(!ui_only) onTextInput.dispatch(s);
    }

    static function _onKeyDown(key:KeyCode, mod:KeyModifier) {
		//Accurate for inputs(?)
		shift = mod.shiftKey;
		alt = mod.altKey;
		control = mod.ctrlKey;
		if(keys[key] == null || keys[key] == false){
			keys[key] = true;
			onUiKeyDown.dispatch(key);
			if(!ui_only) onKeyDown.dispatch(key);
		}

		onUiKeyDownUnfiltered.dispatch(key);
		if(!ui_only) onKeyDownUnfiltered.dispatch(key);
    }

	static function _onKeyUp(key:KeyCode, mod:KeyModifier) {
        //Accurate for inputs
		shift = mod.shiftKey;
		alt = mod.altKey;
		control = mod.ctrlKey;
		if(keys[key] == null || keys[key] == true){
			keys[key] = false;
			onUiKeyUp.dispatch(key);
			if(!ui_only) onKeyUp.dispatch(key);
		}

		onUiKeyUpUnfiltered.dispatch(key);
		if(!ui_only) onKeyUpUnfiltered.dispatch(key);
    }
}