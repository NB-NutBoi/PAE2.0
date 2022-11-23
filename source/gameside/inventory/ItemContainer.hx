package gameside.inventory;

typedef ItemSlot = {
    public var item:Item; // only the top left corner of the item should contain the item, the rest should be a reference to the correct slots
    public var itemSourceX:Int;
    public var itemSourceY:Int;

    public var x:Int;
    public var y:Int;

    public var occupied:Bool; //faster calculations for bigger items?
}

interface ItemContainer {
    private var exists:Bool;

    public function getItemAt(x:Int,y:Int):Item;

    public function addItem(item:Item, ?x:Int, ?y:Int):Bool;
    public function addItemToFirstAvailableSlot(item:Item):Bool;

    public function removeItemByIdName(idName:String, ?destroy:Bool = true):Void;
    public function removeItemStackByName(idName:String, stack:Int, ?destroy:Bool = true):Void;

    public function removeItemAt(x:Int, y:Int, ?destroy:Bool = true):Void;
    public function removeItemStackAt(x:Int, y:Int, stack:Int, ?destroy:Bool = true):Void;

    public function transferItemAt(x:Int, y:Int, to:ItemContainer, ?toX:Int = -1, ?toY:Int = -1):Void;
}

typedef ItemContainerCache = {
    
}