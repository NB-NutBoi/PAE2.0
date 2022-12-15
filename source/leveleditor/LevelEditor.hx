package leveleditor;

import utility.NameUtils;
import flixel.util.FlxDestroyUtil;
import flixel.FlxState;
import assets.AssetCache;
import oop.Object.StaticSpriteDataStructure;
import oop.StaticObject;
import openfl.net.FileFilter;
import oop.GenericObject;
import flixel.util.FlxColor;
import utility.LogFile;
import haxe.Json;
import sys.io.File;
import lowlevel.FileBrowser;
import oop.Component.ComponentInstance;
import oop.Object.FullObjectDataStructure;
import levels.Level.LayerStructure;
import levels.Level.LevelFile;
import ui.elements.TextField;
import lime.ui.KeyCode;
import common.Keyboard;
import assets.ImageAsset;
import sys.FileSystem;
import rendering.Skybox;
import ui.premades.LevelProperties;
import ui.base.Container;
import ui.elements.Context;
import common.Mouse;
import flixel.math.FlxPoint;
import flixel.FlxObject;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.FlxG;
import utility.Utils;
import flixel.FlxSprite;
import FlxGamePlus.UIPlugin;
import ui.premades.Inspector;
import ui.premades.Hierarchy;
import flixel.group.FlxGroup.FlxTypedGroup;
import lime.app.Application;
import lime.utils.Assets;

using StringTools;

class LevelEditor extends CoreState {
    public static var instance:LevelEditor;

    public static var curEditedObject(default,set):GenericObjectVisualizer = null;
    public static var tempCurEdited:GenericObjectVisualizer = null;

    public var name:String;

    public var script:String;

    public var staticAssets:Array<String>;

    public var hierarchy:Hierarchy;
    public var inspector:Inspector;
    public var properties:LevelProperties;

    

    //rendering
    public var skybox:String;
    public var curSkybox:Skybox;
    public var skyboxVisible:Bool = true;

    var axle:Axle;

    public var layers:FlxTypedGroup<LayerVisualizer>;
    public var curLayer:Int = 0;

    //------------------------------------

    public var snappingEnabled:Bool = false;
    public var snapping:Float = 25;

    //taskbar
    //------------------------------------

    static final TaskbarBG:Int = 0xFF1B1B1B;

    public static final Taskbar_Off:Int = 0xFF838383;
    public static final Taskbar_On:Int = 0xFFFFFFFF;

    public var Taskbar:FlxSprite;
    public var TaskbarFps:FlxText;
    var doFps:Bool = false;
    var fpsVis:Bool = false;

    public var TaskbarGroup:FlxTypedGroup<FlxObject>;

        //------------------------------------

        public var HierarchyButton:FlxSprite;
        public var InspectorButton:FlxSprite;
        public var PropertiesButton:FlxSprite;


        static final Camera_Off:Int = 0xFFFF0000;
        static final Camera_Idle:Int = 0xFFFFCF33;
        static final Camera_On:Int = 0xFF33FF66;

        public var CameraIcon:FlxSprite;
        public var CameraCoordsXY:FlxText;


        public var MagnetIcon:FlxSprite;
        public var MagnetSetting100:FlxSprite;
        public var MagnetSetting50:FlxSprite;
        public var MagnetSetting25:FlxSprite;

        public var SaveText:FlxText;
        public var LoadText:FlxText;
        public var NewText:FlxText;

        //------------------------------------

    //------------------------------------

    override function create() {
        super.create();

        instance = this;
        
        LogFile.log("\nOpened Level Editor\n\n",true);

        //map-icon
        Application.current.window.setIcon(Assets.getImage("embed/defaults/leveleditor/icon512.png"));

        name = "Unnamed map.";
        Application.current.window.title = "PAE2.0 - Level editor - Unnamed map.";

        skybox = "";
        script = "";
        staticAssets = [];

        //------------------------------------

        if(!Main.instance.nofps){
            fpsVis = Main.fps.visible;
            Main.fps.visible = false;
            doFps = true;
        }

        //------------------------------------

        //disable watermark
        if(CoreState.watermark != null) CoreState.watermark.visible = false;

        Taskbar = Utils.makeRamFriendlyRect(0,FlxG.height-65, FlxG.width,65,TaskbarBG);
        Taskbar.camera = FlxGamePlus.OverlayCam;

        TaskbarFps = new FlxText(10, Taskbar.y+10,0,"FPS:",20);
        TaskbarFps.antialiasing = true;
        TaskbarFps.font = "vcr";
        TaskbarFps.camera = FlxGamePlus.OverlayCam;

        TaskbarGroup = new FlxTypedGroup();
        TaskbarGroup.camera = FlxGamePlus.OverlayCam;

        TaskbarGroup.add(Utils.makeRamFriendlyRect(110,Taskbar.y+5,2,55,Taskbar_Off));
        TaskbarGroup.add(Utils.makeRamFriendlyRect(250,Taskbar.y+5,2,55,Taskbar_Off));

        HierarchyButton = new FlxSprite(260,Taskbar.y+2,"embed/ui/leveleditor/HierarchyIcon.png");
        HierarchyButton.camera = FlxGamePlus.OverlayCam;
        HierarchyButton.color = Taskbar_Off;

        InspectorButton = new FlxSprite(330,Taskbar.y+2,"embed/ui/leveleditor/InspectorIcon.png");
        InspectorButton.camera = FlxGamePlus.OverlayCam;
        InspectorButton.color = Taskbar_Off;

        PropertiesButton = new FlxSprite(400,Taskbar.y+2,"embed/ui/leveleditor/PropertiesIcon.png");
        PropertiesButton.camera = FlxGamePlus.OverlayCam;
        PropertiesButton.color = Taskbar_Off;

        TaskbarGroup.add(HierarchyButton);
        TaskbarGroup.add(InspectorButton);
        TaskbarGroup.add(PropertiesButton);

        CameraIcon = new FlxSprite(120,Taskbar.y+35, "embed/ui/leveleditor/cameraIcon.png");
        CameraIcon.camera = FlxGamePlus.OverlayCam;
        CameraIcon.color = Camera_Off;
        CameraIcon.antialiasing = true;

        CameraCoordsXY = new FlxText(150,Taskbar.y+35,0,"X: 0\nY: 0",12);
        CameraCoordsXY.font = "vcr";
        CameraCoordsXY.antialiasing = true;

        TaskbarGroup.add(CameraCoordsXY);
        TaskbarGroup.add(CameraIcon);

        MagnetIcon = new FlxSprite(120,Taskbar.y+10, "embed/ui/leveleditor/magnetIcon.png");
        MagnetIcon.camera = FlxGamePlus.OverlayCam;
        MagnetIcon.color = Taskbar_Off;
        MagnetIcon.antialiasing = true;

        MagnetSetting100 = new FlxSprite(150,Taskbar.y+10, "embed/ui/leveleditor/snap100.png");
        MagnetSetting100.color = Taskbar_Off;
        MagnetSetting100.antialiasing = true;

        MagnetSetting50 = new FlxSprite(180,Taskbar.y+10, "embed/ui/leveleditor/snap50.png");
        MagnetSetting50.color = Taskbar_Off;
        MagnetSetting50.antialiasing = true;

        MagnetSetting25 = new FlxSprite(210,Taskbar.y+10, "embed/ui/leveleditor/snap25.png");
        MagnetSetting25.color = Taskbar_Off;
        MagnetSetting25.antialiasing = true;

        TaskbarGroup.add(MagnetSetting25);
        TaskbarGroup.add(MagnetSetting50);
        TaskbarGroup.add(MagnetSetting100);
        TaskbarGroup.add(MagnetIcon);


        SaveText = new FlxText(1800,Taskbar.y+2,0,"SAVE",18);
        SaveText.font = "vcr";
        SaveText.antialiasing = true;
        SaveText.camera = FlxGamePlus.OverlayCam;
        SaveText.color = Taskbar_Off;

        LoadText = new FlxText(SaveText.x,SaveText.y+SaveText.height+2,0,"LOAD",18);
        LoadText.font = "vcr";
        LoadText.antialiasing = true;
        LoadText.camera = FlxGamePlus.OverlayCam;
        LoadText.color = Taskbar_Off;

        NewText = new FlxText(SaveText.x,LoadText.y+LoadText.height+2,0,"NEW",18);
        NewText.font = "vcr";
        NewText.antialiasing = true;
        NewText.camera = FlxGamePlus.OverlayCam;
        NewText.color = Taskbar_Off;

        TaskbarGroup.add(SaveText);
        TaskbarGroup.add(LoadText);
        TaskbarGroup.add(NewText);

        //------------------------------------

        hierarchy = new Hierarchy();
        inspector = new Inspector();
        properties = new LevelProperties();

        //------------------------------------

        axle = new Axle();

        axle.onMove = move;
        axle.onScale = scale;
        axle.onChangeAngle = rotate;

        Keyboard.onUiKeyDown.add(OnKeyDown);
	    Keyboard.onUiKeyUp.add(OnKeyUp);

        //------------------------------------

        FlxG.camera.bgColor = FlxColor.BLACK;

        layers = new FlxTypedGroup();
        //create default layer 0
        layers.add(new LayerVisualizer());
        layers.members[0].selected = true;
    }

    @:access(Main)
    override function destroy() {

        instance = null;

        curEditedObject = null;
        tempCurEdited = null;

        Keyboard.onUiKeyDown.remove(OnKeyDown);
	    Keyboard.onUiKeyUp.remove(OnKeyUp);

        axle.destroy();
        axle = null;

        cleanCams();

        Taskbar.destroy();
        Taskbar = null;

        TaskbarGroup.destroy();
        TaskbarGroup = null;

        layers.destroy();
        layers = null;

        if(curSkybox != null){
            curSkybox.destroy();
        }

        staticAssets.resize(0);
        staticAssets = null;

        StaticObject.clearAssets();

        //reset to default
        Application.current.window.setIcon(Main._getWindowIcon(Main.SetupConfig.getConfig("WindowIcon", "string", "embed/defaults/icon32.png")));
		Application.current.window.title = Main.SetupConfig.getConfig("WindowName", "string", "PAE 2.0");

        if(CoreState.watermark != null) CoreState.watermark.visible = true;

        if(doFps){
            Main.fps.visible = fpsVis;
        }

        super.destroy();
    }

    override function switchTo(nextState:FlxState):Bool {
        cleanCams();
        return super.switchTo(nextState);
    }

    var camsClean = false;
    public function cleanCams() {
        if(camsClean) return;
        camsClean = true;

        hierarchy = FlxDestroyUtil.destroy(hierarchy);
        inspector = FlxDestroyUtil.destroy(inspector);
        properties = FlxDestroyUtil.destroy(properties);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    //AXLE HANDLES

    function move() {
        if(curEditedObject == null) return;

        if(snappingEnabled){

            axle.x = Math.round(axle.nonVisualX / snapping) * snapping;
            axle.y = Math.round(axle.nonVisualY / snapping) * snapping;

            curEditedObject.transform.setVisualPosition(axle.x,axle.y);
        }
        else{
            curEditedObject.transform.setVisualPosition(axle.x,axle.y);
        }
    }

    function scale(axis:Int) {
        if(curEditedObject.usesSize) curEditedObject.handleScaling(axis); //components and static objects handle scaling differently.
    }

    function rotate() {
        if(curEditedObject == null) return;

        curEditedObject.transform.setVisualAngle(axle.angle);
    }

    function OnKeyDown(key:KeyCode){
        if(TextField.curSelected != null) return;

        switch (key){
            case W: if(curEditedObject != null) axle.state = MOVE;
            case S:
                if(Keyboard.control) browseSave();
                else if(curEditedObject != null && curEditedObject.usesSize) axle.state = SCALE;
            case R: if(curEditedObject != null) axle.state = ROTATE;
            case DELETE: if(curEditedObject != null) deleteObject(curEditedObject);
            case D: if(curEditedObject != null && Keyboard.control) duplicateObject(curEditedObject);
            default:
        }
    }
    
    function OnKeyUp(key:KeyCode){
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    override function update(elapsed:Float) {
        super.update(elapsed);

        if(curEditedObject != null && !curEditedObject.existsInLevel) curEditedObject = null;
        for (layer in layers) {
            var i = 0;
            while (i < layer.members.length) {
                if(!layer.members[i].existsInLevel) {layer.remove(layer.members[i], true); i--;}
                i++;
            }
        }

        layers.update(elapsed);
        axle.update(elapsed);

        updateTaskbar(elapsed);

        if(FlxG.mouse.justReleased){
            if(curEditedObject != null){
                axle.setPosition(curEditedObject.transform.internalX, curEditedObject.transform.internalY);
            }
        }
        
        if(FlxG.mouse.justPressed){
            var overlapsMain = true;

            if(inspector.overlapped || hierarchy.overlapped || properties.overlapped || inspector.browser.overlapped) overlapsMain = false;
            if(inspector.browser.closedThisFrame) { inspector.browser.closedThisFrame = false; overlapsMain = false; }
            if(overlaps != -1) overlapsMain = false;
            if(Container.contextActive) overlapsMain = false;
            if(axle.overlap != -1) overlapsMain = false;

            if(overlapsMain){
                var localMousePos = FlxPoint.get(0,0);
                localMousePos = Utils.getMousePosInCamera(FlxG.camera, localMousePos);

                var result:GenericObjectVisualizer = null;

                var i = layers.members[curLayer].length;
                while (i-- > 0) {
                    if(!layers.members[curLayer].members[i].visible) continue;
                    result = layers.members[curLayer].members[i].checkIsHit(localMousePos);
                    if(result != null) { tempCurEdited = result; curEditedObject = result; break; }
                }

                if(result == null) { tempCurEdited = null; curEditedObject = null; }

                localMousePos.put();
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    override function draw() {
        if(curSkybox != null && skyboxVisible) Utils.drawSkybox(curSkybox);
        layers.draw();
        axle.draw();

        drawTaskbar();

        super.draw();
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    //taskbar

    var overlaps = -1;

    function drawTaskbar() {
        Taskbar.draw();
        TaskbarFps.draw();
        TaskbarGroup.draw();

        if(overlaps > -1) Mouse.setAs(BUTTON);
    }

    function updateTaskbar(elapsed:Float) {
        if(doFps){
            TaskbarFps.text = "FPS: "+ Main.fps.times.length;
        }

        TaskbarGroup.update(elapsed);

        //buttons--------------------------------------------------------------------------------------------------
        var localMousePos = FlxPoint.get(0,0);
        localMousePos = Utils.getMousePosInCamera(FlxGamePlus.OverlayCam, localMousePos, HierarchyButton);

        SaveText.color = Taskbar_Off;
        LoadText.color = Taskbar_Off;
        NewText.color = Taskbar_Off;

        overlaps = -1;
        if(Taskbar.overlapsPoint(localMousePos)) overlaps = -2;
        if(Utils.overlapsSprite(HierarchyButton,localMousePos)) overlaps = 0;
        if(Utils.overlapsSprite(InspectorButton,localMousePos)) overlaps = 1;
        if(Utils.overlapsSprite(MagnetIcon,localMousePos)) overlaps = 2;
        if(Utils.overlapsSprite(MagnetSetting100,localMousePos)) overlaps = 3;
        if(Utils.overlapsSprite(MagnetSetting50,localMousePos)) overlaps = 4;
        if(Utils.overlapsSprite(MagnetSetting25,localMousePos)) overlaps = 5;
        if(Utils.overlapsSprite(PropertiesButton,localMousePos)) overlaps = 6;
        if(Utils.overlapsSprite(CameraIcon,localMousePos)) overlaps = 7;
        if(SaveText.overlapsPoint(localMousePos)) { overlaps = 8; SaveText.color = Taskbar_On; }
        if(LoadText.overlapsPoint(localMousePos)) { overlaps = 9; LoadText.color = Taskbar_On; }
        if(NewText.overlapsPoint(localMousePos)) { overlaps = 10; NewText.color = Taskbar_On; }

        if(inspector.overlapped || hierarchy.overlapped || properties.overlapped || Container.contextActive) overlaps = -2;

        if(FlxG.mouse.justPressed){
            switch (overlaps){
                case 0: hierarchyOpen ? close_hierarchy() : open_Hierarchy();
                case 1: inspectorOpen ? close_Inspector() : open_Inspector();
                case 2: snappingEnabled = !snappingEnabled; MagnetIcon.color = snappingEnabled ? Taskbar_On : Taskbar_Off;
                case 3: snapping = 100;
                case 4: snapping = 50;
                case 5: snapping = 25;
                case 6: propertiesOpen ? close_Properties() : open_Properties();
                case 7: FlxG.camera.scroll.set();
                case 8: browseSave();
                case 9: browseLoad();
                case 10: deloadCurrentScene();
            }
        }

        //-----------------------------------------------

        //camera--------------------------------------------------------------------------------------------------
        
        CameraIcon.color = Camera_Off;

        if(FlxG.keys.pressed.ALT){
            CameraIcon.color = Camera_Idle;
            if(FlxG.mouse.pressedMiddle) {
                FlxG.camera.scroll.x -= FlxGamePlus.mouseMove[0];
                FlxG.camera.scroll.y -= FlxGamePlus.mouseMove[1];
                CameraIcon.color = Camera_On;
            }
            else if (FlxG.mouse.wheel != 0) {
                FlxG.camera.zoom -= (FlxG.mouse.wheel * 0.005);
                CameraIcon.color = Camera_On;
            }
            
        }

        CameraCoordsXY.text = "X: "+Math.round(FlxG.camera.scroll.x)+"\nY: "+Math.round(FlxG.camera.scroll.y);

        //-----------------------------------------------

        //magnet--------------------------------------------------------------------------------------------------

        MagnetSetting100.color = snapping == 100 ? Taskbar_On : Taskbar_Off;
        MagnetSetting50.color = snapping == 50 ? Taskbar_On : Taskbar_Off;
        MagnetSetting25.color = snapping == 25 ? Taskbar_On : Taskbar_Off;

        //-----------------------------------------------

        localMousePos.put();
    }

    var inspectorOpen = false;
    var hierarchyOpen = false;
    var propertiesOpen = false;

    function open_Hierarchy() {
        hierarchyOpen = true;
        UIPlugin.addContainer(hierarchy);
        HierarchyButton.color = Taskbar_On;
    }

    function close_hierarchy() {
        hierarchyOpen = false;
        hierarchy.close();
        HierarchyButton.color = Taskbar_Off;
    }

    function open_Inspector() {
        inspectorOpen = true;
        UIPlugin.addContainer(inspector);
        InspectorButton.color = Taskbar_On;
    }

    function close_Inspector() {
        inspectorOpen = false;
        inspector.close();
        InspectorButton.color = Taskbar_Off;
    }

    function open_Properties() {
        propertiesOpen = true;
        UIPlugin.addContainer(properties);
        PropertiesButton.color = Taskbar_On;
    }

    function close_Properties() {
        propertiesOpen = false;
        properties.close();
        PropertiesButton.color = Taskbar_Off;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	static function set_curEditedObject(value:GenericObjectVisualizer):GenericObjectVisualizer {
        if(instance == null) return curEditedObject = null;
        if(value != null) {
            LevelEditor.instance.axle.setPosition(value.transform.internalX, value.transform.internalY);
            LevelEditor.instance.axle.angle = value.transform.internalAngle;
            LevelEditor.instance.axle.visible = true;

            if(curEditedObject != null) //fix crash
                if(LevelEditor.instance.axle.state == SCALE && !curEditedObject.usesSize) LevelEditor.instance.axle.state = MOVE;
        }
        else{
            LevelEditor.instance.axle.visible = false;
        }

        curEditedObject = value;

        LevelEditor.instance.inspector.setObject();
        
		return curEditedObject;
	}

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    //world modifying

    public function createBlankObject(?parent:GenericObjectVisualizer) { //creates a dynamic object, for other types, make/use a designated function.
        var o = new ObjectVisualizer();

        o.name = makeUnnamedNew();

        if(parent == null){
            o.transform.x = FlxG.width*0.5 + FlxG.camera.scroll.x;
            o.transform.y = FlxG.height*0.5 + FlxG.camera.scroll.y;
        }
        

        if(parent == null) layers.members[curLayer].add(o);
        else parent.children.add(o);

        hierarchy.addNodeFor(o);
    }

    public function createStaticObject(?parent:GenericObjectVisualizer) {
        var o = new StaticObjectVisualizer();

        o.name = makeUnnamedNew();

        if(parent == null){
            o.transform.x = FlxG.width*0.5 + FlxG.camera.scroll.x;
            o.transform.y = FlxG.height*0.5 + FlxG.camera.scroll.y;
        }
        

        if(parent == null) layers.members[curLayer].add(o);
        else parent.children.add(o);

        hierarchy.addNodeFor(o);
    }

    public function deleteObject(obj:GenericObjectVisualizer) {
        if(obj == null) return;
        obj.existsInLevel = false;

        if(obj.parent != null){
            obj.parent.children.remove(obj);
            obj.parent = null;
        }

        obj.destroy();
    }

    private function duplicate(obj:GenericObjectVisualizer, ?parent:GenericObjectVisualizer):GenericObjectVisualizer {
        var o = Type.createInstance(Type.getClass(obj),[]);

        if(parent == null) layers.members[curLayer].add(o);
        else parent.children.add(o);

        o.transform.x = obj.transform.x;
        o.transform.y = obj.transform.y;
        o.transform.internalX = parent == null ? o.transform.x : o.transform.x+parent.transform.internalX;
        o.transform.internalY = parent == null ? o.transform.y : o.transform.y+parent.transform.internalY;
        o.transform.angle = obj.transform.angle;

        o.name = getLowestValidName(obj.name);

        obj.duplicate(o);

        for (object in obj.children) {
            var child = duplicate(object, o);
            o.children.add(child);
        }

        return o;
    }

    public function duplicateObject(obj:GenericObjectVisualizer) {
        var o = duplicate(obj, obj.parent);
        hierarchy.addNodeFor(o);
        curEditedObject = o;
    }

    public function setSkybox(to:String) {
        if(to == ""){
            skybox = to;
            if(curSkybox == null) return;
            curSkybox.destroy();
            curSkybox = null;

            return;
        }
        if(!FileSystem.exists(to) || !to.endsWith(".asset")) return;

        if(curSkybox == null) curSkybox = new Skybox(0,0,null);

        curSkybox.setAsset(ImageAsset.get(to));

        skybox = to;
    }

    public function setScript(to:String) {
        script = to;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    //name engine

    public function checkNameValid(name:String):Bool {
        return !getObjectExists(name);
    }

    public function makeUnnamedNew():String {
        if(checkNameValid("unnamed")) return "unnamed";
        return getLowestValidName("unnamed");
    }

    public function getLowestValidName(name:String):String {
        name = NameUtils.removeFormattedNumber(name);
        var samenamelist:Array<String> = [];

        for (layer in layers) {
            for (generic in layer) {
                samenamelist = samenamelist.concat(recursiveNames(name, generic));
            }
        }

        var highestNumber:Int = 0;

        for (equalname in samenamelist) {
            if(NameUtils.endsInFormattedNumerics(equalname)){
                var n = NameUtils.getNumber(equalname);

                if(n > highestNumber)
                    highestNumber = n;
            }
        }

        samenamelist = null;
        return (name+"_"+(highestNumber+1));
    }

    public function recursiveNames(ogName:String, generic:GenericObjectVisualizer):Array<String> {
        var samenamelist:Array<String> = [];
        if(NameUtils.removeFormattedNumber(generic.name) == ogName){
            samenamelist.push(generic.name);
        }

        for (object in generic.children) {
            samenamelist = samenamelist.concat(recursiveNames(ogName, object));
        }

        return samenamelist;
    }

    public function getObjectExists(name:String):Bool {
        var samenamelist:Array<String> = [];
        for (layer in layers) {
            for (generic in layer) {
                samenamelist = samenamelist.concat(recursiveNames(name, generic));
            }
        }

        if(samenamelist.contains(name)) return true;

        samenamelist = null;
        return false;
    }

    //technically not nameEngine but still a name

    public function setLevelName(to:String){
        name = to;
        Application.current.window.title = "PAE2.0 - Level editor - "+name;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    //staticObjects

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    //SAVES

    public function save():LevelFile {
        staticAssets = [];
        var data:LevelFile = {
            levelName: name,
            curLayer: curLayer,
            gridSize: snapping,
            snapping: snappingEnabled,

            bitmaps: null,

            layers: [],
            skybox: skybox,
            skyboxVisible: skyboxVisible,
            script: script,
            backgroundColor: {
                R: FlxG.camera.bgColor.red,
                G: FlxG.camera.bgColor.green,
                B: FlxG.camera.bgColor.blue,
                A: FlxG.camera.bgColor.alpha
            }
        }

        for (layer in layers) {
            var l:LayerStructure = {
                enabledByDefault: layer.enabledByDefault,
                visible: layer.visible,
                objects: [],
                rails: []
            }

            for (object in layer) {
                var o = parseObjectData(object);
                l.objects.push(o);
            }

            data.layers.push(l);
        }

        data.bitmaps = staticAssets;

        return data;
    }

    function parseObjectData(object:GenericObjectVisualizer):Dynamic {
        if(Std.isOfType(object,ObjectVisualizer)){
            var object:ObjectVisualizer = cast object;
            var obj:FullObjectDataStructure = {
                _TYPE: "FULL",
                name: object.name,
                extended: object.extended,
                active: object.visible,
                transform: {
                    X: object.transform.x,
                    Y: object.transform.y,
                    A: object.transform.angle,
                    Z: 0
                },
                components: [],
                children: [],
                drawOrder: object.drawOrder,
                Static: object.isStatic
            }

            for (component in object.components) {
                var startingData:Dynamic = {};
                for (variable in component.variables) {
                    Reflect.setField(startingData,variable[0],variable[1]);
                }

                var comp:ComponentInstance = {
                    component: component.component.key,
                    extended: component.extended,
                    startingData: startingData
                }

                obj.components.push(comp);
            }

            for (children in object.children) {
                var child = parseObjectData(children);
                if(child != null) obj.children.push(child);
            }

            return obj;
        }

        if(Std.isOfType(object, StaticObjectVisualizer)){
            var object:StaticObjectVisualizer = cast object;

            var idx:Int = staticAssets.indexOf(object.spritePath);
            if(idx == -1) { staticAssets.push(object.spritePath); idx = staticAssets.length-1; }

            var obj:StaticSpriteDataStructure = {
                _TYPE: "STATIC_SPRITE",
                name: object.name,
                extended: object.extended,
                active: object.visible,
                drawOrder: object.drawOrder,
                children: [],
                transform: {
                    X: object.transform.x,
                    Y: object.transform.y,
                    Z: object.transform.z,
                    A: object.transform.angle
                },
                scale: {
                    W: object.width,
                    H: object.height
                },
                bitmapIndex: idx
            }

            for (children in object.children) {
                var child = parseObjectData(children);
                if(child != null) obj.children.push(child);
            }

            return obj;
        }

        trace("OBJECT TYPE PARSER NOT IMPLEMENTED! : "+object.name);
        return null;
    }

    public function browseSave() {
        FileBrowser.callback = onSaveBrowsed;
        FileBrowser.save("PLACEHOLDER, SOMETHING MAY HAVE GONE WRONG.", name.replace(" ","_")+(name.replace(" ","_").endsWith(".") ? "map" : ".map"));
    }

    @:access(flixel.input.mouse.FlxMouse)
    public function onSaveBrowsed() {
        FlxG.mouse._leftButton.current = RELEASED; //fix deselecting.
        switch (FileBrowser.latestResult){
            case SELECT, CANCEL, ERROR: return;
            case SAVE:
                LogFile.log("Saving current map...",true);
                trace(FileBrowser.filePath);
                var finalPath = FileBrowser.filePath;
                if(!finalPath.endsWith(".map")) finalPath += ".map";

                var finalSaveData = "SOMETHING WENT WRONG, PLEASE CHECK LOGS.";

                try{
                    finalSaveData = Json.stringify(save(),null," ");
                }
                catch(e){
                    LogFile.error("Error when saving level! : "+e.message);
                    finalSaveData = "SOMETHING WENT WRONG, PLEASE CHECK LOGS.";
                }

                File.saveContent(finalPath, finalSaveData);
                AssetCache.removeDataCache(finalPath);
        }
    }

    public function deloadCurrentScene() {
        curEditedObject = null;
        setLevelName("Unnamed map.");
        properties.levelName.textField.text = "Unnamed map.";
        properties.levelName.caret = properties.levelName.textField.text.length;
        properties.levelName.onUpdateText();

        script = properties.script.textField.text = "";
        properties.script.caret = properties.script.textField.text.length;
        properties.script.onUpdateText();

        setSkybox("");
        properties.skyboxVisible.checked = skyboxVisible = true;
        properties.skybox.textField.text = "";
        properties.skybox.caret = properties.skybox.textField.text.length;
        properties.skybox.onUpdateText();

        staticAssets = [];

        FlxG.camera.bgColor = FlxColor.BLACK;
        properties.bgColor.color = FlxColor.BLACK;

        snapping = 25;
        snappingEnabled = false;
        MagnetIcon.color = snappingEnabled ? Taskbar_On : Taskbar_Off;


        curLayer = 0;
        layers.destroy();
        layers = new FlxTypedGroup();
        //create default layer 0
        layers.add(new LayerVisualizer());
        layers.members[0].selected = true;

        hierarchy.curLayer.setChoices(["0"]);

        hierarchy.layerEnabled.checked = layers.members[0].enabledByDefault;
        hierarchy.layerVisible.checked = layers.members[0].visible;
    }

    public function load(level:LevelFile) {
        deloadCurrentScene(); //buh bye

        setLevelName(properties.levelName.textField.text = level.levelName);
        properties.levelName.caret = properties.levelName.textField.text.length;
        properties.levelName.onUpdateText();

        script = properties.script.textField.text = level.script;
        properties.script.caret = properties.script.textField.text.length;
        properties.script.onUpdateText();

        setSkybox(properties.skybox.textField.text = level.skybox);
        properties.skybox.caret = properties.skybox.textField.text.length;
        properties.skybox.onUpdateText();

        properties.skyboxVisible.checked = skyboxVisible = level.skyboxVisible;

        staticAssets = level.bitmaps;

        FlxG.camera.bgColor = properties.bgColor.color = FlxColor.fromRGB(
            level.backgroundColor.R,
            level.backgroundColor.G,
            level.backgroundColor.B,
            level.backgroundColor.A);

        snapping = level.gridSize;
        snappingEnabled = level.snapping;
        MagnetIcon.color = snappingEnabled ? Taskbar_On : Taskbar_Off;

        //--------------------------------------------------------------------------------------------

        curLayer = level.curLayer;
        var hLayers:Array<String> = [];

        layers.destroy();
        layers = new FlxTypedGroup();
    
        StaticObject.setAssets(staticAssets);

        for (layerStructure in level.layers) {
            hLayers.push(Std.string(layers.length));
            var layer = new LayerVisualizer();

            layer.enabledByDefault = layerStructure.enabledByDefault;

            layer.visible = layerStructure.visible;

            for (json in layerStructure.objects) {
                var o = GenericObjectVisualizer.makefromJson(json);
                if(o != null) layer.add(o);
            }

            layers.add(layer);
            layer.selected = false;
        }

        layers.members[curLayer].selected = true;

        hierarchy.curLayer.setChoices(hLayers);
        hierarchy.curLayer.list.selected = curLayer;
        hierarchy.curLayer.selected.text = Std.string(curLayer);

        hierarchy.layerEnabled.checked = layers.members[curLayer].enabledByDefault;
        hierarchy.layerVisible.checked = layers.members[curLayer].visible;

        hierarchy.switchLayerTo(layers.members[curLayer]);
    }

    public function browseLoad() {
        FileBrowser.callback = onLoadBrowsed;
        FileBrowser.browse([new FileFilter("Map files","*.map")],false);
    }

    @:access(flixel.input.mouse.FlxMouse)
    public function onLoadBrowsed() {
        FlxG.mouse._leftButton.current = RELEASED; //fix deselecting.
        switch (FileBrowser.latestResult){
            case SAVE, CANCEL, ERROR: return;
            case SELECT:
                trace(FileBrowser.filePath);

                if(!FileBrowser.filePath.endsWith(".map")) return;
                LogFile.log("LOADING NEW MAP...",true);
                
                var error = false;
                var level:LevelFile = null;
                try{
                    level = cast Json.parse(File.getContent(FileBrowser.filePath));
                }
                catch(e){
                    LogFile.error("Error when saving level! : "+e.message);
                    error = true;
                }

                if(!error) { load(level); LogFile.log("LOADED NEW MAP.",true); }
        }
    }
}