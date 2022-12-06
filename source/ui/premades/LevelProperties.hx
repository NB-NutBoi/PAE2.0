package ui.premades;

import flixel.FlxSprite;
import flixel.FlxG;
import flixel.util.FlxColor;
import ui.elements.ColorPicker;
import ui.elements.Checkbox;
import sys.FileSystem;
import lowlevel.FileBrowser;
import openfl.net.FileFilter;
import ui.elements.Button;
import utility.Utils;
import leveleditor.LevelEditor;
import ui.elements.TextField;
import flixel.text.FlxText;
import ui.base.Container;
import ui.elements.ContainerMover;

using StringTools;

class LevelProperties extends Container {
    public static var instance:LevelProperties;

    public var levelName:TextField;

    public var skybox:TextField;
    public var skyboxVisible:Checkbox;

    var scriptSafe:FlxSprite;
    public var script:TextField;

    public var bgColor:ColorPicker;

    override public function new() {
        super(0,700,400,300);
        
        instance = this;

        var mover:ContainerMover = new ContainerMover();
        super.mover = mover;

        var label = new FlxText(66,10,0,"Level properties",18); label.font = "vcr";
        add(label);


        levelName = new TextField(10,40,376);
        levelName.textField.text = LevelEditor.instance.name;
        levelName.caret = LevelEditor.instance.name.length;
        levelName.onUpdateText();
        levelName.onPressEnter.add(setName);
        add(levelName);
        
        add(Utils.makeRamFriendlyRect(5,75,390,2));

        label = new FlxText(10,90,0,"Skybox",18); label.font = "vcr";
        add(label);

        skybox = new TextField(60,113,326);
        skybox.onPressEnter.add(setSkybox);
        add(skybox);

        var selectButton = new Button(10,113,20,27,"...",browseSkybox);
        add(selectButton);

        skyboxVisible = new Checkbox(10,145,"Visible (editor only)", setSkyboxVisible);
        skyboxVisible.checked = LevelEditor.instance.skyboxVisible;
        add(skyboxVisible);

        add(Utils.makeRamFriendlyRect(5,175,390,2));

        label = new FlxText(10,185,0,"Background color",18); label.font = "vcr";
        add(label);

        bgColor = new ColorPicker(200,185,FlxColor.BLACK);
        bgColor.onUpdateColor = setBgColor;
        add(bgColor);

        add(Utils.makeRamFriendlyRect(5,220,390,2));

        label = new FlxText(10,235,0,"Script",18); label.font = "vcr";
        add(label);

        scriptSafe = new FlxSprite(370,235,"embed/ui/tick.png");
        scriptSafe.antialiasing = true;
        scriptSafe.color = FlxColor.LIME;
        add(scriptSafe);

        script = new TextField(60,263,326);
        script.onPressEnter.add(setScript);
        script.onType.add(editScript);
        add(script);

        selectButton = new Button(10,263,20,27,"...",browseScript);
        add(selectButton);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function setName(to:String) {
        LevelEditor.instance.setLevelName(to);
    }

    function setSkybox(to:String) {
        LevelEditor.instance.setSkybox(to);
    }

    function setBgColor(to:FlxColor) {
        FlxG.camera.bgColor = to;
    }

    function setSkyboxVisible(to:Bool) {
        LevelEditor.instance.skyboxVisible = to;
    }

    function setScript(to:String) {
        LevelEditor.instance.setScript(to);
        scriptSafe.color = FlxColor.LIME;
    }

    function editScript() {
        scriptSafe.color = FlxColor.RED;
    }

    function browseSkybox() {
        FileBrowser.callback = _fileBrowsed;
        FileBrowser.browse([new FileFilter("Asset files", "*.asset")], false);
    }

    function _fileBrowsed() {
        switch (FileBrowser.latestResult){
            case SAVE, CANCEL, ERROR: return;
            case SELECT:
                if(!FileBrowser.filePath.endsWith(".asset")) return;

                skybox.textField.text = FileBrowser.filePath;
                skybox.caret = FileBrowser.filePath.length;
                skybox.onUpdateText();

                setSkybox(skybox.textField.text);
        }
    }

    function browseScript() {
        FileBrowser.callback = _scriptBrowsed;
        FileBrowser.browse([new FileFilter("Script files", "*.hx")], false);
    }

    function _scriptBrowsed() {
        switch (FileBrowser.latestResult){
            case SAVE, CANCEL, ERROR: return;
            case SELECT:
                if(!FileBrowser.filePath.endsWith(".hx")) return;

                script.textField.text = FileBrowser.filePath;
                script.caret = FileBrowser.filePath.length;
                script.onUpdateText();

                setScript(script.textField.text);
        }
    }
}