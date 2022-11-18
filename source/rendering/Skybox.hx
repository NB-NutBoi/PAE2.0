package rendering;

import common.ClientPreferences;
import assets.AnimatedAsset;
import utility.Utils;
import assets.ImageAsset;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets.FlxGraphicAsset;

class Skybox extends FlxSprite {
    //maybe do something special here?
    public var asset:ImageAsset;

    public var forceNoAA:Bool = false;

    public var animated(get,never):Bool;
    public var animOffsets:Map<String, {var x:Float; var y:Float;}>;

    //-------------------------------------------------

    public var doScrollWrapping:Bool = true;
    public var scroll:FlxPoint;

    public var additiveScrollX:Float = 0;
    public var additiveScrollY:Float = 0;

    override public function new(X:Float = 0, Y:Float = 0, asset:ImageAsset) {
        super(X,Y);
        scroll = new FlxPoint(0,0);

        if(asset != null) setAsset(asset);
    }

    public function setAsset(a:ImageAsset) {
        asset = a;

        forceNoAA = a.forceNoAA;
        
        if(asset.animated && asset != AnimatedAsset.defaultAnimatedAsset){
            frames = Utils.makeSparrowAtlas(asset.graphic, cast(asset, AnimatedAsset).xml);
            animOffsets = new Map();
        }
        else{
            loadGraphic(asset.graphic);
        }

        if(asset.defaultWidth != 0)
        setGraphicSize(asset.defaultWidth,Std.int(height * scale.y));

        if(asset.defaultHeight != 0)
        setGraphicSize(Std.int(width * scale.x), asset.defaultHeight);

        updateHitbox();

        antialiasing = (!forceNoAA && ClientPreferences.globalAA);
    }

    public function playAnimation(name:String, ?force:Bool = false) {
        if(asset == null) return;
        if(!asset.animated) return;
        if(!animation.exists(name)) requestAnimation(name);

        //do a second check to verify if it actually didn't exist or if it just wasn't added yet.
        if(!animation.exists(name)) return;

        animation.play(name, force);
        final anOffset = animOffsets.get(name);
        if(anOffset != null)
            offset.set(anOffset.x,anOffset.y);
    }

    //technically not adding since animations were defined in the asset file.
    public function requestAnimation(name:String) {
        if(asset == null) return;
        if(!asset.animated) return;
        if(animation.exists(name)) return;

        var anAsset:AnimatedAsset = cast asset;

        if(anAsset == null) return;

        if(!anAsset.availableAnimations.exists(name)) return;

        final anim = anAsset.availableAnimations.get(name);

        animation.addByPrefix(name, anim[1], anim[2], anim[3]);
        animOffsets.set(name, {
            x: anim.length == 6 ? anim[4] : 0,
            y: anim.length == 6 ? anim[5] : 0
        });

        anAsset = null;
    }

    function get_animated():Bool {
		return asset == null ? false : asset.animated;
	}

    override function update(elapsed:Float) {
        if(asset == null) return;
        scroll.add(additiveScrollX,additiveScrollY);
        
        super.update(elapsed);

        if(doScrollWrapping){
            //wrap so numbers don't reach ludicrous ammounts and take 30MB of ram.
            if(scroll.x > width) scroll.x -= width;
            if(scroll.y > height) scroll.y -= height;
            if(scroll.x < -width) scroll.x += width;
            if(scroll.y < -height) scroll.y += height;
        }
    }

    override function destroy() {
        graphic = null;
        framePixels = null;

        if(animOffsets != null) animOffsets.clear();
        animOffsets = null;

        if(asset != null){
            if(!asset.important)
                asset.destroy();

            asset = null;
        }

        scroll.destroy();

        super.destroy();
    }
}