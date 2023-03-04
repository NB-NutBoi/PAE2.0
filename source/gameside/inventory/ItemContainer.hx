package gameside.inventory;

import gameside.inventory.Item.ItemStack;

interface ItemContainer {
    private var exists:Bool;

    public function getItemAt(x:Int,y:Int):ItemStack;
    public function getItemIndexAt(x:Int,y:Int):Int;

    public function addItem(stack:ItemStack, ?x:Int, ?y:Int, ?destroyStackIfMerge:Bool):Bool;
    public function addItemToFirstAvailableSlot(stack:ItemStack, ?destroyStackIfMerge:Bool):Bool;

    public function moveItem(index:Int, ?x:Int, ?y:Int, ?destroyStackIfMerge:Bool):Bool;
    public function rotateItem(index:Int, by:Int):Void;

    public function removeItemByName(idName:String, ?destroy:Bool = true):Void;
    public function removeItemStackByName(idName:String, stack:Int, ?destroy:Bool = true):Void;

    public function removeItemAt(x:Int, y:Int, ?destroy:Bool = true):Void;
    public function removeItemStackAt(x:Int, y:Int, stack:Int, ?destroy:Bool = true):Void;

    public function transferItemAt(x:Int, y:Int, to:ItemContainer, ?toX:Int = -1, ?toY:Int = -1):Void;
}

typedef ItemSlotPos = {
    public var x:Int;
    public var y:Int;
}

typedef ItemContainerCache = {
    public var items:Array<ItemContainerCache>;
    public var slots:Array<Array<Int>>;
}