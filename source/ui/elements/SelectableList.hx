package ui.elements;

import ui.elements.ColorPicker.ColorWheel;
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

    public var box:FlxSprite;
    var selectorBox:FlxSprite;
    var selectedBox:FlxSprite;

    public var choices:FlxTypedGroup<FlxText> = new FlxTypedGroup();

    public var selected:Int = 0;
    public var over:Bool = false;
    var hovering:Int = 0;

    public var isExtended:Bool = false;

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
        selectedBox.x = box.x;

        over = false;
    }

	public function updateInputs(elapsed:Float) {
        if(ColorWheel.instance != null) return;
        if(Container.contextActive) return;
        if(Container.dropdownActive && !isExtended) return;
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
            selectorBox.x = box.x;
        }
    }

    override function draw() {
        super.draw();

        box.draw();
        if(over) selectorBox.draw();
        if(choices.length > 0) selectedBox.draw();
        choices.draw();
    }

    override function setScrollFactor(x:Float = 0, y:Float = 0) {
        super.setScrollFactor(x, y);
        box.scrollFactor.set(x,y);
        selectorBox.scrollFactor.set(x,y);
        selectedBox.scrollFactor.set(x,y);
        for (text in choices) {
            text.scrollFactor.set(x,y);
        }
    }

    override function setPosition(X:Float = 0, Y:Float = 0) {
		box.x = X;
		box.y = Y;
        selectedBox.y = box.y + (21*selected);
        selectedBox.x = box.x;
        selectorBox.y = box.y + (21*hovering);
        selectorBox.x = box.x;
        for (i in 0...choices.length) {
            choices.members[i].setPosition(box.x+1, box.y + (21*i));
        }
		super.setPosition(X, Y);
	}

    //-------------------------------------------------------------------------------------------------------

    public function addChoice(s:String):Int {
        var t = new FlxText(box.x+1, box.y + (21*choices.length),box.width-4,s,15);
        t.font = "vcr";
        t.alignment = CENTER;
        t.scrollFactor.set().addPoint(scrollFactor);
        choices.add(t);
        box.setGraphicSize(Std.int(box.width),21*choices.length);
        box.updateHitbox();

        height = combinedHeight = box.height;

        return choices.length-1;
    }

    public function removeChoice(s:String, ?nocallback:Bool = false) {
        var i = 0;
        while (i < choices.members.length) {
            if(choices.members[i] == null) { choices.remove(choices.members[i], true); i--; }
            else if(choices.members[i].text == s){
                if(i >= selected){
                    selected = 0;
                    if(onSelect != null && !nocallback) onSelect(selected);
                }

                choices.members[i].destroy();
                choices.remove(choices.members[i], true);
                box.setGraphicSize(Std.int(box.width),21*choices.length);
                box.updateHitbox();

                break;
            }

            i++;
        }

        height = combinedHeight = box.height;
    }

    public function setChoices(newChoices:Array<String>) {
        if(newChoices.length < 1) newChoices = ["default"];

        choices.members[0].text = newChoices[0];

        if(choices.length > 1){
            while (1 < choices.length) {
                removeChoice(choices.members[1].text,true);
            }

            for (i in 1...newChoices.length) {
                addChoice(newChoices[i]);
            }
        }

        if(choices.length <= selected){
            selected = 0;
            if(onSelect != null) onSelect(selected);
        }
    }

    public function getChoiceName(i:Int):String {
        if(choices.members[i] == null) return "";
        return choices.members[i].text;
    }

    public function setChoice(s:String):Int {
        if(!choiceExists(s)) return selected;
        var i = 0;
        while (i < choices.members.length) {
            if(choices.members[i] == null) { choices.remove(choices.members[i], true); i--; }
            else if(choices.members[i].text == s){
                selected = i;
                break;
            }
            i++;
        }

        return i;
    }
    
    public function choiceExists(s:String):Bool {
        var i = 0;
        while (i < choices.members.length) {
            if(choices.members[i] == null) { choices.remove(choices.members[i], true); i--; }
            else if(choices.members[i].text == s){
                return true;
            }
            i++;
        }

        return false;
    }

}