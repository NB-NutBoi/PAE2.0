package ui.premades;

import flixel.text.FlxText;
import flixel.FlxSprite;
import ui.elements.CustomButton;
import ui.premades.inspector.InspectorComponentNode;
import flixel.FlxG;
import ui.elements.ContainerCloser;
import leveleditor.ObjectVisualizer;
import ui.elements.Button;
import oop.Component;
import ui.base.Container;

class InspectorComponentBrowser extends Container {

    public var opened:Bool = false;
    public var closedThisFrame:Bool = false;
    
    override public function new() {
        super(0,0,250,300);

        new ContainerCloser(223,5,this);
    }


    override function update(elapsed:Float) {
        if(overlapped){
            cam.scroll.y -= FlxG.mouse.wheel * 10;
            if(cam.scroll.y < 0) cam.scroll.y = 0;
        }

        super.update(elapsed);

        x = Inspector.instance.x-250;
        y = (Inspector.instance.y + Inspector.instance.addButton.y + Inspector.instance.cam.scroll.y);
    }


    public function setObject(o:ObjectVisualizer) {
        var i = 0;
        for (cClass in Component.componentClasses) {
            var has = false;
            for (component in o.components) {
                if(component.component == cClass) { has = true; break; }
            }

            if(!has){
                var button = new CustomButton(0,32*i,220,30,function () {
                    Inspector.instance.addComponent(cClass);
                    close();
                });

                var icon = new FlxSprite(5,5,InspectorComponentNode.makeIconFor(cClass));
                icon.setGraphicSize(20,20);
                icon.updateHitbox();
                icon.camera = cam;

                var label = new FlxText(30,2,190,cClass.key,16);
                label.font = "vcr";
                label.antialiasing = true;
                label.camera = cam;

                button.content.push(icon);
                button.content.push(label);

                i++;

                button.destroyContent = true;

                add(button);
            }
        }
    }

    override function close() {

        var i = stuffs.length;
        while (i-- > 0) {
            stuffs.members[i].destroy();
            stuffs.remove(stuffs.members[i], true);
        }
        
        opened = false;
        closedThisFrame = true;

        super.close();
    }

}