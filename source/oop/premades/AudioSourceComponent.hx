package oop.premades;

import files.HXFile.Import;
import files.HXFile.HaxeScript;
import common.HscriptTimer;
import oop.Component;
import assets.SoundAsset;
import common.ClientPreferences;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.display.shapes.FlxShape;
import flixel.addons.display.shapes.FlxShapeCircle;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil.LineStyle;
import lowlevel.Ruler;
import sounds.SoundEntity;
import utility.LogFile;

//better optimized component for playing audio clips
class AudioSourceComponent extends Component {

    //default
    public var clip:SoundEntity;
    private var usesEvents:Bool = false;

    //playOneShot support
    public var clips:Array<SoundEntity>; //they're more or less completely sepparated from this, they inherit the properties when they're created only.

    //only used if its proximity, global by default.
    public var usingProximity:Bool = false;
    public var usingProximityPanning:Bool = false;
    public var radius(get,set):Float; 

    public var offsetX:Float = 0;
    public var offsetY:Float = 0;

    private var panning:Float = 0;

    //debug
    public var drawDebug(null,set):Bool;
    private var drawDebugRuler:Bool = false;
    private var _drawDebug:Bool = false;
    private var _debugSprite_radius:Null<FlxSprite> = null;
    private var _debugSprite_icon:Null<FlxSprite> = null;
    private var _debugText:Null<FlxText> = null;

    override function create(instance:ComponentInstance) {
        super.create(instance);

        //TODO - idk how to handle audio source start data due to the many use cases of this component

        compiled = true;
        ready = true;

        generateFrontend();
    }

    private function generateFrontend() {
        if(!ready || !exists) return;

        final frontend:Dynamic = frontend;

        //owner
        frontend.transform = owner.transform;
        frontend.getComponent = owner.getComponent;
        frontend.hasComponent = owner.hasComponent;

        //children
        frontend.getNumberOfChildren = owner.getNumberOfChildren;
        frontend.getChildAt = owner.getChildAt;

        frontend.Level = owner.level;

        
        frontend.setOffset = setOffset;
        frontend.setImportant = setImportant;

        frontend.playClip = playClip;
        frontend.setProximity = setProximity;
        frontend.removeProximity = removeProximity;
        
        frontend.getRadius = get_radius;
        frontend.setRadius = set_radius;
        frontend.getPanning = getPanning;
        frontend.setPanning = setPanning;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------

    //override and disable standard functions

    override function awake() {}
    override function start() {}
    override function compile(fullScript:String) {}
    override function requireComponent(typeof:String):HaxeScript { return null; }
    override function AddGeneral(name:String, toAdd:Dynamic) {}
    override function AddVariables() {}
    override function functionExists(func:String):Bool { return false; }
    override function doFunction(func:String, ?args:Array<Dynamic>):Dynamic { return null; }
    override function getFunction(func:String):Dynamic { return null; }
    override function setStaticVar(name:String, value:Dynamic):Dynamic { return null; }
    override function getStaticVar(name:String):Dynamic { return null; }
    override function importPackage(pack:String) {}
    override function getScriptVarExists(name:String):Bool { return false; }
    override function getScriptVar(name:String):Dynamic { return null; }
    override function setScriptVar(name:String, to:Dynamic) {}
    override function load() {}
    override function save() {}
    override function getTimers() { return null; }
    override function loadTimers(from:Array<HscriptTimerSave>) {}
    override function populateFrontend() {}
    override function RegisterExternalFunction(name:String, func:Dynamic) {}
    override function decompile() {}
    override function _import(what:Import, as:Import) {}
    override function grantImportPerms(to:HaxeScript) {}
    override function preprocessString(script:String, ?og:Bool = true):String { return "";}
    override function setCompilerFlag(name:String, value:Bool) {}

    //overrides

    override function update(elapsed:Float) {
        if(!exists || !ready) return;

        if(clip != null){
            if(usingProximity){
                if(clip != null)
                    clip.setPosition(owner.transform.internalPosition.x + offsetX ,owner.transform.internalPosition.y + offsetY);
            }
    
            if(_drawDebug && clip.curAsset != null) {
                _debugText.text = "Primary sound: " + clip.curAsset.key + (clips == null ? "" : "\n["+clips.length+"] extra clips active.");
            }
            else if(_drawDebug) {
                _debugText.text = "No primary sound"+ (clips == null ? "" : "\n["+clips.length+"] extra clips active.");
            }
        }
    }

    function onClipDone(clip:SoundEntity) {
        clips.remove(clip);

        clip.destroy();

        if(usesEvents){
            if(this.clip == null && clips.length == 0){
                Main.onPauseGame.remove(onPause);
                Main.onUnpauseGame.remove(onUnpause);
                usesEvents = false;
            }
        }
    }

    function onPause() {
        if(clip.playing){
            clip.pause();
            clip.pausedWithGame = true;
        }

        if(clips != null){
            for (entity in clips) {
                if(entity.playing){
                    entity.pause();
                    entity.pausedWithGame = true;
                }
            }
        }
    }

    function onUnpause() {
        if(!clip.playing && clip.pausedWithGame){
            clip.unpause();
            clip.pausedWithGame = false;
        }

        if(clips != null){
            for (entity in clips) {
                if(!entity.playing && entity.pausedWithGame){
                    entity.unpause();
                    entity.pausedWithGame = false;
                }
            }
        }
    }

    override function draw() {
        if(_drawDebug && ClientPreferences.drawDebug){
            _debugSprite_icon.setPosition(owner.transform.internalPosition.x - (_debugSprite_icon.width * 0.5), owner.transform.internalPosition.y  - (_debugSprite_icon.height * 0.5));
            _debugSprite_icon.draw();
            Component.precisionSprite.setPosition(_debugSprite_icon.x, _debugSprite_icon.y);
            Component.precisionSprite.draw();

            _debugText.setPosition(_debugSprite_icon.x - 25, _debugSprite_icon.y - 40);
            _debugText.draw();
        } 

        if(_debugSprite_radius != null && ClientPreferences.drawDebug){
            _debugSprite_radius.setPosition(owner.transform.internalPosition.x + offsetX - radius, owner.transform.internalPosition.y + offsetY - radius);
            _debugSprite_radius.draw();

            if(drawDebugRuler){
                var point = FlxPoint.get(owner.transform.internalPosition.x, owner.transform.internalPosition.y);
                var point2 = FlxPoint.get(AudioListenerComponent.listener.owner.transform.internalPosition.x,AudioListenerComponent.listener.owner.transform.internalPosition.y);
                if(point.distanceTo(point2) < radius){
                    Ruler.measure(point,point2, FlxColor.LIME);
                    //Ruler.measure(point.set(0,0),point2, FlxColor.BLUE);
                }

                point.put();
                point2.put();
            }
        }
    }

    override function destroy() {
        if(!exists) return;

        if(usesEvents){
            Main.onPauseGame.remove(onPause);
            Main.onUnpauseGame.remove(onUnpause);
        }

        if(clip != null)
            clip.destroy();

        usingProximity = false;

        //default basic destroy (so i don't have to call super)
        exists = false;
    }

    override public function clone(newParent:Object):HaxeScript {
        var c:HaxeScript = Component.instanceComponent("AudioSource",newParent);
        var clone:AudioSourceComponent = c._dynamic.backend;
        
        if(clip != null) {
            clone.playClip(clip.curAsset.key);
            if(!clip.playing) clone.pause();
        }

        if(usingProximity) {
            clone.setProximity(radius, usingProximityPanning);
        }
        else
            clone.setPanning(panning);

        return c;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------

    //api for interacting with this through the frontend

    private function _updateRadiusGraphic() {
        if(_debugSprite_radius != null) _debugSprite_radius.destroy();
        if(!Main.DEBUG || !_drawDebug) return;
        if(!usingProximity) return;
        _debugSprite_radius = new FlxShapeCircle(0,0, radius, {thickness: 0,color: 0x10FFA600},0x10FFA600);
        _debugSprite_radius.cameras = [FlxGamePlus.DebugCam];
    }

    public function setProximity(radius:Float, ?panning:Bool = true, ?clip:SoundEntity) {
        if(AudioListenerComponent.listener == null) {
            LogFile.error("No AudioListener is present in the scene!");
            return;
        }

        usingProximity = true;
        usingProximityPanning = panning;

        if(clip == null){
            if(this.clip == null) return;
            clip = this.clip;
        }
        
        clip.setProximity(owner.transform.internalPosition.x + offsetX, owner.transform.internalPosition.y + offsetY,
        AudioListenerComponent.listener.internalListener,
        radius,
        panning);

        _updateRadiusGraphic();
    }

    public function removeProximity() {
        if(!usingProximity) return;
        
        usingProximity = false;
        usingProximityPanning = false;

        clip.removeProximity();

        _updateRadiusGraphic();
    }

    public function setOffset(?x:Float = 0, ?y:Float = 0) {
        offsetX = x;
        offsetY = y;
    }

    public function playClip(path:String) {
        var removeEvents = false;
        if(usesEvents){
            usesEvents = false;
            removeEvents = true;
        }

        var asset = SoundAsset.get(path);

        var previousRadius = radius;
        var paused = clip == null ? false : clip.playing;

        if(clip == null){
            clip = new SoundEntity(asset);
        }
        else{
            //clean up previous clip
            clip.stop();
            clip.setAsset(asset);
        }

        if(clip.pauseWithGame) usesEvents = true;

        if(removeEvents && !usesEvents){
            Main.onPauseGame.remove(onPause);
            Main.onUnpauseGame.remove(onUnpause);
        }
        else if(usesEvents && !removeEvents){
            Main.onPauseGame.add(onPause);
            Main.onUnpauseGame.add(onUnpause);
        }

        clip.play();

        if(usingProximity)
            setProximity(previousRadius, usingProximityPanning, clip);

        if(paused) clip.pause();
    }

    public function playOneShot(path:String) {
        if(clips == null) clips = [];

        var previousRadius = radius;

        var asset = SoundAsset.get(path);
        var osClip = new SoundEntity(asset);
        osClip.onSoundDone = onClipDone;

        if(!usesEvents && clip.pauseWithGame){
            Main.onPauseGame.add(onPause);
            Main.onUnpauseGame.add(onUnpause);
        }

        clips.push(osClip);

        if(usingProximity)
            setProximity(previousRadius, usingProximityPanning, osClip);
        else
            osClip.pan = panning;

        osClip.play();
    }

    public function setImportant(to:Bool) {
        if(clip.curAsset != null)
            clip.curAsset.important = to;
    }

    public function getPanning():Float {
        if(clip == null) return panning;
        return clip.pan;
    }

    public function setPanning(to:Float) {
        if(usingProximityPanning) return;

        panning = to;

        if(clip != null)
            clip.pan = to;
    }

    public function pause() {
        if(clip != null)
            clip.pause();
    }

    public function unpause() {
        if(clip != null)
            clip.unpause();
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------

	function get_radius():Float {
        if(!usingProximity) return 0;
		return clip == null ? 0 : clip.radius;
	}

	function set_radius(value:Float):Float {
        if(!usingProximity) return 0;
        var rValue = clip == null ? 0 : clip.radius = value;
        if(_drawDebug) _updateRadiusGraphic();
		return rValue;
	}

	function set_drawDebug(value:Bool):Bool {
        value = value && Main.DEBUG;
        var previousValue = _drawDebug;
        _drawDebug = value;
        
		if(value == true && previousValue == false && Main.DEBUG){
            _debugSprite_icon = new FlxSprite(0,0,"embed/components/AudioSource.png");
            _debugText = new FlxText(0,0,0,"",14);
            _debugText.font = "vcr";

            _debugText.antialiasing = true;

            _debugSprite_icon.cameras = [FlxGamePlus.DebugCam];
            _debugText.cameras = [FlxGamePlus.DebugCam];

            _updateRadiusGraphic();
        }
        else if (value == false && previousValue == true ){
            if(_debugSprite_radius != null) _debugSprite_radius.destroy();

            _debugText.destroy();
            _debugText = null;



            _debugSprite_icon.destroy();
            _debugSprite_icon = null;
        }

        return _drawDebug;
	}
}