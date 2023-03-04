package gameside.inventory;

import gameside.inventory.Item.ItemStack;
import gameside.inventory.ItemContainer;

/**
 * Item container with either limited or unlimited space on 1 axis, used most effectively in a list-like interface.
 */
class ItemContainerList implements ItemContainer{
	var exists:Bool = true;
    
    public var maxSize(get,set):Int;
    private var _maxSize:Int = 0;
    private var _limitedSpace:Bool = false;

    public var storage:Array<ItemStack>;

	public function new(?maxLength:Int = 0) {
		storage = [];
		maxSize = maxLength;
	}

	public function destroy() {
		if(!exists) return;

        exists = false;

		for (slot in storage) {
			if(slot != null)
				slot.destroy();
		}

		storage.resize(0);
		storage = null;
	}

	//------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------

	public function addItem(stack:ItemStack, ?x:Int = 0, ?y:Int = 0, ?destroyStackIfMerge:Bool):Bool {
		if(!exists) return false;

		if(_limitedSpace && storage.length >= maxSize) return false;

		var index:Int = storage.push(stack);
		stack.index = index;

		stack.setPosition(0,index);

		return true;
	}

	public function addItemToFirstAvailableSlot(stack:ItemStack, ?destroyStackIfMerge:Bool):Bool {
		return addItem(stack);
	}

	//moving

	public function moveItem(index:Int, ?x:Int, ?y:Int, ?destroyStackIfMerge:Bool):Bool {
		var stack:ItemStack = storage[index];
        if(stack == null) return false;

		storage.remove(stack);
		storage.insert(index,stack);

		for (i in 0...storage.length) {
			storage[i].index = i;
		}

		return false;
	}

	public function rotateItem(index:Int, by:Int) {
		var stack:ItemStack = storage[index];
        if(stack == null) return;
		
		stack.rotate(by);
	}

	//removing

    public function removeItemByName(idName:String, ?destroy:Bool = true):Void {
        if(!exists) return;

		var curStack:ItemStack = null;

        for (stack in storage) {
			if(stack.id == idName) curStack = stack;
		}

		if(curStack != null) removeStack(curStack, destroy);
    }

    public function removeItemStackByName(idName:String, stack:Int, ?destroy:Bool = true):Void {
        if(!exists) return;
        //this is the only way to remove quantity of a specific item without having direct access to the item.
        
        //accounts for stacks.
		var curStack:ItemStack = null;

        for (stack in storage) {
			if(stack.id == idName) curStack = stack;
		}

		if(curStack == null) return;
		curStack.quantity -= stack;

		if(curStack.quantity < 1) removeStack(curStack, destroy);
    }

	public function removeItemAt(x:Int, y:Int, ?destroy:Bool) {
		if(!exists) return;
		removeStack(storage[y], destroy);
	}

	public function removeItemStackAt(x:Int, y:Int, stack:Int, ?destroy:Bool) {
		if(!exists) return;

		var curStack:ItemStack = storage[y];

		if(curStack == null) return;
		curStack.quantity -= stack;

		if(curStack.quantity < 1) removeStack(curStack, destroy);
	}

    //misc?

	public function getItemAt(x:Int,y:Int):ItemStack {
        if(!exists) return null;
        if(storage[y] == null) return null;
        
        return storage[y];
    }

	public function getItemIndexAt(x:Int,y:Int):Int {
        if(!exists) return null;
        if(storage[y] == null) return -1;

        return y;
    }

	public function transferItemAt(x:Int, y:Int, to:ItemContainer, ?toX:Int = -1, ?toY:Int = -1) {
        var item = getItemAt(x,y);
        if(item == null) return;

        removeItemAt(x,y,false);

        if(toX >= 0 && toY >= 0) to.addItem(item, toX, toY);
        else to.addItemToFirstAvailableSlot(item);
    }

	//------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------

	private inline function removeStack(stack:ItemStack, ?destroy:Bool = true) {
		stack.positionX = -1;
		stack.positionY = -1;

        if(destroy) stack.destroy();

		var index:Int = storage.indexOf(stack);
		storage.remove(stack);
		for (i in index...storage.length) {
            storage[i].index = i;
        }
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