package;

import oop.Object.FullObjectDataStructure;
import common.ClientPreferences;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import levels.Level;
import rendering.Skybox;
import utility.Utils;

class MainState extends CoreState {
    public static var instance:MainState;

    var grid:FlxSprite;

    public var level:Level;

    override function create() {
        instance = this;
        super.create();

        CoreState.onSave.add(onSave);
        CoreState.onLoad.add(onLoad);

        level = new Level(); //standard level instance
    }

    override function update(elapsed:Float) {
        super.update(elapsed);
        level.update(elapsed);
    }

    override function draw() {
        if(ClientPreferences.drawDebug){
            drawDebug();
        }

        level.draw();

        super.draw();
    }

    function createGrid() {
        grid = new FlxSprite(0,0,"embed/debug/grid.png");
        grid.color = 0x1A1B1B1B;
        grid.antialiasing = true;
    }

    function drawDebug() {

        //GRID
        if(grid == null) createGrid();

        Utils.drawBackground(grid);
    }

    override function destroy() {
        CoreState.onSave.remove(onSave);
        CoreState.onLoad.remove(onLoad);

        level.destroy();

        instance = null;

        super.destroy();
    }

    function onSave(where:String) {
        level.onSave();
    }

    function onLoad(from:String) {
        level.onLoad();
    }

    //DEBUG
    //-----------------------------------------------------------------------------

    function testDebug() {
        level.loadLevel("assets/levels/test/testLevel.map");
    }
}