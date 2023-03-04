package gameside.dialogue;

import files.HXFile.HaxeScript;
import JsonDefinitions.ScriptVariable;
import haxe.DynamicAccess;

/**
 * NOT SAVEABLE!!!
 * (redo every time script is loaded.)
 */
typedef Dialogue = {
    public var onEnter:Null<Bool->Void>;
    public var onDoneTyping:Null<Void->Void>;
    public var onAdvance:Null<Void->Void>;
}

//(Saveable)
typedef DialogueCache = {
    public var stage:String;
    public var script:String;
    public var currentDialogue:Int;
}

class DialogueState {
    
    public var dialogues:Map<Int, Dialogue>;

    public var currentDialogue:Int = 0;

    public function new() {
        dialogues = new Map();
    }

    public function goToDialogue(to:Int) {
        if(dialogues[to] == null) return;

        currentDialogue = to;

        dialogues[currentDialogue].onEnter(false);
    }

    public function loadToDialogue(to:Int) {
        if(dialogues[to] == null) return;

        currentDialogue = to;

        dialogues[currentDialogue].onEnter(true);
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public function advance() {
        if(dialogues[currentDialogue] == null) return;

        dialogues[currentDialogue].onAdvance();
    }

    public function onDoneTyping() {
        if(dialogues[currentDialogue] == null) return;

        dialogues[currentDialogue].onDoneTyping();
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //static functions

    public static function makeDialogue():Dialogue {
        return {
            onEnter: null,
            onDoneTyping: null,
            onAdvance: null
        }
    }

    public static function makeDialogueCache():DialogueCache {
        return {
            stage: null,
            script: null,
            currentDialogue: 0
        }
    }

}