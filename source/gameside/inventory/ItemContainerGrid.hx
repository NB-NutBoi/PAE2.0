package gameside.inventory;

import utility.LogFile;
import gameside.inventory.Item;
import gameside.inventory.ItemContainer;
import lowlevel.Vector2D.Array2D;

//this class should:
/*
Be able to load a graphic interface state from save data.
Not be responsible for the interface's functionality, but the other way around.
*/

/**
 * Item container with limited space on 2 axis, used most effectively in a grid-like interface.
 */
class ItemContainerGrid implements ItemContainer {
    var exists:Bool = true;

    private var items:Array<ItemStack>;
    private var slots:Array2D<Int>;

    public function new(width:Int, height:Int) {
        slots = new Array2D(width,height);
        resize(width,height);
    }

    public function destroy() {
        if(!exists) return;

        exists = false;

        for (array in slots.array) {
            for (slot in array) {
                if(slot > -1) items[slot].destroy();
            }
        }
        
        slots.clear();
        slots = null;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    //managing items

    //adding

    public function addItem(stack:ItemStack, ?x:Int = 0, ?y:Int = 0, ?destroyStackIfMerge:Bool = true):Bool { //adding requires the item class, but afterwards everything is handled with the item id
        if(!exists) return false;
        if(!slots.inBounds(x,y)) return false;

        var toSlot = slots.get(x,y);
        
        if(toSlot > -1) return items[toSlot].mergeStack(stack,destroyStackIfMerge);
        else if(fitsAround(stack,x,y))
        {
            var index:Int = items.push(stack);
            stack.index = index;
            stack.setPosition(x,y);
            slots.set(x,y,index);

            if(stack.item.itemWidth == 1 && stack.item.itemHeight == 1) return true;

            setItemCorner(index,x,y);

            return true;
        }

        return false;
    }

    public function addItemToFirstAvailableSlot(stack:ItemStack, ?destroyStackIfMerge:Bool = true):Bool {
        if(!exists) return false;

        var prevRotation = stack.curRotation;
        var iterateWidth:Int = slots.width - (stack.item.itemWidth-1);
		var iterateHeight:Int = slots.height - (stack.item.itemHeight-1);

        stack.curRotation = 0;
        
        for (y in 0...iterateHeight) {
            for (x in 0...iterateWidth) {
                if(addItem(stack,x,y,destroyStackIfMerge) == true){
                    return true;
                }
            }
        }

        if(stack.item.itemWidth == stack.item.itemHeight) return false;

        //Non-rotated failed, try swapping axis. (rotating)
        iterateWidth = slots.width - (stack.item.itemHeight-1);
		iterateHeight = slots.height - (stack.item.itemWidth-1);

        stack.curRotation = 1;

        for (y in 0...iterateHeight) {
            for (x in 0...iterateWidth) {
                if(addItem(stack,x,y,destroyStackIfMerge) == true){
                    return true;
                }
            }
        }

        stack.curRotation = prevRotation;

        return false;
    }

    //moving

    public function moveItem(index:Int, ?x:Int = 0, ?y:Int = 0, ?destroyStackIfMerge:Bool = true):Bool {
        var stack:ItemStack = items[index];
        if(stack == null) return false;

        var toSlot:Int = slots.get(x,y);

        if(toSlot > -1) return items[toSlot].mergeStack(stack,destroyStackIfMerge);
        else if(fitsAround(stack,x,y))
        {
            replaceReferencesFor(index, -1);
            setItemCorner(index,x,y);

            return true;
        }

        return false;
    }

    public function rotateItem(index:Int, by:Int) {
        var stack:ItemStack = items[index];
        if(stack == null) return;

        var prevRotation = (stack.drag ? stack.tempRotation : stack.curRotation);
        stack.rotate(by);

        if(stack.drag) return;
        if(fitsAround(stack,stack.positionX,stack.positionY))
        {
            replaceReferencesFor(index, -1);
            setItemCorner(index,stack.positionX,stack.positionY);

            return;
        }

        stack.drag ? stack.tempRotation = prevRotation : stack.curRotation = prevRotation;
    }

    //removing

    public function removeItemByName(idName:String, ?destroy:Bool = true):Void {
        if(!exists) return;

        //doesn't account for stacks.
        for (i in 0...items.length) {
            if(items[i].id == idName) { removeItem(i, destroy); break; }
        }
    }

    public function removeItemStackByName(idName:String, stack:Int, ?destroy:Bool = true):Void {
        if(!exists) return;
        //this is the only way to remove quantity of a specific item without having direct access to the item.
        
        //accounts for stacks.
        for (i in 0...items.length) {
            if(items[i].id == idName)
            {
                items[i].quantity -= stack;
                if(items[i].quantity < 1) removeItem(i, destroy);

                break;
            }
        }
    }

    public function removeItemAt(x:Int, y:Int, ?destroy:Bool = true) {
        if(!exists) return;
        if(!slots.inBounds(x,y)) return;
        
        var atSlot:Int = slots.get(x,y);
        if(atSlot <= -1) return;

        removeItem(atSlot, destroy);
    }

    public function removeItemStackAt(x:Int, y:Int, stack:Int, ?destroy:Bool = true) {
        if(!exists) return;
        if(!slots.inBounds(x,y)) return;

        var atSlot:Int = slots.get(x,y);
        if(atSlot <= -1) return;

        items[atSlot].quantity -= stack;

        if(items[atSlot].quantity < 1) removeItem(atSlot, destroy);
    }

    //misc?

    public function getItemAt(x:Int,y:Int):ItemStack {
        if(!exists) return null;
        if(!slots.inBounds(x,y)) return null;

        var atSlot:Int = slots.get(x,y);
        if(atSlot <= -1) return null;

        return items[atSlot];
    }

    public function getItemIndexAt(x:Int,y:Int):Int {
        if(!exists) return null;
        if(!slots.inBounds(x,y)) return null;

        return slots.get(x,y);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    private function fitsAround(stack:ItemStack, x:Int, y:Int):Bool {
        if(stack.item.itemWidth == 1 && stack.item.itemHeight == 1) return true; //it's a 1x1, a check to see if it fits within the given coordinates has already been made, so it will fit.
        if(stack.item.itemWidth-1 + x > slots.width || stack.item.itemHeight-1 + y > slots.height) return false; //too big to fit within the bounds if placed here.

        var calcRotation:Int = (stack.drag ? stack.tempRotation : stack.curRotation);

        for (extraX in 1...stack.item.itemWidth) {
            for (extraY in 1...stack.item.itemHeight) {
                if((calcRotation % 2 == 0 ? slots.get(x + extraX, y + extraY) : slots.get(x + extraY, y + extraX)) > -1) return false;
            }
        }

        return true;
    }

    private function replaceReferencesFor(forIndex:Int, to:Int = -1) {
        if(forIndex == -1) return;
        
        for (y in 0...slots.height) {
            for (x in 0...slots.width) {
                if(slots.get(x,y) == forIndex) slots.set(x,y, to);
            }
        }
    }

    private function removeItem(index:Int, ?destroy:Bool = true){
        replaceReferencesFor(index, -1);

        items[index].setPosition(-1,-1);

        if(destroy) items[index].destroy();

        items.remove(items[index]);
        for (i in index...items.length) {
            replaceReferencesFor(items[i].index, i);
            items[i].index = i;
        }
    }

    private function setItemCorner(index:Int, x:Int, y:Int){
        var stack:ItemStack = items[index];
        if(stack == null) return;
        if(stack.item.itemWidth == 1 && stack.item.itemHeight == 1) return;
        var calcRotation:Int = (stack.drag ? stack.tempRotation : stack.curRotation);
        
        for (extraX in 1...stack.item.itemWidth) {
            for (extraY in 1...stack.item.itemHeight) {
                calcRotation % 2 == 0 ? slots.set(x + extraX, y + extraY,index) : slots.set(x + extraY, y + extraX,index);
            }
        }

        stack = null;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------

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

    //resizes the grid and generates new slots if needed.
    public function resize(newWidth:Int, newHeight:Int) {
        if(newHeight != slots.height || newWidth != slots.width) slots.modifySize(newWidth, newHeight);

        for (y in 0...newHeight)
        {   
            for (x in 0...newWidth)
            {
                if(slots.get(x,y) == null){
                    slots.set(x,y,-1);
                }
            }
        }
    }

    public function toString():String {
        return Std.string(slots);
    }
}