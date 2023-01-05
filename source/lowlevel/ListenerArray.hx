package lowlevel;

import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSignal.FlxTypedSignal;
import flixel.util.typeLimit.OneOfTwo;
import haxe.iterators.ArrayKeyValueIterator;

typedef VarArray<T> = OneOfTwo<Array<T>,ListenerArray<T>>;

class ListenerArray<T>
{
	var length(get, never):Int;
	function get_length():Int {
		return array.length;
	}

	public var onArrayModify(default, null) = new FlxTypedSignal<Void->Void>();
	public var onArrayAdd(default, null) = new FlxTypedSignal<T->Void>();
	public var onArrayRemove(default, null) = new FlxTypedSignal<T->Void>();
    
	private var array:Array<T> = new Array<T>();

    public function new() {

    }

	@:noCompletion private static function fromArray<T>(prevArray:Array<T>):ListenerArray<T> {
		var array = new ListenerArray<T>();
        array.array = prevArray;
        return array;
    }

	public function concat(a:VarArray<T>):ListenerArray<T> {
        if(Std.isOfType(a, Array))
            array.concat(a);

		if(Std.isOfType(a, ListenerArray))
		{
            var fake:ListenerArray<T> = a;
			array.concat(fake.array);
        }

        return this;
    }
	public function join(sep:String):String {
		return array.join(sep);
    }
	public function pop():Null<T> {
		var popped = array.pop();
		onArrayRemove.dispatch(popped);
		onArrayModify.dispatch();
        return popped;
    }
	public function push(x:T):Int {
		var idx = array.push(x);
		onArrayAdd.dispatch(x);
		onArrayModify.dispatch();
        return idx;
    }
	public function reverse():Void {
        array.reverse();
		onArrayModify.dispatch();
    }
	public function shift():Null<T> {
		var shifted = array.shift();
        onArrayRemove.dispatch(shifted);
        onArrayModify.dispatch();
        return shifted;
    }
    //MIGHT NOT WANNA USE, no good way to "event" this.
	public function slice(pos:Int, ?end:Int):Array<T> {
		return array.slice(pos, end);
    }
	public function sort(f:T->T->Int):Void {
		array.sort(f);
		onArrayModify.dispatch();
    }
	public function splice(pos:Int, len:Int):ListenerArray<T>{
		array.splice(pos, len);
		onArrayModify.dispatch();
		return this;
    }
	public function toString():String{
        return array.toString();
    }
	public function unshift(x:T):Void{
        array.unshift(x);
		onArrayAdd.dispatch(x);
		onArrayModify.dispatch();
    }
	public function insert(pos:Int, x:T):Void
	{
		array.insert(pos, x);
		onArrayAdd.dispatch(x);
		onArrayModify.dispatch();
	}
	public function remove(x:T):Bool
	{
        var removed = array.remove(x);
        onArrayRemove.dispatch(x);
        onArrayModify.dispatch();
		return removed;
	}
	public function contains(x:T):Bool
	{
        return array.contains(x);
	}
	public function indexOf(x:T, ?fromIndex:Int):Int
	{
		return array.indexOf(x,fromIndex);
	}
	public function lastIndexOf(x:T, ?fromIndex:Int):Int
	{
		return array.lastIndexOf(x, fromIndex);
	}

	public function copy():ListenerArray<T>
	{
		return ListenerArray.fromArray(array.copy());
	}

	@:runtime inline public function map<S>(f:T->S):Array<S>
	{
		return array.map(f);
	}

	@:runtime inline public function filter(f:T->Bool):Array<T>
	{
		return array.filter(f);
	}

	@:runtime inline public function iterator():haxe.iterators.ArrayIterator<T>
	{
		return array.iterator();
	}

	@:runtime inline public function keyValueIterator():ArrayKeyValueIterator<T>
	{
		return array.keyValueIterator();
	}

    //makes sure to kill all the events.
    public function kill() {
        FlxDestroyUtil.destroy(onArrayAdd);
		FlxDestroyUtil.destroy(onArrayModify);
		FlxDestroyUtil.destroy(onArrayRemove);

        array = null;
    }
}