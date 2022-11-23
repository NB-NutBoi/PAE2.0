package gameside.inventory;

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

    private var storage:Array2D<ItemSlot>;

    public function new(width:Int, height:Int) {
        storage = new Array2D(width,height);
        resize(width,height);
    }

    public function destroy() {
        if(!exists) return;

        exists = false;

        for (array in storage.array) {
            for (slot in array) {
                if(slot.item != null)
                    slot.item.destroy();
            }
        }
        
        storage.clear();
        storage = null;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------

    //managing items

    //adding

    public function addItem(item:Item, ?x:Int = 0, ?y:Int = 0):Bool { //adding requires the item class, but afterwards everything is handled with the item id
        if(!exists) return false;
        if(!storage.exists(x,y)) return false;

        var toSlot = storage.get(x,y);
        if(toSlot.occupied){
            if(toSlot.item == null) toSlot = storage.get(toSlot.itemSourceX, toSlot.itemSourceY);
            if(toSlot.item == null) return false; //idk what happened but my guess is a bug.
            
            if(item.itemFile == toSlot.item.itemFile && item.ammount == toSlot.item.ammount && item.id == toSlot.item.id){
                if(toSlot.item.maxQuantity > 1){
                    //can hold multiple

                    toSlot.item.quantity += item.quantity;
                    var diff = toSlot.item.quantity - toSlot.item.maxQuantity;

                    if(diff > 0){
                        toSlot.item.quantity -= diff;
                        item.ammount = diff;
                        //technically failed but added as much item stack as it could.
                        return false;
                    }     //success!
                    else return true;
                }
            }
        }
        else if(fitsAround(item, x, y)) {
            toSlot.item = item;
            toSlot.occupied = true;

            toSlot.item.positionX = toSlot.x;
		    toSlot.item.positionY = toSlot.y;
            
            if(item.itemWidth == 1 && item.itemHeight == 1) return true;

            for (extraX in 1...item.itemWidth) {
                for (extraY in 1...item.itemHeight) {
                    var extraSpace = storage.get(x + extraX, y + extraY);
    
                    extraSpace.occupied = true;
                    extraSpace.itemSourceX = x;
                    extraSpace.itemSourceY = y;
                }
            }

            return true;
        }

        return false;
    }

    public function addItemToFirstAvailableSlot(item:Item):Bool {
        if(!exists) return false;
        
        for (y in 0...storage.height) {
            for (x in 0...storage.width) {
                if(addItem(item,x,y) == true){
                    return true;
                }
            }
        }

        return false;
    }

    //removing

    public function removeItemByIdName(idName:String, ?destroy:Bool = true):Void {
        if(!exists) return;

        //doesn't account for stacks.

        for (y in 0...storage.height) {
            for (x in 0...storage.width) {
                var curSlot = storage.get(x,y);
                if(curSlot.item.id == idName){
                    removeFromSlot(curSlot, destroy);
                    break;
                }
            }
        }
    }

    public function removeItemStackByName(idName:String, stack:Int, ?destroy:Bool = true):Void {
        if(!exists) return;
        //this is the only way to remove quantity of a specific item without having direct access to the item.
        
        //accounts for stacks.
        for (y in 0...storage.height) {
            for (x in 0...storage.width) {
                var curSlot = storage.get(x,y);
                if(curSlot.item.id == idName){

                    curSlot.item.quantity -= stack;

                    if(curSlot.item.quantity < 1){
                        removeFromSlot(curSlot, destroy);
                    }
                    
                    break;
                }
            }
        }
    }

    public function removeItemAt(x:Int, y:Int, ?destroy:Bool = true) {
        if(!exists) return;
        if(!storage.exists(x,y)) return;

        var curSlot = storage.get(x,y);
        if(curSlot.itemSourceX != -1 && curSlot.itemSourceY != -1) curSlot = storage.get(curSlot.itemSourceX,curSlot.itemSourceY);

        removeFromSlot(curSlot, destroy);
    }

    public function removeItemStackAt(x:Int, y:Int, stack:Int, ?destroy:Bool = true) {
        if(!exists) return;
        if(!storage.exists(x,y)) return;

        var curSlot = storage.get(x,y);
        if(curSlot.itemSourceX != -1 && curSlot.itemSourceY != -1) curSlot = storage.get(curSlot.itemSourceX,curSlot.itemSourceY);

        curSlot.item.quantity -= stack;

        if(curSlot.item.quantity < 1){
            removeFromSlot(curSlot, destroy);
        }
    }

    //misc?

    public function getItemAt(x:Int,y:Int):Item {
        if(!exists) return null;
        if(!storage.exists(x,y)) return null;
        
        var theSlot = storage.get(x,y);

        if(theSlot.itemSourceX != -1 && theSlot.itemSourceY != -1) theSlot = storage.get(theSlot.itemSourceX,theSlot.itemSourceY);

        return theSlot.item;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------

    private function fitsAround(item:Item, x:Int, y:Int):Bool {
        if(item.itemWidth == 1 && item.itemHeight == 1) return true; //it's a 1x1, a check to see if it fits within the given coordinates has already been made, so it will fit.
        if(item.itemWidth-1 + x > storage.width || item.itemHeight-1 + y > storage.height) return false; //too big to fit within the bounds if placed here.

        var fits:Bool = true;
        for (extraX in 1...item.itemWidth) {
            for (extraY in 1...item.itemHeight) {
                var checking = storage.get(x + extraX, y + extraY);

                if(checking.occupied){
                    fits = false;
                    break;
                }
            }
        }

        return fits;
    }

    private function removeReferencesFor(forX:Int, forY:Int) {
        if(forX == -1 || forY == -1) return;
        
        for (y in 0...storage.height) {
            for (x in 0...storage.width) {
                if(storage.get(x,y).occupied == true && (storage.get(x,y).itemSourceX == forX && storage.get(x,y).itemSourceY == forY) && storage.get(x,y).item == null){

                    storage.get(x,y).occupied = false;
                    storage.get(x,y).itemSourceX = -1;
                    storage.get(x,y).itemSourceY = -1;
                }
            }
        }
    }

    private inline function removeFromSlot(slot:ItemSlot, ?destroy:Bool = true) {
        if(slot.item.itemWidth > 1 || slot.item.itemHeight > 1) removeReferencesFor(slot.x,slot.y);

        slot.item.positionX = -1;
		slot.item.positionY = -1;

        if(destroy) slot.item.destroy();

        slot.item = null;
        slot.occupied = false;
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
        if(newHeight != storage.height || newWidth != storage.width) storage.modifySize(newWidth, newHeight);

        for (y in 0...newHeight)
        {   
            for (x in 0...newWidth)
            {
                if(storage.get(x,y) == null){
                    storage.set(x,y,{
                        item: null,
                        itemSourceX: -1,
                        itemSourceY: -1,
                        x: x,
                        y: y,
                        occupied: false
                    });
                }
            }
        }
    }

    public function toString():String {
        return Std.string(storage);
    }
}