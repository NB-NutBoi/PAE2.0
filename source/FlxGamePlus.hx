package;

import ui.elements.Context;
import common.Keyboard;
import common.Mouse;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import lime._internal.backend.native.NativeCFFI;
import lime.app.Application;
import lime.graphics.opengl.GL;
import lime.utils.Bytes;
import lowlevel.OverrideableEvent;
import lowlevel.Ruler;
import openfl.display.BitmapData;
import ui.DMenu;
import ui.base.Container;
import utility.Utils;

/**
 * FlxGame class with extended functionality that i didn't find anywhere else.
 * @author Flixel team, extended functionality by NutBoi
 */
class FlxGamePlus extends FlxGame {

    //imagine spending 5 months researching rendering code for this one feature, couldn't be me.
    public static var lastFrame:BitmapData = null;

    public static var DebugCam:FlxCamera; //will be used to draw debug ui info, such as the ruler.
    public static var OverlayCam:FlxCamera; //will be used to draw overlay objects.

    override public function new(GameWidth:Int = 0, GameHeight:Int = 0, InitialState:Class<FlxState>, Zoom:Float = 1, UpdateFramerate:Int = 60, DrawFramerate:Int = 60, SkipSplash:Bool = true, StartFullScreen:Bool = false) {
        super(GameWidth, GameHeight, InitialState, Zoom, UpdateFramerate, DrawFramerate, SkipSplash, StartFullScreen);
        Application.current.window.onFocusOut.add(focusLost);

        DebugCam = new FlxCamera();
		DebugCam.bgColor.alpha = 0;

		DebugCam.visible = true;

        //overlay
        
        OverlayCam = new FlxCamera();
        OverlayCam.bgColor.alpha = 0;

        OverlayCam.visible = true;
    }

    @:access(openfl.display.BitmapData)
    override function draw() {
        //Console integration
        Console.beginProfile("Draw");

        Ruler.clear();

        super.draw();
        

        //saves the last rendered frame to a bitmap, can be used for save previews, effects, and other stuff.

        /*
        (no, you can't just draw the flxGame instance to a blank bitmap ok) 
        has to be this way since with opengl, flixel saves object color transformations in a shader,
        which only opengl reads, so if you draw the game sprite onto a bitmap, all objects will appear without color mods.
        (you can also repurpose this so it only gets the screen when you need it to, it doesn't have to be every frame.)
        */

        #if BUFFER_LAST_FRAME

        Console.beginProfile("BufferLastFrame");

        if(lastFrame == null){
            lastFrame = new BitmapData(stage.context3D.backBufferWidth, stage.context3D.backBufferHeight, true, 0xFFFFFFFF);
        }

        if(lastFrame == null) return;

        if(lastFrame.width != stage.context3D.backBufferWidth || lastFrame.height != stage.context3D.backBufferHeight){
            lastFrame.__resize(stage.context3D.backBufferWidth, stage.context3D.backBufferHeight);
            lastFrame.image.resize(stage.context3D.backBufferWidth, stage.context3D.backBufferHeight);
        }

        switch(stage.window.context.type){
            case OPENGL, OPENGLES, WEBGL:
                //draw with opengl (more optimized that context3d since this reuses an image buffer, instead of creating an entirely new image.)
                glScreen();
            default:
                nonGlScreen(); //no fucking clue what it does, and i can only pray it works if i ever dare use it.
        }

        Console.endProfile("BufferLastFrame");
        
        #end

        Console.endProfile("Draw");
    }
    
    private static var resetMouse:Bool = false;
    private static var lastMousePosition:Array<Float> = [0,0];
    public static var mouseMove:Array<Float> = [0,0];

    override function update() {
        CoreState._frame = true;
        CoreState._lateFrame = true;
        Mouse.reset();
        super.update();
        DebugCam.scroll.set(FlxG.camera.scroll.x, FlxG.camera.scroll.y);
        DebugCam.zoom = FlxG.camera.zoom;
        
        lastMousePosition = [FlxG.mouse.screenX, FlxG.mouse.screenY];
    }

    //mouse stuff
    function focusLost() {
        resetMouse = true;
    }

    override function updateInput() {
        super.updateInput();

        if(resetMouse){
            lastMousePosition = [FlxG.mouse.screenX, FlxG.mouse.screenY];
            resetMouse = false;
        }
            
        mouseMove = [FlxG.mouse.screenX, FlxG.mouse.screenY];
        mouseMove[0] = mouseMove[0]-=lastMousePosition[0];
        mouseMove[1] = mouseMove[1]-=lastMousePosition[1];
    }

    
    //GL DRAW
    var temp:Bytes;
    var prevRowLength:Float;

    @:access(lime.ui.Window)
    private final function glScreen() {
        //just stole this from nativeWindow and cleaned it up so it doesn't oscilate from 30 mb usage to 10 mb usage every god damn second.
        var windowWidth = Std.int(Application.current.window.__width * Application.current.window.__scale);
		var windowHeight = Std.int(Application.current.window.__height * Application.current.window.__scale);
        
        var width = windowWidth;
	    var height = windowHeight;

        if(lastFrame.image.buffer.format != RGBA32){
            lastFrame.image.buffer.format = RGBA32;
            lastFrame.image.buffer.bitsPerPixel = 32;
        }

        GL.readPixels(0, 0, width, height, GL.RGBA, GL.UNSIGNED_BYTE, lastFrame.image.buffer.data);

        var rowLength = width * 4;
        var srcPosition = (height - 1) * rowLength;
        var destPosition = 0;


        //this creates a lot of memory instability for some reason so only change it when necessary
        if(temp == null || rowLength != prevRowLength){
            temp = Bytes.alloc(rowLength);
        }
        var buffer = lastFrame.image.buffer.data.buffer;
        var rows = Std.int(height / 2);

        while (rows-- > 0)
        {
            temp.blit(0, buffer, destPosition, rowLength);
            buffer.blit(destPosition, buffer, srcPosition, rowLength);
            buffer.blit(srcPosition, temp, 0, rowLength);

            destPosition += rowLength;
            srcPosition -= rowLength;
        }

        prevRowLength = rowLength;
    }

    @:access(lime._internal.backend.native.NativeCFFI)
    private final function nonGlScreen() {
        #if (!macro && lime_cffi)
        #if !cs
        NativeCFFI.lime_window_read_pixels(null, null, lastFrame.image.buffer.data);
        #else
        var data:Dynamic = NativeCFFI.lime_window_read_pixels(handle, rect, null);
        if (data != null)
        {
            lastFrame.image.buffer = new ImageBuffer(new UInt8Array(@:privateAccess new Bytes(data.data.length, data.data.b)), data.width, data.height,
                data.bitsPerPixel);
        }
        #end
        #end
    }


    override function switchState() {
        if(FlxG.cameras.list.contains(DebugCam))
            FlxG.cameras.remove(DebugCam,false);

        if(FlxG.cameras.list.contains(OverlayCam))
            FlxG.cameras.remove(OverlayCam,false);

        if(UIPlugin.instance != null) UIPlugin.preReset();

        super.switchState();

        if(UIPlugin.instance == null){
            FlxG.plugins.add(new UIPlugin());

            if(Main.DEBUG){
                if(Main.SetupConfig.configExists("DMenuDirectory")){
                    DMenu.register(Main.SetupConfig.getConfig("DMenuDirectory","STRING","assets/dmenu"));
                }
            }
        }

        if(UIPlugin.instance != null) UIPlugin.reset();

        if(GameOverlay.instance == null){
            FlxG.plugins.add(new GameOverlay(OverlayCam));
        }

        FlxG.cameras.add(DebugCam,false);
        UIPlugin.addingCams = true;
        if(!FlxG.cameras.list.contains(OverlayCam)) FlxG.cameras.add(FlxGamePlus.OverlayCam,false);
        UIPlugin.addingCams = false;
    }
}

class GameOverlay extends FlxBasic {
    
    public static var instance:GameOverlay = null;

    public var OverlayCamera:FlxCamera;
    public var OnTryCloseGame:OverrideableEvent;
    private var _event:Void->Void;

    override public function new(camera:FlxCamera) {
        super();
        OverlayCamera = camera;

        OnTryCloseGame = new OverrideableEvent(onTryCloseGame_default);
        Main.onTryCloseGame.add(_event = OnTryCloseGame.execute.bind());
    }

    override function destroy() {
        super.destroy();

        Main.onTryCloseGame.remove(_event);
        OnTryCloseGame = null;
    }

    function onTryCloseGame_default() {
        defaultQuitMenu(true);
    }

    //DEFAULT CLOSING GAME SCREEN (YOU CAN OVERRIDE THIS WITH YOUR OWN.)
    //-------------------------------------------------------------------------------------------------------------------------
    var defaultExists:Bool = false;
    var defaultActive:Bool = false;
    var bg:FlxSprite = null;
    var tx1:FlxText = null;
    var tx2:FlxText = null;
    var tx3:FlxText = null;
    function defaultQuitMenu(b:Bool) {
        if(!defaultExists) buildDefaultQuitMenu();

        defaultActive = b;
        Main.Paused = defaultActive;
        OverlayCamera.bgColor.alphaFloat = defaultActive ? 0.5 : 0;
    }

    function buildDefaultQuitMenu() {
        defaultExists = true;

        OverlayCamera.bgColor = 0xFF000000;
        bg = Utils.makeRamFriendlyRect(0,0,600,400,0xD0353535);
        bg.screenCenter();
        bg.cameras = [OverlayCamera];

        tx1 = new FlxText(0,380,0,"Are you sure you want to close the game?", 24);
        tx1.font = "vcr";
        tx1.antialiasing = true;
        tx1.screenCenter(X);
        tx1.cameras = [OverlayCamera];

        tx2 = new FlxText(720,610,0,"Yes.",32);
        tx2.font = "vcr";
        tx2.antialiasing = true;
        tx2.cameras = [OverlayCamera];
        
        tx3 = new FlxText(1130,610,0,"No.",32);
        tx3.font = "vcr";
        tx3.antialiasing = true;
        tx3.cameras = [OverlayCamera];
    }

    override function update(elapsed:Float) {
        super.update(elapsed);
        if(Context.instance != null){
            Context.instance.update(elapsed);
        }

        if(defaultActive){
            bg.update(elapsed);
            tx1.update(elapsed);

            tx2.update(elapsed);
            tx3.update(elapsed);

            var overlaps:Bool = false;

            overlaps = Utils.overlapsSprite(tx2,Utils.getMousePosInCamera(OverlayCamera));
            if(overlaps){
                tx2.offset.y = 4;
                if(FlxG.mouse.justPressed){
                    yes();
                }
            }
            else{
                tx2.offset.y = 0;
            }

            overlaps = Utils.overlapsSprite(tx3,Utils.getMousePosInCamera(OverlayCamera));
            if(overlaps){
                tx3.offset.y = 4;
                if(FlxG.mouse.justPressed){
                    no();
                }
            }
            else{
                tx3.offset.y = 0;
            }
        }
    }

    override function draw() {
        super.draw();
        if(defaultActive){
            bg.draw();
            tx1.draw();

            tx2.draw();
            tx3.draw();
        }
    }

    function yes() {
        Main.CloseGame();
    }

    function no() {
        defaultQuitMenu(false);
    }

    //-------------------------------------------------------------------------------------------------------------------------
}

class UIPlugin extends FlxBasic {
    
    public static var instance:UIPlugin = null;
    
    public static var containers:FlxTypedGroup<Container> = new FlxTypedGroup();
    static var curFocused:Null<Container> = null;

    override public function new() {
        super();

        instance = this;
        
        FlxG.cameras.cameraAdded.add(updateCams);
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        //UI CONTROLLER

        var overlapped:Null<Container> = null;

        for (container in containers.members) {
            var overlaps = container.overlaps();

            container.overlapped = overlaps;
            
            if(overlaps) {
                if(overlapped != null)
                    overlapped.overlapped = false;

                overlapped = container;
            }
        }

        if(FlxG.mouse.justPressed) {
            if(curFocused != null) curFocused.focused = false;
            
            if(overlapped != null){
                overlapped.focused = true;
                curFocused = overlapped;
            }
            else{
                curFocused = null;
            }
        }

        //clean
        overlapped = null;

        Keyboard.ui_only = (curFocused != null || Console.overlaps());

        containers.update(elapsed);
    }

    override function draw() {
        super.draw();

        containers.draw();
    }


    static var resetting:Bool = false;
    public static var addingCams:Bool = false;

    function updateCams(_) {
        if(addingCams || resetting) return;
        if(containers.length == 0) return;

        addingCams = true;
        if(FlxG.cameras.list.contains(FlxGamePlus.OverlayCam))
            FlxG.cameras.remove(FlxGamePlus.OverlayCam,false);
        addingCams = false;

        for (container in containers) {
            FlxG.cameras.remove(container.cam,false);
            if(container.cam == null) continue; //prevent crash
            addingCams = true;
            FlxG.cameras.add(container.cam,false);
            addingCams = false;
        }       //keep cams on front at all times if a non-ui cam is added.

        var i = containers.length;
        while (i-- > 0) { //remove containers with null cams
            if(containers.members[i].cam == null) { containers.remove(containers.members[i],true); i++; }
        }

        //its the overlay, duh.
        addingCams = true;
        FlxG.cameras.add(FlxGamePlus.OverlayCam,false);
        addingCams = false;
    }

    public static function preReset() {
        resetting = true;
        for (container in containers) {
            FlxG.cameras.remove(container.cam,false);
        }
    }

    public static function reset() {
        for (container in containers) {
            addingCams = true;
            FlxG.cameras.add(container.cam,false);
            addingCams = false;
        }

        resetting = false;
    }

    //--------------------------------------------------------------------------------------------------------------

    public static function addContainer(x:Container) {
        if(x == null) return;

        UIPlugin.addingCams = true;
        if(FlxG.cameras.list.contains(FlxGamePlus.OverlayCam))
            FlxG.cameras.remove(FlxGamePlus.OverlayCam,false);
        UIPlugin.addingCams = false;

        UIPlugin.addingCams = true;

		FlxG.cameras.add(x.cam, false);

        UIPlugin.addingCams = false;

        UIPlugin.addingCams = true;
        if(!FlxG.cameras.list.contains(FlxGamePlus.OverlayCam)) FlxG.cameras.add(FlxGamePlus.OverlayCam,false);
        UIPlugin.addingCams = false;

        x.open = true;
        x.cam.visible = true;
        containers.add(x);
    }

    public static function removeContainer(x:Container) {
        if(x == null) return;
        if(!containers.members.contains(x)) return;

        UIPlugin.addingCams = true;

		FlxG.cameras.remove(x.cam, false);

        UIPlugin.addingCams = false;

        x.overlapped = false;
        x.focused = false;
        if(curFocused == x){
            curFocused = null;
        }

        x.cam.visible = false;

        containers.remove(x,true);
    }
}