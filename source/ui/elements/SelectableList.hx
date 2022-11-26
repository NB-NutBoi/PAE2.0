package ui.elements;

import common.Mouse;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import ui.base.Container;
import ui.base.ContainerObject;
import utility.Utils;

class SelectableList extends StackableObject implements ContainerObject {
    static final IDLE:Int = 0xFF292929;
    static final HOVER:Int = 0xFF3B3B3B;
    static final SELECTED:Int = 0xFF575757;
	
    public var parent:Null<Container>;

    var box:FlxSprite;
    var selectorBox:FlxSprite;
    var selectedBox:FlxSprite;

    public var choices:FlxTypedGroup<FlxText> = new FlxTypedGroup();

    public var selected:Int = 0;
    public var over:Bool = false;
    var hovering:Int = 0;

    public var onSelect:Int->Void;

    override public function new(x:Float, y:Float, defaultChoices:Array<String>, width:Int) {
        super(x,y);

        if(defaultChoices.length < 1) defaultChoices = ["default"];

        box = Utils.makeRamFriendlyRect(x,y,width,1,IDLE);

        for (s in defaultChoices) {
            addChoice(s);
        }

        selectedBox = Utils.makeRamFriendlyRect(box.x, box.y + (21*selected), width, 21, SELECTED);
        selectorBox = Utils.makeRamFriendlyRect(box.x, box.y + (21*selected), width, 21, HOVER);


        height = combinedHeight = box.height;
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        box.setPosition(x,y);

        for (i in 0...choices.length) {
            choices.members[i].setPosition(box.x+1, box.y + (21*i));
        }

        choices.update(elapsed);

        selectedBox.y = box.y + (21*selected);

        over = false;
    }

	public function updateInputs(elapsed:Float) {
        var localMousePos = FlxPoint.get(0,0);
        localMousePos = Utils.getMousePosInCamera(parent == null ? camera : parent.cam, localMousePos, box);

        over = box.overlapsPoint(localMousePos);

        if(over){
            hovering = Math.floor((localMousePos.y - box.y) / 21);
            if(FlxG.mouse.justPressed){
                selected = hovering;
                if(onSelect != null) onSelect(selected);
            }
        }

        localMousePos.put();
    }

	public function postUpdate(elapsed:Float) {
        if(over){
            Mouse.setAs(BUTTON);
            selectorBox.y = box.y + (21*hovering);
        }
    }

    override function draw() {
        super.draw();

        box.draw();
        if(over) selectorBox.draw();
        if(choices.length > 0) selectedBox.draw();
        choices.draw();
    }

    //-------------------------------------------------------------------------------------------------------

    public function addChoice(s:String):Int {
        var t = new FlxText(box.x+1, box.y + (21*choices.length),box.width-4,s,15);
        t.font = "vcr";
        t.alignment = CENTER;
        choices.add(t);
        box.setGraphicSize(Std.int(box.width),21*choices.length);
        box.updateHitbox();

        height = combinedHeight = box.height;

        return choices.length-1;
    }

    public function removeChoice(s:String) {
        for (i in 0...choices.length) {
            if(choices.members[i].text == s){
                choices.members[i].destroy();
                choices.remove(choices.members[i], true);
                box.setGraphicSize(Std.int(box.width),21*choices.length);
                box.updateHitbox();

                if(i >= selected){
                    selected = 0;
                    if(onSelect != null) onSelect(selected);
                }  
            }
        }

        height = combinedHeight = box.height;
    }

    public function setChoices(choices:Array<String>) {
        if(choices.length < 1) choices = ["default"];

        if(this.choices.length > 1){
            for (i in 1...this.choices.length) {
                removeChoice(this.choices.members[i].text);
            }
        }

        this.choices.members[0].text = choices[0];
        for (i in 1...choices.length) {
            addChoice(choices[i]);
        }
    }

    public function getChoiceName(i:Int):String {
        if(choices.members[i] == null) return "";
        return choices.members[i].text;
    }
    
}