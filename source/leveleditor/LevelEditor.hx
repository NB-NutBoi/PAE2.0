package leveleditor;

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

class LevelEditor extends CoreState {
    public static var instance:LevelEditor;

    @:isVar public static var curEditedObject(get,set):ObjectVisualizer = null;
    public static var tempCurEdited:ObjectVisualizer = null;

    public var hierarchy:Hierarchy;
    public var inspector:Inspector;

    var axle:Axle;

    public var layers:FlxTypedGroup<LayerVisualizer>;
    public var curLayer:Int = 0;

    //------------------------------------

    public var snappingEnabled:Bool = true;
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

        //------------------------------------

    //------------------------------------

    override function create() {
        super.create();

        instance = this;

        //map-icon
        Application.current.window.setIcon(Assets.getImage("embed/defaults/leveleditor/icon512.png"));

        Application.current.window.title = "PAE2.0 - Level editor - Unnamed map.";

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


        HierarchyButton = new FlxSprite(130,FlxG.height-63,"embed/ui/leveleditor/HierarchyIcon.png");
        HierarchyButton.camera = FlxGamePlus.OverlayCam;
        HierarchyButton.color = Taskbar_Off;

        TaskbarGroup.add(HierarchyButton);

        FlxGamePlus.OverlayCam.bgColor.alpha = 0;

        //------------------------------------

        hierarchy = new Hierarchy();

        //------------------------------------

        axle = new Axle();

        axle.onMove = move;
        axle.onScale = scale;
        axle.onChangeAngle = rotate;

        //------------------------------------

        layers = new FlxTypedGroup();
        //create default layer 0
        layers.add(new LayerVisualizer());
    }

    @:access(Main)
    override function destroy() {

        //reset to default
        instance = null;

        axle.destroy();

        hierarchy.destroy();
        hierarchy = null;

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
            curEditedObject.x = axle.x = Math.round(axle.nonVisualX / snapping) * snapping;
            curEditedObject.y = axle.y = Math.round(axle.nonVisualY / snapping) * snapping;
        }
        else{
            curEditedObject.x = axle.x;
            curEditedObject.y = axle.y;
        }
    }

    function scale(axis:Int) {
        
    }

    function rotate() {
        
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

        updateTaskbar(elapsed);

        axle.update(elapsed);
        if(FlxG.mouse.justReleased){
            if(curEditedObject != null){
                axle.setPosition(curEditedObject.x, curEditedObject.y);
            }
        }
        
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    override function draw() {
        super.draw();

        layers.draw();
        axle.draw();

        drawTaskbar();
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    //taskbar

    var overlaps = false;

    function drawTaskbar() {
        Taskbar.draw();
        TaskbarFps.draw();
        TaskbarGroup.draw();

        if(overlaps) Mouse.setAs(BUTTON);
    }

    function updateTaskbar(elapsed:Float) {
        if(doFps){
            TaskbarFps.text = "FPS: "+ Main.fps.times.length;
        }

        TaskbarGroup.update(elapsed);

        //buttons--------------------------------------------------------------------------------------------------
        var localMousePos = FlxPoint.get(0,0);
        localMousePos = Utils.getMousePosInCamera(FlxGamePlus.OverlayCam, localMousePos, HierarchyButton);
        
        overlaps = false;

        if(Utils.overlapsSprite(HierarchyButton,localMousePos)) overlaps = true;

        if(overlaps && FlxG.mouse.justPressed) hierarchyOpen ? close_hierarchy() : open_Hierarchy();

        //-----------------------------------------------

        

        localMousePos.put();
    }


    var hierarchyOpen = false;

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

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    static function get_curEditedObject():ObjectVisualizer {
		return curEditedObject;
	}

	static function set_curEditedObject(value:ObjectVisualizer):ObjectVisualizer {
        if(value != null) {
            LevelEditor.instance.axle.setPosition(value.x, value.y);
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

    public function createBlankObject(?parent:ObjectVisualizer) {
        var o = new ObjectVisualizer();

        o.x = 500;
        o.y = 500;

        if(parent == null) layers.members[curLayer].add(o);
        else parent.children.add(o);

        hierarchy.addNodeFor(o);
    }

    public function deleteObject(obj:ObjectVisualizer) {
        if(obj == null) return;
        obj.existsInLevel = false;

        if(obj.parent != null){
            obj.parent.children.remove(obj);
            obj.parent = null;
        }

        obj.destroy();
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
}