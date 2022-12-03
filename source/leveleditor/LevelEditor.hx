package leveleditor;

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

    @:isVar public static var curEditedObject(get,set):GenericObjectVisualizer = null;
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

        //------------------------------------

    //------------------------------------

    override function create() {
        super.create();

        instance = this;

        //map-icon
        Application.current.window.setIcon(Assets.getImage("embed/defaults/leveleditor/icon512.png"));

        name = "Unnamed map.";
        Application.current.window.title = "PAE2.0 - Level editor - Unnamed map.";

        skybox = "";
        script = "";
        staticAssets = [];

        //------------------------------------

        if(!Main.instance.nofps){
            Main.fps.visible = false;
            doFps = true;
        }

        //------------------------------------

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

        //------------------------------------

        hierarchy = new Hierarchy();
        inspector = new Inspector();
        properties = new LevelProperties();

        //------------------------------------

        axle = new Axle();

        axle.onMove = move;
        axle.onScale = scale;
        axle.onChangeAngle = rotate;

        //------------------------------------

        layers = new FlxTypedGroup();
        //create default layer 0
        layers.add(new LayerVisualizer());
        layers.members[0].selected = true;
    }

    @:access(Main)
    override function destroy() {

        curEditedObject = null;
        tempCurEdited = null;

        
        instance = null;

        axle.destroy();
        axle = null;

        hierarchy.destroy();
        hierarchy = null;

        inspector.destroy();
        inspector = null;

        properties.destroy();
        properties = null;

        Taskbar.destroy();
        Taskbar = null;

        TaskbarGroup.destroy();
        TaskbarGroup = null;

        layers.destroy();


        if(curSkybox != null){
            curSkybox.asset.important = false;
            curSkybox.destroy();
            curSkybox = null;
        }

        staticAssets.resize(0);
        staticAssets = null;

        //reset to default
        Application.current.window.setIcon(Main._getWindowIcon(Main.SetupConfig.getConfig("WindowIcon", "string", "embed/defaults/icon32.png")));
		Application.current.window.title = Main.SetupConfig.getConfig("WindowName", "string", "PAE 2.0");

        super.destroy();
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
        
    }

    function rotate() {
        if(curEditedObject == null) return;

        curEditedObject.transform.setVisualAngle(axle.angle);
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

            if(inspector.overlapped || hierarchy.overlapped) overlapsMain = false;
            if(overlaps != -1) overlapsMain = false;
            if(Container.contextActive) overlapsMain = false;
            if(axle.overlap != -1) overlapsMain = false;

            if(overlapsMain){
                var localMousePos = FlxPoint.get(0,0);
                localMousePos = Utils.getMousePosInCamera(FlxG.camera, localMousePos);

                var result:ObjectVisualizer = null;

                for (i in layers.members[curLayer].length...0) {
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
        super.draw();

        if(curSkybox != null && skyboxVisible) Utils.drawSkybox(curSkybox);
        layers.draw();
        axle.draw();

        drawTaskbar();
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

        overlaps = -1;
        if(Taskbar.overlapsPoint(localMousePos)) overlaps = -2;
        if(Utils.overlapsSprite(HierarchyButton,localMousePos)) overlaps = 0;
        if(Utils.overlapsSprite(InspectorButton,localMousePos)) overlaps = 1;
        if(Utils.overlapsSprite(MagnetIcon,localMousePos)) overlaps = 2;
        if(Utils.overlapsSprite(MagnetSetting100,localMousePos)) overlaps = 3;
        if(Utils.overlapsSprite(MagnetSetting50,localMousePos)) overlaps = 4;
        if(Utils.overlapsSprite(MagnetSetting25,localMousePos)) overlaps = 5;
        if(Utils.overlapsSprite(PropertiesButton,localMousePos)) overlaps = 6;

        if(FlxG.mouse.justPressed){
            switch (overlaps){
                case 0: hierarchyOpen ? close_hierarchy() : open_Hierarchy();
                case 1: inspectorOpen ? close_Inspector() : open_Inspector();
                case 2: snappingEnabled = !snappingEnabled; MagnetIcon.color = snappingEnabled ? Taskbar_On : Taskbar_Off;
                case 3: snapping = 100;
                case 4: snapping = 50;
                case 5: snapping = 25;
                case 6: propertiesOpen ? close_Properties() : open_Properties();
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

    static function get_curEditedObject():GenericObjectVisualizer {
		return curEditedObject;
	}

	static function set_curEditedObject(value:GenericObjectVisualizer):GenericObjectVisualizer {
        if(value != null) {
            LevelEditor.instance.axle.setPosition(value.transform.internalX, value.transform.internalY);
            LevelEditor.instance.axle.angle = value.transform.internalAngle;
            LevelEditor.instance.axle.visible = true;
        }
        else{
            LevelEditor.instance.axle.visible = false;
        }
        
		return curEditedObject = value;
	}

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    //world modifying

    public function createBlankObject(?parent:GenericObjectVisualizer) { //creates a dynamic object, for other types, make/use a designated function.
        var o = new ObjectVisualizer();

        o.name = "unnamed "+FlxG.random.int(0,20); //TODO this is temporary.

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
        o.transform.angle = obj.transform.angle;

        o.name = obj.name; //TODO add name engine

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
    }

    public function setSkybox(to:String) {
        if(to == ""){
            curSkybox.asset.important = false;
            curSkybox.destroy();
            curSkybox = null;

            skybox = to;

            return;
        }
        if(!FileSystem.exists(to) || !to.endsWith(".asset")) return;

        if(curSkybox == null) curSkybox = new Skybox(0,0,null);
        else {
            curSkybox.graphic = null;
            
            if(curSkybox.animOffsets != null) curSkybox.animOffsets.clear();
            curSkybox.animOffsets = null;

            curSkybox.asset.important = false;
            curSkybox.asset.destroy();

            curSkybox.asset = null;
        }

        curSkybox.setAsset(ImageAsset.get(to));

        skybox = to;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    //names

    public function checkNameValid(name:String):Bool {
        return false;
    }

    public function makeUnnamedNew():String {
        return "";
    }

    public function getLowestValidName(name:String):String {
        return "";
    }

    public function getObjectByName(name:String):ObjectVisualizer {
        return null;
    }

    //technically not nameEngine but still a name

    public function setLevelName(to:String){
        name = to;
        Application.current.window.title = "PAE2.0 - Level editor - "+name;
    }
}