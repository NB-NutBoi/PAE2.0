package gameside.inventory;

import gameside.inventory.ItemContainer;

/**
 * Item container with either limited or unlimited space on 1 axis, used most effectively in a list-like interface.
 */
class ItemContainerList implements ItemContainer{
	var exists:Bool = true;
    
    public var maxSize(get,set):Int;
    private var _maxSize:Int = 0;
    private var _limitedSpace:Bool = false;

    public var storage:Array<ItemSlot>;

	public function new(?maxLength:Int = 0) {
		storage = [];
		maxSize = maxLength;
	}

	public function destroy() {
		if(!exists) return;

        exists = false;

		for (slot in storage) {
			if(slot.item != null)
				slot.item.destroy();
		}

		storage.resize(0);
		storage = null;
	}

	//------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------

	public function addItem(item:Item, ?x:Int = 0, ?y:Int = 0):Bool {
		if(!exists) return false;

		if(_limitedSpace && storage.length >= maxSize) return false;

		var theSlot = null;
		storage.push( theSlot = {
			item: item,
			itemSourceX: -1,
			itemSourceY: -1,
			x: 0,
			y: storage.length,
			occupied: true
		});

		theSlot.item.positionX = theSlot.x;
		theSlot.item.positionY = theSlot.y;

		return true;
	}

	public function addItemToFirstAvailableSlot(item:Item):Bool {
		return addItem(item);
	}

	//removing

    public function removeItemByIdName(idName:String, ?destroy:Bool = true):Void {
        if(!exists) return;

		var curSlot:ItemSlot = null;

        for (slot in storage) {
			if(slot.item.id == idName){
				curSlot = slot;
			}
		}

		if(curSlot != null) removeSlot(curSlot, destroy);
    }

    public function removeItemStackByName(idName:String, stack:Int, ?destroy:Bool = true):Void {
        if(!exists) return;
        //this is the only way to remove quantity of a specific item without having direct access to the item.
        
        //accounts for stacks.
		if(!exists) return;

		var curSlot:ItemSlot = null;

        for (slot in storage) {
			if(slot.item.id == idName){
				curSlot = slot;
			}
		}

		if(curSlot == null) return;
		curSlot.item.quantity -= stack;

		if(curSlot.item.quantity < 1){
			removeSlot(curSlot, destroy);
		}
    }

	public function removeItemAt(x:Int, y:Int, ?destroy:Bool) {
		if(!exists) return;

		var curSlot:ItemSlot = storage[y];

		if(curSlot != null) removeSlot(curSlot, destroy);
	}

	public function removeItemStackAt(x:Int, y:Int, stack:Int, ?destroy:Bool) {
		if(!exists) return;

		var curSlot:ItemSlot = storage[y];

		if(curSlot == null) return;
		curSlot.item.quantity -= stack;

		if(curSlot.item.quantity < 1){
			removeSlot(curSlot, destroy);
		}
	}

    //misc?

    public function getItemAt(i:Int):Item {
        if(!exists) return null;
		if(storage.length-1 < i) return null;

		return storage[i].item;
    }

	//------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------

	private inline function removeSlot(slot:ItemSlot, ?destroy:Bool = true) {
		slot.item.positionX = -1;
		slot.item.positionY = -1;

        if(destroy) slot.item.destroy();

        slot.item = null;
        slot.occupied = false;
		storage.remove(slot);
    }

	function get_maxSize():Int {
		return _maxSize;
	}

	function set_maxSize(value:Int):Int {
        _limitedSpace = value > 0;
		return _maxSize = value;
	}

	public function toString():String {
        return Std.string(storage);
    }
}