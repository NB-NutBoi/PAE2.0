package leveleditor;

import leveleditor.componentvisualizers.AudioListenerVisualizer;
import leveleditor.componentvisualizers.AudioSourceVisualizer;
import leveleditor.componentvisualizers.TextVisualizer;
import leveleditor.componentvisualizers.SpriteVisualizer;
import oop.Component;
import haxe.DynamicAccess;
import flixel.math.FlxPoint;
import rendering.Sprite;
import flixel.FlxBasic;

class ComponentVisualizer extends FlxBasic {

    public var owner:ObjectVisualizer; //only dynamic objects use components.

    public var variables:Array<Array<Dynamic>>;

    public var component:ComponentClass;

    public var extended:Bool = true; //hierarchy temp data
    public var UPDATE_VARIABLES:Bool = false; //hierarchy temp data

    public function copyJson(json:ComponentInstance) {
        for (field in Reflect.fields(json.startingData)) {
            Component.setArray(field,Reflect.field(json.startingData,field),variables);
        }
    }

    public static function make(type:String, owner:ObjectVisualizer):ComponentVisualizer {
        var component:ComponentVisualizer = null;
        switch (type){
            case "Sprite":
                component = new SpriteVisualizer(Component.componentClasses.get(type),owner);
            case "Text":
                component = new TextVisualizer(Component.componentClasses.get(type),owner);
            case "AudioSource":
                component = new AudioSourceVisualizer(Component.componentClasses.get(type),owner);
            case "AudioListener":
                component = new AudioListenerVisualizer(Component.componentClasses.get(type),owner);
            default:
                component = new ComponentVisualizer(Component.componentClasses.get(type),owner);
        }
         
        owner.components.add(component);
        return component;
    }

    public function clone(toCopy:ComponentVisualizer) {
        for (array in variables) {
            Component.setArray(array[0],array[1],toCopy.variables);
            toCopy.changeVariable(array[0]);
        }
        
        toCopy.extended = extended;
    }

    public function new(type:ComponentClass, parent:ObjectVisualizer) {
        super();

        owner = parent;

        component = type;
        variables = [];

        //----------------------------------------------------------------------------

        for (variable in component.defaultVars) {
            variables.push(variable.copy());
        }
    }

    override function destroy() {
        super.destroy();
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public function changeVariable(key:String) {
        
    }

    public function handleScaling(axis:Int) {
        
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public function onActiveLayerChange(to:Bool) {
        
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public function checkCollides(mousePos:FlxPoint):Bool {
        return false;
    }

}