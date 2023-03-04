package common;

import flixel.tweens.FlxEase;
import utility.Utils;
import files.HXFile.HaxeScriptBackend;
import flixel.util.FlxDestroyUtil;
import haxe.ds.StringMap;
import flixel.FlxBasic;

typedef HscriptTimerSave = {
    public var name:String;
    public var callbacks:HscriptTimerCallbacks;

    public var length:Float;
    public var time:Float;

    public var loops:Int;

    public var paused:Bool;
    public var done:Bool;
}

typedef HscriptTimerCallbacks = {
    public var onComplete:Null<String>;
    public var onUpdate:Null<String>;
}

//timers that are local to an individual hscript instance.
class HscriptTimer implements IFlxDestroyable {

    public var manager:HscriptTimerManager;

    public var name:String;
    public var callbacks:HscriptTimerCallbacks;

    public var length:Float;
    public var time:Float;

    public var percent(get,never):Float;

    public var loops:Int;

    public var paused:Bool = true;
    public var done:Bool = false;

    public function new(id:String, call:HscriptTimerCallbacks, t:Float, ?l:Int = 0) {
        name = id;
        callbacks = call;
        length = time = t;
        loops = l;
    }

    public function update(elapsed:Float) {
        if(done) return;
		
		if (!paused){
            if(callbacks != null &&  (callbacks.onUpdate != "" && callbacks.onUpdate != null )) manager.script.doFunction(callbacks.onUpdate,[name,elapsed]);
            
			time -= elapsed;
			if (time <= 0)
			{
				complete();
			}
    	}
    }

    public function complete():Void {
        done = true;
        if(callbacks != null && (callbacks.onComplete != "" && callbacks.onComplete != null )) manager.script.doFunction(callbacks.onComplete,[name]);
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
        if(loops != -1) loops--;
        var leftover = time;
        reset();
        time-=Math.abs(leftover); //no cheating
    }

	public function destroy():Void {
        manager = null;

        name = null;
        callbacks = null;
	}

	function get_percent():Float {
		return 1-(Utils.clamp(time,0,length)/length);
	}
}

//the manager within script files.
class HscriptTimerManager extends FlxBasic {

    public var script:HaxeScriptBackend;

    var _timers:StringMap<HscriptTimer> = new StringMap();

    public static function load(from:Array<HscriptTimerSave>, owner:HaxeScriptBackend):HscriptTimerManager {
        var manager = new HscriptTimerManager(owner);
        for (timerSave in from) {
            manager.loadTimer(timerSave);
        }

        return manager;
    }

    private function loadTimer(from:HscriptTimerSave) {
        final timer = new HscriptTimer(from.name,from.callbacks,from.length,from.loops);
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
                callbacks: timer.callbacks,
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

    public function new(script:HaxeScriptBackend)
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
                if(timer.loops > 0 || timer.loops == -1) {
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
        timer.update(0); //initial frame update (won't take away time.)
        return timer;
    }

    public function AddTimer(name:String, time:Float, callback:String, ?loops:Int = 0):HscriptTimer {
        final timer = new HscriptTimer(name,
        {
            onComplete: callback,
            onUpdate: ""
        },
        time,loops);
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
		if (t != null) {
			t.paused = paused;
            t.update(0); //initial frame update (won't take away time.)
        }
	}

    public function ResetTimer(name:String, ?newtime:Null<Float> = null):Void {
		final t = _timers.get(name);
		if (t != null){
            t.reset(newtime);
            t.update(0); //initial frame update (won't take away time.)
        }
	}

    public function TimerExists(name:String):Bool {
		final t = _timers.get(name);
		return (t != null);
	}

    public function TimerPercent(name:String):Float {
        if(!TimerExists(name)) return 1;
        return _timers.get(name).percent;
    }

    public function GetTimer(name:String):HscriptTimer {
        return _timers.get(name);
    }

    //---------------------------------------------------------------//

    public function SetTimerCompleteCallback(name:String,callback:String):Void {
		final t = _timers.get(name);
		if (t != null)
			t.callbacks.onComplete = callback;
	}

    public function SetTimerUpdateCallback(name:String,callback:String):Void {
		final t = _timers.get(name);
		if (t != null) {
			t.callbacks.onUpdate = callback;
            t.update(0); //initial frame update (so the update function gets called before draw.)
        }
	}
}