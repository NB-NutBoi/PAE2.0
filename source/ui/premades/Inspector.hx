package ui.premades;

import ui.elements.Button;
import FlxGamePlus;
import oop.Component.ComponentClass;
import flixel.math.FlxPoint;
import utility.Utils;
import ui.premades.inspector.TransformField;
import ui.elements.TextField;
import ui.elements.Checkbox;
import flixel.FlxSprite;
import leveleditor.ComponentVisualizer;
import leveleditor.LevelEditor;
import ui.elements.Context;
import ui.elements.StackableObject;
import ui.premades.inspector.InspectorComponentNode;
import flixel.group.FlxGroup.FlxTypedGroup;
import ui.base.Container;
import ui.elements.ContainerMover;
import flixel.FlxG;
import leveleditor.ObjectVisualizer;

//SPECIAL CASE!!!
//no need to optimize beyond standard, it's only ever gonna be used in the level editor
class Inspector extends Container {
    public static var instance:Inspector = null;
    public static final BG:Int = 0xFF1D1D1D;

    static final nodesBaseY:Float = 100;


    public var isActive:Checkbox;
    public var name:TextField;
    public var transform:TransformField;

    public var flap:FlxSprite;

    public var nodes:FlxTypedGroup<InspectorComponentNode>;
    public var stack:StackableObject;
    public var addButton:Button;


    public var browser:InspectorComponentBrowser;


    var type:Int = -1;

    override public function new() {
        super(FlxG.width-250,10,250,700);

        instance = this;

        flap = Utils.makeRamFriendlyRect(0,0,250,Std.int(nodesBaseY),BG);
        flap.scrollFactor.set();
        add(flap);

        isActive = new Checkbox(66,8,"Active",setActive);
        isActive.setScrollFactor();
        add(isActive);

        name = new TextField(3,38,240);
        name.setScrollFactor();
        name.onPressEnter.add(setName);
        add(name);
        

        nodes = new FlxTypedGroup();
        nodes.camera = cam;
        stack = new StackableObject(0,0);

        var mover:ContainerMover = new ContainerMover();
        super.mover = mover;

        browser = new InspectorComponentBrowser();

        addButton = new Button(0,0,250,30,"Add Component...",openComponentBrowser);
        add(addButton);
    }

    override function destroy() {

        instance = null;

        super.destroy();
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    override function update(elapsed:Float) {
        if(overlapped && focused){
            cam.scroll.y -= FlxG.mouse.wheel * 10;
            if(cam.scroll.y < 0) cam.scroll.y = 0;
        }

        super.update(elapsed);

        stack.combinedHeight = 0;

        for (node in nodes) {
            node.update(elapsed);
            node.setPosition(0,nodesBaseY+stack.combinedHeight);
            stack.combinedHeight += node.combinedHeight;
        }
    }

    override function updateInputs(elapsed:Float) {
        if(!visible) return;
        if(!overlapped) return;
        if(Container.contextActive) return;

        if(LevelEditor.curEditedObject != null)
            super.updateInputs(elapsed);

        var localMousePos = FlxPoint.get(0,0);
        localMousePos = Utils.getMousePosInCamera(cam, localMousePos, flap);

        if(!flap.overlapsPoint(localMousePos)){
            for (node in nodes) {
                node.updateInputs(elapsed);
            }
        }

        localMousePos.put();
    }

    override function postUpdate(elapsed:Float) {
        super.postUpdate(elapsed);

        for (node in nodes) {
            node.postUpdate(elapsed);
        }

        addButton.setPosition(0,nodesBaseY+stack.combinedHeight);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    override function draw() {
        bg.draw();
        
        nodes.draw();

        if(LevelEditor.curEditedObject != null)
            stuffs.draw();

        if(mover != null)
            mover.draw();
        if(closer != null)
            closer.draw();
    }

    public function openComponentBrowser() {
        if(browser.opened) return;
        UIPlugin.addContainer(browser);
        browser.opened = true;
        browser.setObject(cast LevelEditor.curEditedObject);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    //interacting with the object

    public function setActive(to:Bool) {
        LevelEditor.curEditedObject.visible = to;
    }

    public function setName(_) {
        LevelEditor.curEditedObject.name = _;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public function setObject() {
        //takes the curEdited object, no need to feed it to the function
        
        destroyPreviousInspectorLayout();

        type = -1;

        if(LevelEditor.curEditedObject == null) return;

        isActive.checked = LevelEditor.curEditedObject.visible;
        name.textField.text = LevelEditor.curEditedObject.name;
        name.caret = name.textField.text.length;
        name.onUpdateText();

        if(Std.isOfType(LevelEditor.curEditedObject, ObjectVisualizer)){
            type = 1;
            var obj:ObjectVisualizer = cast LevelEditor.curEditedObject;

            addButton.disabled = false;

            for (component in obj.components) {
                addNodeFor(component);
            }
        }
        else{
            addButton.disabled = true;
        }
    }

    function destroyPreviousInspectorLayout() {
        stack.combinedHeight = 0;
        nodes.destroy();
        nodes = new FlxTypedGroup();

        if(browser.opened) browser.close();
    }

    public function addNodeFor(component:ComponentVisualizer) {
        var node = new InspectorComponentNode(component, this);
        nodes.add(node);
        var old = component.extended;
        node.extended = true;
        node.update(0);
        node.setPosition(0,nodesBaseY+stack.combinedHeight);
        stack.combinedHeight += node.combinedHeight;
        node.update(0);
        node.extended = old;
        //complicated update order because cring
    }
    
    public function addComponent(cClass:ComponentClass) {
        if(LevelEditor.curEditedObject == null) return;
        if(!Std.isOfType(LevelEditor.curEditedObject, ObjectVisualizer)) return;
        var obj:ObjectVisualizer = cast LevelEditor.curEditedObject;

        var comp = ComponentVisualizer.make(cClass.key, obj);

        addNodeFor(comp);
    }

    function addTestComponent() {
        if(!Std.isOfType(LevelEditor.curEditedObject, ObjectVisualizer)) return;
        var obj:ObjectVisualizer = cast LevelEditor.curEditedObject;

        var comp = ComponentVisualizer.make("Sprite", obj);

        addNodeFor(comp);
    }

    function addTestComponent2() {
        if(!Std.isOfType(LevelEditor.curEditedObject, ObjectVisualizer)) return;
        var obj:ObjectVisualizer = cast LevelEditor.curEditedObject;

        var comp = ComponentVisualizer.make("Text", obj);

        addNodeFor(comp);
    }
}