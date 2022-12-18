package rendering;

import common.ClientPreferences;
import utility.Language;
import flixel.text.FlxText;

using StringTools;

class Text extends FlxText {

    override public function new(X:Float = 0, Y:Float = 0, FieldWidth:Float = 0, ?Text:String, Size:Int = 8, EmbeddedFont:Bool = true) {
        super(X,Y,FieldWidth,Text,Size,EmbeddedFont);
        antialiasing = ClientPreferences.globalAA;
    }

    override function update(elapsed:Float) {
        if(!done){
            if(waiting){
                toWait-=elapsed;
                if(toWait <= 0){
                    waiting = false;
    
                    var char:Null<Int> = toWrite.charCodeAt(curChar);
    
                    if(char == null){
                        onDone();
                    }
                    else{
                        curChar++;
                        writeChar(String.fromCharCode(char));
                    }
                }
            }
        }

        super.update(elapsed);
    }

    override function destroy() {
        if(LanguageManager.listeners.has(updateLang)){
            LanguageManager.listeners.remove(updateLang);
        }

        super.destroy();
    }

    //-----------------------------------------------------------------------------
    //AUTOTYPE

    var toWrite:String = "";
    var curChar:Int = 0;

    public var delay:Float = 0.025;

    public var done:Bool = true; //never change this unless using autotype.
    var waiting:Bool = false;
    var toWait:Float = 0;

    public var funcChars:Map<String, Void->Void> = new Map();
    public var waitChars:Map<String, Float> = new Map();

    public var onDoneWriting:Void->Void;

    public function write(w:String) {
        if(!done){
            skip();
            return;
        }

        text = "";
        
        var with_symbols = w;
        var with_out_symbols = w;
        for (s in funcChars.keys()) {
            with_out_symbols = with_out_symbols.replace(s,"");
        }

        for (s in waitChars.keys()) {
            with_out_symbols = with_out_symbols.replace(s,"");
        }

        applyMarkup(with_symbols,Main.textFormat);
        with_symbols = text;

        applyMarkup(with_out_symbols,Main.textFormat);
        toWrite = with_symbols;
        text = "";
        toWait = delay;
        waiting = true;
        done = false;
    }

    public function writeInstant(w:String) {
        write(w);
        skip();
    }

    public function clear() {
        applyMarkup("",Main.textFormat);
    }

    function skip() {
        if(done) return;
        
        while(toWrite.charCodeAt(curChar) != null){
            var char:Null<Int> = toWrite.charCodeAt(curChar);

            curChar++;
            writeChar(String.fromCharCode(char));
        }

        onDone();
    }

    function writeChar(char:String) {
        if(funcChars[char] != null){
            funcChars[char]();
            toWait = 0;
            waiting = true;
            return;
        }

        if(waitChars[char] != null){
            toWait = waitChars[char];
            waiting = true;
            return;
        }

        text += char;
        toWait = delay;
        waiting = true;
    }

    function onDone() {
        toWrite = "";
        done = true;
        waiting = false;
        curChar = 0;

        funcChars.clear();
        waitChars.clear();

        if(onDoneWriting != null)
            onDoneWriting();
    }

    //-----------------------------------------------------------------------------
    //LANG STUFF

    public var langKey(default,set):String;

    function set_langKey(value:String):String {
		if(langKey == value) return langKey;
		
        if((value == "" || value == null)){
            text = "";
            
            if(LanguageManager.listeners.has(updateLang)){
                LanguageManager.listeners.remove(updateLang);
            }
            
            return langKey = value;
        }


        if(!LanguageManager.listeners.has(updateLang)){
            LanguageManager.listeners.add(updateLang);
        }

        text = LanguageManager.getText(value);

		return langKey = value;
	}


    final public function updateLang() {
		text = LanguageManager.getText(langKey);
    }

    //technically autotype but whatever

    public function writeLang(key:String) {
        write(LanguageManager.getText(key));
    }

    public function writeInstantLang(key:String) {
        writeInstant(LanguageManager.getText(key));
    }
    
}