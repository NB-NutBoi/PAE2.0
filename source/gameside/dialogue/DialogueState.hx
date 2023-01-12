package gameside.dialogue;

import JsonDefinitions.ScriptVariable;
import haxe.DynamicAccess;

/**
 * NOT SAVEABLE!!!
 * (redo every time script is loaded.)
 */
typedef Dialogue = {
    public var onStart:Null<Void->Void>;
    public var onDoneTyping:Null<Void->Void>;
    public var onAdvance:Null<Void->Void>;
    public var onLoad:Null<Void->Void>;
}

//(Saveable)
typedef DialogueCache = {
    public var script:String;
    public var scriptVars:DynamicAccess<ScriptVariable>;
    public var currentDialogue:Int;
}

class DialogueState {
    
    public var dialogues:Map<Int, Dialogue>;

    public var currentDialogue:Int = 0;

    public function goToDialogue(to:Int) {
        if(dialogues[to] == null) return;

        currentDialogue = to;

        dialogues[currentDialogue].onStart();
    }

    public function loadToDialogue(to:Int) {
        if(dialogues[to] == null) return;

        currentDialogue = to;

        dialogues[currentDialogue].onLoad();
    }

}