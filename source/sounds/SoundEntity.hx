package sounds;

import assets.SoundAsset;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.system.FlxSound;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import flixel.util.FlxStringUtil;

@:allow(oop.premades.AudioSourceComponent)
class SoundEntity implements IFlxDestroyable{

    public var playing:Bool = false;
    private var curAsset:Null<SoundAsset>;

    private var inst:FlxSound;
    private var vocals:Array<FlxSound> = [];

    public var onSoundDone:SoundEntity->Void;

    public var pan(get,set):Float;
    public var volume(get,set):Float;
    public var radius(get,set):Float;

    public var pauseWithGame:Bool = false;
    public var pausedWithGame:Bool = false;
    
    public function new(asset:SoundAsset) {
        if(asset == null) return;

        setAsset(asset);
    }

    public function setAsset(asset:SoundAsset) {
        curAsset = asset;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------

    /**
     * MAKE SURE YOU KNOW WHAT YOU'RE DOING!! HAVE PROXIMITY SET UP PROPERLY!!
     * @param x x position of the sound
     * @param y y position of the sound
     */
     public function setPosition(x:Float, y:Float) {
        for (sound in vocals) {
            sound.setPosition(x,y);
        }
		return inst.setPosition(x,y);
    }

    /**
     * MAKE SURE YOU KNOW WHAT YOU'RE DOING!!
     * 
     * This sets up proximity | MAKE SURE THIS IS SETUP BEFORE USING SETPOSITION!!
     * @param x initial x position
     * @param y initial y position
     * @param target tracking target
     * @param radius radius of the sound
     * @param pan (optional) wether or not to use panning, default is true.
     */
    public function setProximity(x:Float, y:Float, target:FlxObject, radius:Float, ?pan:Bool = true) {
        for (sound in vocals) {
            sound.proximity(x,y, target, radius, pan);
        }
        inst.proximity(x,y, target, radius, pan);
    }

    @:access(flixel.system.FlxSound)
    public function removeProximity() {
        for (sound in vocals) {
            sound._target = null;
            sound.x = 0;
            sound.y = 0;

            sound._radius = 0;
            sound._proximityPan = false;
        }

        inst._target = null;
        inst.x = 0;
        inst.y = 0;

        inst._radius = 0;
        inst._proximityPan = false;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------

    /**
     * Begins playing the sound. this restarts it if it isn't stopped, recommend calling it only once and then using pause/unpause to control it.
     * 
     * Requires a sound asset to be set.
     */
    public function play() {
        if(curAsset == null) return;
        if(playing) stop();

        inst = FlxG.sound.load(curAsset.inst, 1, curAsset.loop);
        inst.persist = true; //dont want bullshit crashes like last time.

        inst.onComplete = soundDone;

        inst.pause();

        for (sound in curAsset.vocals) {
            var vt = FlxG.sound.load(sound, 1, curAsset.loop);
            vt.pause();
            vt.persist = true;
            vocals.push(vt);
        }
        
        unpause();
    }

    /**
     * WARNING: this does not pause the sound, this stops the sound and removes it from memory if it's not marked as important.
     * 
     * Use pause() if you need to stop it temporarily.
     */
    public inline function stop() {
        if(curAsset == null || !playing) return;
        
        playing = false;

        if(inst != null)
        inst.onComplete = null;

        inst.stop();
        inst.persist = false;
        inst.destroy();
        inst = null;

        for (vocal in vocals) {
            vocal.stop();

            vocal.persist = false;
            vocal.destroy();
        }

        vocals.resize(0);

        if(!curAsset.important)
            curAsset.destroy();
    }

    /**
     * Unpauses the sound, does nothing if it's already unpaused.
     */
    public function unpause() {
        if(curAsset == null || playing) return;

        playing = true;

        resyncVocals();
    }

    /**
     * Pauses the sound, does nothing if it's already paused.
     */
    public function pause() {
        if(curAsset == null || !playing) return;

        playing = false;

        inst.pause();

        for (vocal in vocals) {
            vocal.pause();
        }
    }

    private function resyncVocals() {
        if(curAsset == null) return;

        for (vocal in vocals) {
            vocal.pause();
        }
        

		inst.play();
        var time = inst.time;

        for (vocal in vocals) {
            vocal.time = time;
            vocal.play();
        }
    }

    private function soundDone() {
        if(curAsset.loop) return;
        stop();

        if(onSoundDone != null)
            onSoundDone(this);
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------

	private function get_pan():Float {
		return inst.pan;
	}

	private function set_pan(value:Float):Float {
        for (sound in vocals) {
            sound.pan = value;
        }
		return inst.pan = value;
	}

    function get_volume():Float {
		return inst.volume;
	}

	function set_volume(value:Float):Float {
		for (sound in vocals) {
            sound.volume = value;
        }
        return inst.volume = value;
	}

    @:access(flixel.system.FlxSound)
    function get_radius():Float {
		return inst._radius;
	}

    @:access(flixel.system.FlxSound)
	function set_radius(value:Float):Float {
        for (sound in vocals) {
            sound._radius = value;
        }
		return inst._radius = value;
	}

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------

	public function destroy() {
        stop();
        
        curAsset = null;
    }

    public function toString():String {
        return "Sound: "+ curAsset == null ? "none set." : curAsset.key;
    }

}