package ui.base;

import flixel.math.FlxPoint;
import FlxGamePlus.UIPlugin;
import assets.ImageAsset;
import common.Mouse;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;
import lime.app.Application;
import pgr.dconsole.DCThemes;
import rendering.Sprite;
import ui.elements.ContainerCloser;
import ui.elements.ContainerMover;
import utility.Utils;

class Container extends FlxBasic {

    public static var contextActive:Bool = false;
    public static var dropdownActive:Bool = false;

    public var bg:FlxSprite;
    public var stuffs:FlxTypedGroup<FlxBasic>;
    public var cam:FlxCamera;

    public var x(get,set):Float;
	private var _x:Float = 0;
	public var y(get, set):Float;
	private var _y:Float = 0;


    public var width(get,null):Int;
	public var height(get, null):Int;

    public var focused:Bool = false;
    public var overlapped:Bool = false;
    public var open:Bool = false;

    public var restrictWithinWindow:Bool = true;

    //Container plugins
    public var mover(get,set):Null<ContainerMover>;
    private var _mover:Null<ContainerMover> = null;
    public var move:Bool = false;

    public var closer(get,set):Null<ContainerCloser>;
    private var _closer:Null<ContainerCloser> = null;

    public var exclusiveInputs:Null<ContainerObject> = null;

    public var canScroll:Bool = false;

    override public function new(x:Float,y:Float, w:Int, h:Int) {
        super();

		_x = x;
        _y = y;

        #if USING_DCONSOLE
        bg = new Sprite(0,0,ImageAsset.get("embed/debug/TestSliced.asset"));
        bg.setGraphicSize(w,h);
        bg.updateHitbox();
        bg.color = 0xA6353535;
        bg.alpha = bg.color.alphaFloat;
        #else
        bg = Utils.makeRamFriendlyRect(0,0,w,h,0xFF464B6B);
        #end
        bg.graphic.destroyOnNoUse = false;
        bg.graphic.persist = true;
        bg.antialiasing = true;
        bg.scrollFactor.set();
        stuffs = new FlxTypedGroup();
		cam = new FlxCamera(0,0,w,h);

        FlxG.signals.gameResized.add(onGameResize);

		cam.x = -x;
		cam.y = -y;
		cam.bgColor.alpha = 0;
		cam.visible = false;
        cam.antialiasing = true;

        stuffs.cameras = [cam];
        bg.cameras = [cam];

        stuffs.memberAdded.add(onAdd);
    }

    function onGameResize(_,_) {
        if(!cam.visible){
            cam.onResize();
        }
    }

    override function update(elapsed:Float) {
        if(!visible) return;

        bg.update(elapsed);
        stuffs.update(elapsed);

        if(move){
            //add position
            x += FlxGamePlus.mouseMove[0];
            y += FlxGamePlus.mouseMove[1];
            if(FlxG.mouse.justReleased || !FlxG.mouse.pressed){
                move = false;
            }
        }

        if(closer != null){
            closer.update(elapsed);
        }

        updateInputs(elapsed);
        if(!exists) return;

        super.update(elapsed);

        postUpdate(elapsed);
    }

    //idea is to have input logic update only if you're overlapping with it at the very minimum(so no other elements trigger if containers overlap.)
    public function updateInputs(elapsed:Float) {
        if(!visible) return;
        if(!overlapped) return;
        if(contextActive) return;

        //logic
        if(mover != null){
            mover.update(elapsed);
            var over = mover.overlaps(null);


            if(over){
                Mouse.setAs(HAND);
                if(FlxG.mouse.justPressed)
                    move = true;
            }
        }

        if(canScroll && focused){
            cam.scroll.y -= FlxG.mouse.wheel * 2;
        }

        var localMousePos = FlxPoint.get(0,0);
        localMousePos = Utils.getMousePosInCamera(camera, localMousePos);
        
        for (object in stuffs.members) {
            if(object == null) continue;

            if (Std.isOfType(object, ContainerObject)){
                var o:ContainerObject = cast object;
                if(exclusiveInputs == null || exclusiveInputs == o){
                    o.updateInputs(elapsed);
                }
            }
        }

        if(closer != null){
            closer.updateInputs(elapsed);
        }

        localMousePos.put();
    }

    public function postUpdate(elapsed:Float) {
        if(closer != null){
            closer.postUpdate(elapsed);
        }
        
        for (object in stuffs.members) {
            if(object == null) continue;

            if (Std.isOfType(object, ContainerObject)){

                var o:ContainerObject = cast object;
                o.postUpdate(elapsed);
            }
        }
    }

    public function updatePosition() {
		cam.x = -_x;
		cam.y = -_y;
    }

    public function setSize(w:Int, h:Int) {
		cam.setSize(w,h);
		bg.setGraphicSize(w,h);
        bg.updateHitbox();
    }

    override function draw() {
        super.draw();
        bg.draw();
        if(mover != null)
            mover.draw();
        if(closer != null)
            closer.draw();
        stuffs.draw();
    }

    override function destroy() {
        if(open) close();
        super.destroy();
		bg.destroy();
		stuffs.destroy();
        if(mover != null)
            mover.destroy();
        if(closer != null)
            closer.destroy();
		cam.destroy();

        FlxG.signals.gameResized.remove(onGameResize);
    }

    public function close() {
        if(!open) return;
        open = false;
        UIPlugin.removeContainer(this);
    }




    public function overlaps():Bool {
        return Utils.overlapsSprite(bg, Utils.getMousePosInCamera(cam,null,bg), false);
    }




    public function add(x:FlxBasic) {
        if(Std.isOfType(x, ContainerObject)) cast(x, ContainerObject).parent = this;
        stuffs.add(x);
    }

    public function remove(x:FlxBasic) {
        if(Std.isOfType(x, ContainerObject)) cast(x, ContainerObject).parent = null;
        stuffs.remove(x,true);
    }
    

    

	function get_x():Float {
		return _x;
	}

	function set_x(value:Float):Float {
		_x = value;
        updatePosition();
        return _x;
	}

	function get_y():Float {
		return _y;
	}

	function set_y(value:Float):Float {
        _y = value;
        updatePosition();
		return _y;
	}

	function get_width():Int {
		return cam.width;
	}

	function get_height():Int {
		return cam.height;
	}

	function get_mover():Null<ContainerMover> {
		return _mover;
	}

	function set_mover(value:Null<ContainerMover>):Null<ContainerMover> {
		if(value == null){
            if(_mover != null){
                _mover.cameras = null;
                _mover.parent = null;
            }
                
        }
        else{
            value.cameras = [cam];
            value.parent = this;
            value.antialiasing = true;
        }

        return _mover = value;
	}
    
    function onAdd(x:FlxBasic) {
        //funny hack (TURN YOUR ANTIALIASINGS ON >:( )
        if(Reflect.field(x, "antialiasing") != null)
            Reflect.setProperty(x, "antialiasing", true);
    }

	function get_closer():Null<ContainerCloser> {
		return _closer;
	}

	function set_closer(value:Null<ContainerCloser>):Null<ContainerCloser> {
		if(value == null){
            if(_closer != null){
                _closer.cameras = null;
                _closer.parent = null;
            } 
        }
        else{
            value.cameras = [cam];
            value.parent = this;
            value.update(0);
        }

        return _closer = value;
	}
}

