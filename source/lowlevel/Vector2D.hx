package lowlevel;

import haxe.ds.Vector;
import haxe.iterators.ArrayKeyValueIterator;

class Vector2DTest
{
    public static function main()
    {
        // 2D array, technically variable size, but you'll have to initialise them. Sometimes slower.
        var a2d = new Array2D(3,5);

        a2d.set(0,0, "Top Left");
        a2d.set(2,4, "Bottom Right");

        trace (a2d);
        // [[Top Left,null,null,null,null],[null,null,null,null,null],[null,null,null,null,Bottom Right]]
    }
}











/**
 * Dynamic version of Vector2D.
 * 
 * Stores a two-dimensional array of objects and provides functions to effectively interact with it.
 * * Generally slower than vector2d but can be resized.
 * @author NutBoi
 */
class Array2D<T>
{
    /**
     * Backend array, this cannot be modified after it is created.
     */
    public var array(default, null):Array<Array<T>>;

    /**
     * Width of the vector, this can only be set on creation and modifySize().
     */
    public var width(default, null):Int = 0;

    /**
     * Height of the vector, this can only be set on creation and modifySize().
     */
    public var height(default, null):Int = 0;


    public function new(w:Int, h:Int) {
        modifySize(w,h);
    }

    /**
     * Gets the object within the given coordinates.
     * @param x The X position of the object within the array.
     * @param y The Y position of the object within the array.
     * @return The object allocated on the coordinates given, null if it hasn't been set or exceeds the array bounds.
     */
    public inline function get(x:Int, y:Int):T {
        return array[x][y]; // it'll return null if it hasn't been set or doesn't exist so no need to do checks here
    }

    /**
     * Sets the object within the given coordinates.
     * @param x The future X position of the object within the array.
     * @param y The future Y position of the object within the array.
     * @param to The object to be set.
     * @return The object set, it won't set the object within the array if the coordinates given exceed the array bounds.
     */
    public inline function set(x:Int, y:Int, to:T):T {
        if(exists(x,y)) return array[x][y] = to else return to;
    }

    /**
     * Checks if the array bounds contain the given coordinates.
     * @param x X coordinate to be checked.
     * @param y Y coordinate to be checked.
     * @return True if the coordinates exist within the array bounds, False if they exceed the bounds or are below 0.
     */
    public inline function exists(x:Int, y:Int):Bool {
        return (width > x && height > y) && (x>=0 && y>=0);
    }


    /**
     * Modifies the bounds of the array.
     * @param w new width of the array.
     * @param h new height of the array.
     * This *should* keep the previous objects intact, unless they exist outside the new bounds.
     */
    public function modifySize(w:Int, h:Int) {
        if(array == null) array = [];

        for (i in 0...width) {
            if(array[i] != null) array[i].resize(w);
        }

        for (x in 0...w)
        {
            if(array[x] == null) array[x] = [];
            
            for (y in 0...h)
            {
                if(y >= height) array[x][y] = null;
            }
        }

        width = w;
        height = h;
    }

    public function clear() {
        for (x in 0...width)
        { 
            for (y in 0...height)
            {
                array[x][y] = null;
            }
        }
    }

    
    public function toString():String {
        var s = "\n[\n";
        for (i in 0...array.length) {
            s+= "X: "+i+" "+Std.string(array[i])+"\n";
        }
        s+="]";
        return s;
    }
}

/**
 * Static version of Array2D.
 * 
 * Stores a two-dimensional vector of objects and provides functions to effectively interact with it.
 * * Generally faster than array2d but can't be resized.
 * @author NutBoi
 */
class Vector2D<T>
{
    /**
     * Backend vector, this cannot be modified after it is created.
     */
    public var vector(default, null):Vector<Vector<T>>;

    /**
     * Width of the vector, this cannot be modified after it is created.
     */
    public var width(default, null):Int = 0;

    /**
     * Height of the vector, this cannot be modified after it is created.
     */
    public var height(default, null):Int = 0;


    
    public function new(w:Int, h:Int) {
        //static so no need for a modify function.

        width = w;
        height = h;

        vector = new Vector<Vector<T>>(w);
        for (i in 0...w)
        {
            vector[i] = new Vector<T>(h);
        }
    }


    /**
     * Gets the object within the given coordinates.
     * @param x The X position of the object within the vector.
     * @param y The Y position of the object within the vector.
     * @return The object allocated on the coordinates given, null if it hasn't been set or exceeds the vector bounds.
     */
     public inline function get(x:Int, y:Int):T {
        return vector[x][y]; // it'll return null if it hasn't been set or doesn't exist so no need to do checks here
    }

    /**
     * Sets the object within the given coordinates.
     * @param x The future X position of the object within the vector.
     * @param y The future Y position of the object within the vector.
     * @param to The object to be set.
     * @return The object set, it won't set the object within the vector if the coordinates given exceed the vector bounds.
     */
    public inline function set(x:Int, y:Int, to:T):T {
        if(exists(x,y)) return vector[x][y] = to else return to;
    }

    /**
     * Checks if the vector bounds contain the given coordinates.
     * @param x X coordinate to be checked.
     * @param y Y coordinate to be checked.
     * @return True if the coordinates exist within the vector bounds, False if they exceed the bounds or are below 0.
     */
    public inline function exists(x:Int, y:Int):Bool {
        return (width > x && height > y) && (x>=0 && y>=0);
    }

    


    
    public function toString():String {
        var s = "\n[\n";
        for (i in 0...vector.length) {
            s+= "X: "+i+" "+Std.string(vector[i])+"\n";
        }
        s+="]";
        return s;
    }
}