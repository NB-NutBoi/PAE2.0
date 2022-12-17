package common;

import flixel.util.FlxDestroyUtil;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import common.BasicHscript.HScriptable;
import haxe.ds.StringMap;
import flixel.FlxBasic;

typedef HscriptTimerSave = {
    public var name:String;
    public var callback:String;

    public var length:Float;
    public var time:Float;

    public var loops:Int;

    public var paused:Bool;
    public var done:Bool;
}

//timers that are local to an individual hscript instance.
class HscriptTimer implements IFlxDestroyable {

    public var manager:HscriptTimerManager;

    public var name:String;
    public var callback:String;

    public var length:Float;
    public var time:Float;

    public var loops:Int;

    public var paused:Bool = true;
    public var done:Bool = false;

    public function new(id:String, call:String, t:Float, ?l:Int = 0) {
        name = id;
        callback = call;
        length = time = t;
        loops = l;
    }

    public function update(elapsed:Float) {
        if(done) return;
		
		if (!paused){
			time -= elapsed;
			if (time <= 0)
			{
				complete();
			}
    	}
    }

    public function complete():Void {
        manager.script.doFunction(callback,[name]);
		done = true;
	}

	public function cancel():Void {
		done = true;
	}

	public function reset(?newtime:Null<Float> = null):Void {
		if(newtime != null){
			length = newtime;
		}
        
        time = length;
        done = false;
	}

    public function loop() {
        loops--;
        var leftover = time;
        reset();
        time-=Math.abs(leftover); //no cheating
    }

	public function destroy():Void {
        manager = null;

        name = null;
        callback = null;
	}
}

//the manager within script files.
class HscriptTimerManager extends FlxBasic {

    public var script:HScriptable;

    var _timers:StringMap<HscriptTimer> = new StringMap();

    public static function load(from:Array<HscriptTimerSave>, owner:HScriptable):HscriptTimerManager {
        var manager = new HscriptTimerManager(owner);
        for (timerSave in from) {
            manager.loadTimer(timerSave);
        }

        return manager;
    }

    private function loadTimer(from:HscriptTimerSave) {
        final timer = new HscriptTimer(from.name,from.callback,from.length,from.loops);
        timer.manager = this;
        timer.time = from.time;
        timer.paused = from.paused;
        timer.done = from.done;
        _timers.set(from.name, timer);
    }

    public function saveTimers():Array<HscriptTimerSave> {
        var timers:Array<HscriptTimerSave> = [];

        for (s in _timers.keys()) {
            final timer = _timers.get(s);
			var timerSave:HscriptTimerSave = {
                name: timer.name,
                callback: timer.callback,
                length: timer.length,
                time: timer.time,
                loops: timer.loops,
                paused: timer.paused,
                done: timer.done
            }

            timers.push(timerSave);
		}

        return timers;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public function new(script:HScriptable)
    {
        super();

        // Don't call draw on this.
        visible = false;

        this.script = script;
    }

    override function destroy() {
        script = null;

        for (s in _timers.keys()) {
			_timers.get(s).cancel();
			_timers.set(s,FlxDestroyUtil.destroy(_timers.get(s)));
		}

        _timers.clear();
        _timers = null;

        super.destroy();
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        var removedThisFrame:Array<String> = null;

        for (key in _timers.keys()) {
            final timer = _timers.get(key);
            if(timer.done){
                if(timer.loops > 0) {
                    timer.loop();
                    timer.update(elapsed);
                    continue;
                }
                if(removedThisFrame == null) removedThisFrame = [];
                removedThisFrame.push(key);
                continue;
            }

            timer.update(elapsed);
        }

        if(removedThisFrame == null) return;

        for (s in removedThisFrame) {
            _timers.get(s).destroy();
            _timers.remove(s);
        }

        removedThisFrame = null;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public function StartNewTimer(name:String, time:Float, callback:String, ?loops:Int = 0):HscriptTimer {
        final timer = AddTimer(name,time,callback,loops);
        timer.paused = false;
        return timer;
    }

    public function AddTimer(name:String, time:Float, callback:String, ?loops:Int = 0):HscriptTimer {
        final timer = new HscriptTimer(name,callback,time,loops);
        timer.manager = this;
		_timers.set(name, timer);
        return timer;
  	}

    public function RemoveTimer(name:String, ?doComplete:Bool = false):Void {
        var t = _timers.get(name);
        if(t != null){
            doComplete ? t.complete() : t.cancel();
            t.destroy();
            _timers.remove(name);
        }

        t = null;
	}

    public function SetTimerPaused(name:String,paused:Bool):Void {
		final t = _timers.get(name);
		if (t != null)
			t.paused = paused;
	}

    public function ResetTimer(name:String, ?newtime:Null<Float> = null):Void {
		final t = _timers.get(name);
		if (t != null)
			t.reset(newtime);
	}

    public function TimerExists(name:String):Bool {
		final t = _timers.get(name);
		return (t != null);
	}
}