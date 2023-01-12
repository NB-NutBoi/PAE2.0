package gameside.inventory;

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
    public var maxQuantity:Int;
    public var defaultAmmount:Float;
    public var langId:String;
    public var textures:Array<ItemTexture>;
    public var curTexture:Int;
    public var iWidth:Int;
    public var iHeight:Int;
}

class Item {
    public static var registeredItems:Map<String,Item> = new Map(); //Future rework (items'll work like minecraft items registering-wise in the future)

    //technical
    public var exists:Bool = true;


    //file
    public var itemFile:String;
    

    //can be changed at runtime
    public var id:String; //item id for using on world buttons and stuff
    public var curGraphic:Int;
    public var ammount:Float;
    public var quantity:Int;

    public var dynamicItemProperties:Dynamic;

    public var positionX:Int;
    public var positionY:Int;


    //defined by file, never to change.
    public var maxQuantity:Int;
    public var sprites:Array<String> = [];
    public var spriteWidth:Int = 100;
    public var spriteHeight:Int = 100;
    
    //how many slots the item takes.
    public var itemWidth:Int = 1;
    public var itemHeight:Int = 1;



    public function destroy() {
        
    }
}