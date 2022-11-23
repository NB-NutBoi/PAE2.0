package ui.premades;
//------------------------------------------------------------
//------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------|
/* This file is under protection and belongs to the PA: AUN project team.                                  |
 * You may learn from this code and / or modify the source code for redistribution with proper accrediting.|
 * -NUT                                                                                                    |
 *///                                                                                                      |
//---------------------------------------------------------------------------------------------------------|

import openfl.net.FileFilter;
import lowlevel.FileBrowser;
import ui.elements.CustomButton;
import common.ClientPreferences;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import ui.base.Container;
import ui.elements.Button;
import ui.elements.Checkbox;
import ui.elements.ContainerCloser;
import ui.elements.ContainerMover;
import ui.elements.ScrollBar;
import ui.elements.SelectableList;
import ui.elements.TextField;
import utility.ConsoleCommands;
import utility.LogFile;
import utility.Utils;


class DebugMenu extends DMenu {

    var debugCam:Null<FlxCamera> = null;
    static var debugCamControls:Bool = false;
    var debugCamLabel:FlxText;
    var debugCamIndicator:FlxSprite;
    var paused:Checkbox;

    var lastX:Float = 0;
    var lastY:Float = 0;
    var lastZoom:Float = 0;

    var debugScrollValue1:FlxText;
    var debugScrollValue2:FlxText;

    var test5:SelectableList;

    var measuringToolSprite:FlxSprite;
    
    override public function new(x:Float,y:Float) {
        super(x,y,300,600);

        canOverride = false;
        doCompile = false;

        var mover:ContainerMover = new ContainerMover();
        super.mover = mover;

        new ContainerCloser(273,5,this);

        var debugLabel:FlxText = new FlxText(70,7,"DEBUG MENU",20);
        debugLabel.font = "vcr";
        debugLabel.antialiasing = true;
        debugLabel.scrollFactor.set();
        add(debugLabel);

        var drawdebug:Checkbox = new Checkbox(10,45,"Draw Debug",drawDebug);
        drawdebug.checked = ClientPreferences.drawDebug;
        add(drawdebug);

        paused = new Checkbox(10,80,"Game Paused",setPaused);
        paused.checked = Main.Paused;
        add(paused);

        Main.onPauseGame.add(updatePaused);
        Main.onUnpauseGame.add(updatePaused);
        
        var debugcam:Checkbox = new Checkbox(10,125,"Debug camera controls",debugCamera);
        debugcam.checked = debugCamControls;
        add(debugcam);

        debugCamIndicator = new FlxSprite(260,125,"embed/ui/checkbox.png");
        debugCamIndicator.antialiasing = true;
        debugCamIndicator.color = FlxColor.BLACK;
        add(debugCamIndicator);

        add(Utils.makeRamFriendlyRect(10,115,280,2,0xAD646464));

        var resetdebugcam = new Button(15, 160, 80, 20, "Reset cam", resetDebugCamera);
        add(resetdebugcam);

        debugCamLabel = new FlxText(100,160,0,"",16);
        debugCamLabel.font = "vcr";
        debugCamLabel.antialiasing = true;
        debugCamLabel.visible = true;
        add(debugCamLabel);

        add(Utils.makeRamFriendlyRect(10,197,280,2,0xAD646464));

        var loadLevel = new Button(10,210,100,25,"Open Level",loadLevel);
        add(loadLevel);

        var measurerTool:CustomButton = new CustomButton(250, 205, 36, 36, toggleMeasuringTool);
        add(measurerTool);

        measuringToolSprite = new FlxSprite(3,3,"embed/debug/quill.png");
        measuringToolSprite.setGraphicSize(30,30);
        measuringToolSprite.updateHitbox();

        measuringToolSprite.color = 0xFF818181;

        measurerTool.content.push(measuringToolSprite);

        var test2:TextField = new TextField(10,240, 150);
        add(test2);

        var test3:ScrollBar = new ScrollBar(10,320,160,22,HORIZONTAL);
        add(test3);
        test3.invertValue = true;

        debugScrollValue1 = new FlxText(10,350,0,Std.string(test3.value),16);
        debugScrollValue1.font = "vcr";
        debugScrollValue1.antialiasing = true;
        debugScrollValue1.visible = true;
        add(debugScrollValue1);

        test3.onScroll = scrollbar1;

        var test4:ScrollBar = new ScrollBar(200,320,22,160,VERTICAL);
        add(test4);

        test5 = new SelectableList(60,350,["Choice1","Choice2","Choice3"], 100);
        add(test5);

        

        debugCam = FlxG.camera;
        lastZoom = debugCam.zoom;
    }

    function scrollbar1(f:Float) {
        debugScrollValue1.text = Std.string(f);
    }
    
    var lastRegX:Float = 0;
    var lastRegY:Float = 0;
    var lastRegZoom:Float = 0;

    override function update(elapsed:Float) {
        super.update(elapsed);

        if(debugCam != null && !debugCam.exists) debugCam = null;

        debugCamIndicator.color = debugCamControls ? FlxColor.RED : FlxColor.BLACK;
        if(debugCam != null){
            if(debugCamControls && FlxG.keys.pressed.ALT){
                debugCamIndicator.color = FlxColor.YELLOW;
                if(FlxG.mouse.pressedMiddle) {
                    debugCam.scroll.x -= FlxGamePlus.mouseMove[0];
                    debugCam.scroll.y -= FlxGamePlus.mouseMove[1];
                    debugCamIndicator.color = FlxColor.LIME;
                }
                else if (FlxG.mouse.wheel != 0) {
                    debugCam.zoom -= (FlxG.mouse.wheel * 0.005);
                    debugCamIndicator.color = FlxColor.LIME;
                }
                
            }
            
            if(debugCam.scroll.x != lastRegX || debugCam.scroll.y != lastRegY || debugCam.zoom != lastRegZoom)
            { 
                lastRegX = debugCam.scroll.x;
                lastRegY = debugCam.scroll.y;
                lastRegZoom = debugCam.zoom;
                debugCamLabel.text = "(X: "+debugCam.scroll.x+" |Y: "+debugCam.scroll.y+")"+"\nZOOM: "+(-debugCam.zoom);//idk why its negative??
            }
        }
    }

    var brace = false;
    function updatePaused() {
        if(brace) {brace = false; return;}
        paused.checked = Main.Paused;
    }

    function setPaused(to:Bool) {
        brace = true;
        Main.Paused = to;
    }

    function drawDebug(to:Bool) {
        ClientPreferences.drawDebug = to;
    }

    function debugCamera(to:Bool) {
        debugCam = FlxG.camera;
        if(to){ lastX = debugCam.scroll.x; lastY = debugCam.scroll.y; lastZoom = debugCam.zoom; }
        debugCamControls = to;
    }

    function resetDebugCamera() {
        if(debugCam == null) return;
        
        debugCam.scroll.set(lastX,lastY);
        debugCam.zoom = lastZoom;
    }

    function test() {
        trace(test);
        test5.removeChoice("Choice3");
    }

    var measuringTool:MeasuringTool = null;
    function toggleMeasuringTool() {
        if(measuringTool != null){
            //destroy it
            FlxG.state.remove(measuringTool,true);
            measuringTool.destroy();
            measuringTool = null;
            measuringToolSprite.color = 0xFF818181;
        }
        else {
            //create it
            measuringTool = new MeasuringTool(FlxG.camera.scroll.x+(FlxG.width*0.5),FlxG.camera.scroll.y+(FlxG.height*0.5));
            FlxG.state.add(measuringTool);
            measuringToolSprite.color = 0xFFFFFFFF;
        }
    }

    function loadLevel() {
        FileBrowser.callback = loadLevelSelect;
        FileBrowser.browse([new FileFilter("Map files", "*.map")], false);
    }

    function loadLevelSelect() {
        switch (FileBrowser.latestResult){
            case SAVE, CANCEL, ERROR: return;
            case SELECT: if(MainState.instance != null) MainState.instance.level.loadLevel(FileBrowser.filePath); 
        }
    }
}