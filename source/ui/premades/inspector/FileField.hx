package ui.premades.inspector;

import oop.Component;
import flixel.util.FlxDestroyUtil;
import flixel.FlxG;
import lowlevel.FileBrowser;
import utility.Utils;
import ui.base.Container;
import flixel.FlxSprite;
import flixel.text.FlxText;
import ui.elements.TextField;
import ui.elements.Button;
import ui.premades.inspector.InspectorComponentNode.NodeField;

class FileField extends NodeField {
    
    public var text:FlxText;
    public var fileField:TextField;
    public var button:Button;
    public var sepparator:FlxSprite;

    override public function new(name:String, defaultValue:String, ?parent:Container) {
        super(name, parent);

        text = new FlxText(0,0,0,name,14);
        text.font = "vcr";
        text.antialiasing = true;
        add(text);

        fileField = new TextField(60,0,180);
        fileField.textField.text = defaultValue;
        fileField.caret = fileField.textField.text.length;
        fileField.onUpdateText();
        fileField.onPressEnter.add(onEnter);
        fileField.onDeselect.add(deselect);
        add(fileField);

        button = new Button(10,0,20,27,"...",browseFile);
        add(button);

        sepparator = Utils.makeRamFriendlyRect(0,0,240,2);
        add(sepparator);

        stackObject.combinedHeight = stackObject.height = 55;
    }

    override function destroy() {

        text = FlxDestroyUtil.destroy(text);
        fileField = FlxDestroyUtil.destroy(fileField);
        button = FlxDestroyUtil.destroy(button);
        sepparator = FlxDestroyUtil.destroy(sepparator);

        super.destroy();
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        if(component.UPDATE_VARIABLES){
            if(Component.getArray(key,component.variables) != fileField.textField.text){
                fileField.textField.text = Component.getArray(key,component.variables);
                fileField.caret = fileField.textField.text.length;
                fileField.onUpdateText();
            }
        }

        text.setPosition(stackObject.x+2,stackObject.y+1.5);
        button.setPosition(stackObject.x+10,stackObject.y+20.5);
        fileField.setPosition(stackObject.x+60,stackObject.y+20.5);
        sepparator.setPosition(stackObject.x+5,stackObject.y+53);
    }

    function browseFile() {
        FileBrowser.callback = onBrowsed;
        FileBrowser.browse(false);
    }

    @:access(flixel.input.mouse.FlxMouse)
    function onBrowsed() {
        FlxG.mouse._leftButton.current = RELEASED; //fix deselecting.
        switch (FileBrowser.latestResult){
            case SAVE, CANCEL, ERROR: return;
            case SELECT:
                fileField.textField.text = FileBrowser.filePath;
                fileField.caret = FileBrowser.filePath.length;
                fileField.onUpdateText();

                onEnter(key);
        }
    }

    public function deselect() {
        onEnter("");
    }

    public function onEnter(_) {
        Component.setArray(key, fileField.textField.text, component.variables);
		component.changeVariable(key);
    }

}