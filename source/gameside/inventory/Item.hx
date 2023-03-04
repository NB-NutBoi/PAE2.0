package gameside.inventory;

import sys.FileSystem;
import sys.io.File;
import haxe.Json;
import files.HXFile;
import saving.SaveManager;
import common.HscriptTimer;
import JsonDefinitions;
import haxe.DynamicAccess;
import utility.LogFile;

using StringTools;

typedef ItemTexture = {
    public var nick:String;
    public var index:Int;
    public var path:String;
    public var width:Int;
    public var height:Int;
    public var xOffset:Float;
    public var yOffset:Float;
}

typedef ItemJson = {
    public var script:String;
    public var maxQuantity:Int;
    public var langId:String;
    public var textures:Array<ItemTexture>;
    public var curTexture:Int;
    public var iWidth:Int;
    public var iHeight:Int;
}

class ItemManager {
    //IS STATIC CLASS
    public static var init:Bool = false;
    public static var registeredItems:Map<String,Item> = new Map(); //Future rework (items'll work like minecraft items registering-wise in the future)

    public static var baseScript:Null<HaxeScript>; //IS ONLY FOR INTERACTING WITH OTHER GAME SCRIPTS, NOTHING ELSE

    ///////////////////////////////
    //INIT
    public static function Init() {
        init = true;

        CoreState.onSave.add(Save, false, 1000);
        CoreState.onLoad.add(Load, false, 1000);
    }

    public static function Save(_:String) {
        for (item in registeredItems) {
            cast(item.script, ItemScriptBackend).save();
        }
    }

    public static function Load(_:String) {
        for (item in registeredItems) {
            cast(item.script, ItemScriptBackend).load();
        }
    }

    ///////////////////////////////
    //REGISTERING
    public static function RegisterItem(id:String, path:String) {
        if(!init) return;
        if(id == "" || path == "") return;
        if(!FileSystem.exists(path) || !path.endsWith(".item")) return;

        var json:ItemJson = cast Json.parse(File.getContent(path));
        new Item(id, json);
    }
}

class Item {
    ///////////////////////////////
    //TECHNICAL
    public var id:String; //not the individual item, the id registered.
    public var exists:Bool = true;

    public var script:HaxeScript;

    public var lang:String;

    ///////////////////////////////
    //PROPERTIES
    public var maxQuantity:Int;
    public var sprites:Array<ItemTexture> = [];

    public var itemWidth:Int = 1;
    public var itemHeight:Int = 1;

    ///////////////////////////////
    //FUNCTIONS

    public function new(id:String, json:ItemJson) {
        this.id = id;

        if(json.script == null || json.script == "") { LogFile.error("Tried to register item "+id+" with no script!",true,true); return; }

        //-----------------------------------------//

        itemWidth = json.iWidth;
        itemHeight = json.iHeight;
        
        lang = json.langId;

        maxQuantity = json.maxQuantity;

        sprites = json.textures;

        //-----------------------------------------//

        script = HXFile.makeNew(ItemScriptBackend);
        cast(script.backend, ItemScriptBackend).item = this;
        if(ItemManager.baseScript != null) script.backend.AddGeneral("BaseScript",ItemManager.baseScript);
        HXFile.compileFromFile(script, json.script);

        //-----------------------------------------//

        ItemManager.registeredItems.set(id,this);
    }
}

class ItemScriptBackend extends SaveableHaxeScriptBackend
{
    public var item:Item;

    override public function new(frontend:HaxeScript) {
        super(frontend);
    }

    override function logWarning(Message:String, ?Trace:Bool = false, ?Print:Bool = false) {
        super.logWarning("[ItemScript: "+item.id+"] "+Message, Trace, Print);
    }

    override function logError(Message:String, ?Trace:Bool = false, ?Print:Bool = false) {
        super.logError("[ItemScript: "+item.id+"] "+Message, Trace, Print);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    override public function save() {
        if(!exists || !ready) return;
        super.save();

        SaveManager.curSaveData.itemStates.set(item.id, state);
    }

    override public function load() {
        if(!exists || !ready) return;

        //load custom savedata from cur save data
        if(SaveManager.curSaveData.itemStates.exists(item.id))
        state = SaveManager.curSaveData.itemStates.get(item.id);

        super.load();
    }
}

typedef ItemStackCache = {
    public var item:String;
    public var id:String;

    public var quantity:Int;
    public var curGraphic:Int;

    public var X:Int;
    public var Y:Int;
}

class ItemStack {
    
    public var item:Item;

    //can be changed at runtime
    public var id:String; //item id for using on world buttons and stuff
    public var quantity:Int;
    public var curGraphic:Int;
    
    public var curRotation:Int;
    public var tempRotation:Int;
    public var drag:Bool = false;

    public var dynamicItemProperties:Dynamic = null; //Remember this has to be saved so only basic types.

    public var positionX:Int;
    public var positionY:Int;

    public var index:Int;

    ///////////////////////////////
    //FUNCTIONS

    public function mergeStack(stack:ItemStack, ?destroyOnMerge:Bool = true):Bool {
        if(stack.item.id != item.id || stack.id != id) return false;
        if(item.maxQuantity <= 1) return false;

        if(stack.dynamicItemProperties != null)
        {
            if(dynamicItemProperties == null) dynamicItemProperties = {};

            //Add stack's properties to this.
            for (s in Reflect.fields(stack.dynamicItemProperties)) {
                if(!Reflect.hasField(dynamicItemProperties,s)) Reflect.setField(dynamicItemProperties,s,Reflect.field(stack.dynamicItemProperties,s));
            }
        }

        quantity += stack.quantity;
        var diff = quantity - item.maxQuantity;

        if(diff > 0)
        {
            quantity -= diff;
            stack.quantity = diff;
            //technically failed but added as much item stack as it could.
            return false;
        }
        else //success!
        {
            if(destroyOnMerge) stack.destroy();
            return true;
        }
    }

    public function rotate(by:Int) {
        if(item.itemWidth == item.itemHeight) { //Square item, cannot rotate.
			curRotation = 0; //Reset rotation just in case.
			return;
		}

        if(drag) {
            tempRotation += by;
            tempRotation = tempRotation % 4;
        }
        else {
            curRotation += by;
            curRotation = curRotation % 4;
        }
    }

    /**
     * Sets the position of the item (CORNER ONLY!!!)
     * @param x The x position
     * @param y The y position
     */
    public function setPosition(x:Int, y:Int) {
        positionX = x;
        positionY = y;
    }

    public function destroy() {
        
    }
}