package rendering;

import utility.LogFile;
import assets.AnimatedAsset;
import assets.ImageAsset;
import common.ClientPreferences;
import flash.display.BitmapData;
import flixel.FlxSprite;
import flixel.math.FlxRect;
import utility.Utils;

class Sprite extends FlxSprite{
    public var assets:Array<ImageAsset>;

    public var animated(get,never):Bool;
    public var animOffsets:Map<String, {var x:Float; var y:Float;}>;
    
    public var lockFramePixels:Bool = false;
    public var tryOptimizeDrawCalls:Bool = true;

    public var forceNoAA:Bool = false;

    var slice9:Bool = false;
    var slice9W:Int;
    var slice9H:Int;
    

    override public function new(x:Float, y:Float, asset:ImageAsset) {
        super(x,y);

        if(asset == null) return;
        setAsset(asset);
    }

    public function setAsset(a:ImageAsset) {
        if(assets != null) removeAssets();
        assets = [a];
        a.users++;

        forceNoAA = a.forceNoAA;
        
        if(assets[0].flags.contains("9SLICE")){
            loadGraphic(assets[0].graphic, true, slice9W = Math.ceil(assets[0].graphic.width/3), slice9H = Math.ceil(assets[0].graphic.height/3));

            slice9 = true;
            assets[0].animated = false;
        }
        else if(assets[0].animated && assets[0] != AnimatedAsset.defaultAnimatedAsset){
            frames = Utils.makeSparrowAtlas(assets[0].graphic, cast(assets[0], AnimatedAsset).xml);
            animOffsets = new Map();
        }
        else{
            loadGraphic(assets[0].graphic);
        }

        if(assets[0].defaultWidth != 0)
        setGraphicSize(assets[0].defaultWidth,Std.int(height * scale.y));

        if(assets[0].defaultHeight != 0)
        setGraphicSize(Std.int(width * scale.x), assets[0].defaultHeight);

        updateHitbox();

        antialiasing = (!forceNoAA && ClientPreferences.globalAA);
    }

    public function removeAssets() {
        if(assets != null){
            for (asset in assets) {
                asset.users--;
                if(!asset.important && asset.users <= 0)
                asset.destroy();
            }
            assets = null;
        }
    }

    public function playAnimation(name:String, ?force:Bool = false) {
        if(assets == null) return;
        if(!assets[0].animated) return;
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
        if(assets == null) return;
        if(!assets[0].animated) return;
        if(animation.exists(name)) return;

        var anAsset:AnimatedAsset = getAnimatedAssetContaining(name);

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
		return assets == null ? false : assets[0].animated; //first asset is the master asset.
	}

    private function getAnimatedAssetContaining(animation:String) {
        if(assets == null) return null;
        if(!assets[0].animated) return null;
        var i = assets.length;
        while (i-- > 0) { //check last upwards for overrides.
            var anAsset:AnimatedAsset = cast assets[i];
            if(anAsset.availableAnimations.exists(animation)) return anAsset;
        }

        return null;
    }

    public function addAnimatedAsset(asset:AnimatedAsset) {
        if(assets == null) return;
        if(!asset.animated) {LogFile.error("! Cannot add a non-animated asset as an extra to a sprite !"); return; }
        if(!assets[0].animated) { LogFile.error("! Cannot add more than 1 asset to a non-animated sprite !"); return; }
        if(assets.contains(asset)) return;

        assets.push(asset);
        asset.users++;

        var newFrames = Utils.makeSparrowAtlas(asset.graphic, asset.xml);
        for (frame in newFrames.frames) {
            frames.pushFrame(frame);
        }

        //reload
        this.frames = this.frames;

        //update animations if they're already added.
        for (s in asset.availableAnimations.keys()) {
            if(animation.exists(s)){
                //assume its an override
                animation.remove(s);

                final anim = asset.availableAnimations.get(s);

                animation.addByPrefix(s, anim[1], anim[2], anim[3]);
                animOffsets.set(s, {
                    x: anim.length == 6 ? anim[4] : 0,
                    y: anim.length == 6 ? anim[5] : 0
                });
            }
        }
    }

    //----------------------------------------------------------------------overrides-----------------------------------------

    override function update(elapsed:Float) {
        if(assets == null) return;
        super.update(elapsed);
    }

    override function draw() {
        if(assets == null) return;

        if(tryOptimizeDrawCalls){
            //not sure if this is efficient at all, but we're trying to optimize draw calls
            //should work with slice9 too.
            var rect = FlxRect.get(0,0,0,0);
            for (camera in cameras) {
                if(!camera.getViewRect().overlaps(getBoundingBox(camera))){
                    rect.put();
                    return;
                }
            }
            rect.put();
        }

        //slice9 sprite support.
        if(slice9){
            drawSlice9();
            return;
        }

        super.draw();
    }

    //slice9 sprite support.
    function drawSlice9() {
        final curX = x;
        final curY = y;

        final curSizeW = Math.ceil(Math.abs(width));
        final curSizeH = Math.ceil(Math.abs(height));

        //new values
        var newX, newY:Float=0;
        var newW, newH:Int=0;

        for (i in 0...9) {
            //do the math for each slice (not really meant to be readable, math's already been checked.)
            switch (i){
                default: /*???*/ continue;
                case 0: /*TOP LEFT*/ newX = curX; newY = curY; newW = slice9W; newH = slice9H;
                case 1: /*TOP MIDDLE*/ newX = curX+slice9W; newY = curY; newW = curSizeW - (slice9W*2); newH = slice9H;
                case 2: /*TOP RIGHT*/ newX = curSizeW - (slice9W); newY = curY; newW = slice9W; newH = slice9H;
                case 3: /*MIDDLE LEFT*/ newX = curX; newY = curY+slice9H; newW = slice9W; newH = curSizeH - (slice9H*2);
                case 4: /*MIDDLE*/ newX = curX+slice9W; newY = curY+slice9H; newW = curSizeW - (slice9W*2); newH = curSizeH - (slice9H*2);
                case 5: /*MIDDLE RIGHT*/ newX = curSizeW - (slice9W); newY = curY+slice9H; newW = slice9W; newH = curSizeH - (slice9H*2);
                case 6: /*BOTTOM LEFT*/ newX = curX; newY = curSizeH - (slice9H); newW = slice9W; newH = slice9H;
                case 7: /*BOTTOM MIDDLE*/ newX = curX+slice9W; newY = curSizeH - (slice9H); newW = curSizeW - (slice9W*2); newH = slice9H;
                case 8: /*BOTTOM RIGHT*/ newX = curSizeW - (slice9W); newY = curSizeH - (slice9H); newW = slice9W; newH = slice9H;
            }

            //set the correct frame
            frame = frames.frames[i];

            //POSITION AND SCALE SLICES ACCORDINGLY.
            setPosition(newX,newY);
            setGraphicSize(newW,newH);

            updateHitbox();

            //draw.
            super.draw();
        }

        //RESET SPRITE FOR NEXT FRAME.
        frame = frames.frames[4]; //collision won't be accurate here, ohboohoo

        setPosition(curX,curY);
        setGraphicSize(curSizeW,curSizeH);

        updateHitbox();
        //accurate enough.
    }

    override function destroy() {

        graphic = null;
        framePixels = null;

        if(animOffsets != null) animOffsets.clear();
        animOffsets = null;

        if(assets != null) removeAssets();

        super.destroy();
    }

    override function updateFramePixels():BitmapData {
        if(lockFramePixels && framePixels != null) return framePixels;
        
        return super.updateFramePixels();
    }

}