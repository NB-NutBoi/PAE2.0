package ui.premades.inspector;

import leveleditor.GenericObjectVisualizer;
import leveleditor.ObjectVisualizer;
import leveleditor.TransformVisualizer;
import openfl.text.TextField;
import ui.base.Container;
import ui.base.ContainerObject;
import ui.elements.StackableObject;

class TransformField extends StackableObject implements ContainerObject {
	public var parent:Null<Container>;

    public var x_field:TextField;
    public var y_field:TextField;
    //public var z_field:TextField; deprecated

    public var angle_field:TextField;

	public function updateInputs(elapsed:Float) {}

	public function postUpdate(elapsed:Float) {}

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public function set(o:GenericObjectVisualizer) {
        
    }
    
}