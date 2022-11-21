package ui.premades;

import flixel.util.FlxColor;
import ui.elements.Button;
import utility.Utils;
import ui.elements.SelectableList;
import ui.elements.TextField;
import assets.AssetCache;
import assets.ImageAsset;
import rendering.Sprite;
import flixel.FlxSprite;
import flixel.text.FlxText;
import ui.elements.ContainerCloser;
import ui.elements.ContainerMover;

typedef ItemTexture = {
    public var nick:String;
    public var index:Int;
    public var path:String;
    public var width:Int;
    public var height:Int;
    public var xOffset:Float;
    public var yOffset:Float;
}

class ItemEditor extends DMenu{
    
    var itemName:FlxText;
    var itemDescription:FlxText;
    var itemNameLang:String;
    var itemDescLang:String;

    var grid:FlxSprite;
    var gridW:Int = 1;
    var gridH:Int = 1;

    var itemTexture:Sprite;
    var itemTextures:Array<ItemTexture>;
    var curItemTexture:Int;

    var itemWidth:Int;
    var itemHeight:Int;

    var maxQuantity:Int;
    var defaultAmmount:Float;

    //--------------------------------------------------------

    var gridWField:TextField;
    var gridHField:TextField;

    var textureList:SelectableList;
        //--------------------------------------------------------

        var texturePath:TextField;
        var nick:TextField;

    override public function new(x:Float, y:Float) {
        super(x, y, 600, 600);

        canOverride = false;
        doCompile = false;

        var mover:ContainerMover = new ContainerMover();
        super.mover = mover;

        new ContainerCloser(273,5,this);

        var itemLabel:FlxText = new FlxText(70,7,"ITEM EDITOR",20);
        itemLabel.font = "vcr";
        itemLabel.antialiasing = true;
        itemLabel.scrollFactor.set();
        add(itemLabel);


        //-----------------------------------------------------
        itemName = new FlxText(320,10,0,"Unnamed Item",20);
        itemName.setFormat("vcr",20,FlxColor.WHITE,CENTER);
        itemName.antialiasing = true;
        add(itemName);

        var sepparator = Utils.makeRamFriendlyRect(300,33,280,2);
        add(sepparator);

        itemDescription = new FlxText(320,40,0,"Description",20);
        itemDescription.setFormat("vcr",20,FlxColor.WHITE,CENTER);
        itemDescription.antialiasing = true;
        add(itemDescription);

        grid = new FlxSprite(340, 120, "embed/ui/inventoryBox.png");
        grid.antialiasing = false;
        grid.setGraphicSize(124, 124);
        grid.updateHitbox();
        grid.camera = cam;

        itemTexture = new Sprite(340,120,null);
        add(itemTexture);

        gridWField = new TextField(340,90,30);
        gridHField = new TextField(385,90,30);
        add(gridWField);
        add(gridHField);

        gridWField.textField.text = "1";
        gridHField.textField.text = "1";

        gridWField.onPressEnter.add(enterValues);
        gridHField.onPressEnter.add(enterValues);

        textureList = new SelectableList(20,100,["default"],100);
        add(textureList);

        textureList.onSelect = onSelectTextureFromList;

        var addButton = new Button(25,67,30,30,"+",addTexture);
        add(addButton);
        var removeButton = new Button(75,67,30,30,"-",removeTexture);
        add(removeButton);

        var bgRect = Utils.makeRamFriendlyRect(130,80,200,300, 0xFF161616); add(bgRect);

        //texturedef rect----------------------------------------------------------------------

        texturePath = new TextField(175,120,150);
        add(texturePath);

        texturePath.onPressEnter.add(applyTexture_field);

        nick = new TextField(135,85,170);
        add(nick);

        nick.onPressEnter.add(applyNick);

        var selectButton = new Button(132,120,20,20,"...",browseTexture);
        add(selectButton);

        var setButton = new Button(132,145,20,20,"set",applyTexture);
        add(setButton);

        setupNewItem();
    }

    override function draw() {
        bg.draw();

        for (x in 0...gridW) {
            for (y in 0...gridH) {
                grid.x = 340 + (124*x);
                grid.y = 120 + (124*y);
                grid.draw();
            }
        }

        if(mover != null)
            mover.draw();
        if(closer != null)
            closer.draw();
        stuffs.draw();
    }

    public function setupNewItem() {
        
        itemTextures = [];
        curItemTexture = 0;
        itemWidth = 1;
        itemHeight = 1;

        maxQuantity = 1;
        defaultAmmount = 0;

        itemTextures.push({
            nick: "default",
            index: 0,
            path: "embed/ui/default_item.asset",
            width: 124,
            height: 124,
            xOffset: 0,
            yOffset: 0
        });

        onSelectTextureFromList(curItemTexture);
    }

    public function setTexture(t:Int) {
        if(itemTextures[t] == null) return;
        final texture = itemTextures[t];
        itemTexture.setAsset(ImageAsset.get(texture.path));
        itemTexture.setGraphicSize(texture.width, texture.height);
        itemTexture.updateHitbox();
        itemTexture.offset.add(texture.xOffset, texture.yOffset);
    }

    public function addTexture() {
        itemTextures.push({
            nick: "unnamed",
            index: textureList.addChoice("unnamed"),
            path: "embed/ui/default_item.asset",
            width: 124,
            height: 124,
            xOffset: 0,
            yOffset: 0
        });
    }

    public function removeTexture() {
        var idx = textureList.selected;
        if(idx == 0) return;
        var listIdx = 0;
        for (tex in itemTextures) {
            if(tex.index < idx) continue;
            if(tex.index == idx) { listIdx = itemTextures.indexOf(tex); continue; }
            tex.index--;
        }

        itemTextures.remove(itemTextures[listIdx]);
    }

    public function browseTexture() {
        
    }

    public function applyTexture() {
        var texIdx = getTextureIdxFromSelected(textureList.selected);
        var tex = itemTextures[texIdx];

        tex.path = texturePath.textField.text;

        setTexture(texIdx);
    }

    public function applyTexture_field(_) {
        applyTexture();
    }

    public function applyNick(_:String) {
        var texIdx = getTextureIdxFromSelected(textureList.selected);
        var tex = itemTextures[texIdx];

        tex.nick = _;

        textureList.choices.members[textureList.selected].text = _;
    }

    public function getTextureIdxFromSelected(sel:Int):Int {
        for (i in 0...itemTextures.length) {
            if(itemTextures[i].index == sel) return i;
        }
        
        return 0;
    }

    public function onSelectTextureFromList(i:Int) {
        var texIdx = getTextureIdxFromSelected(i);
        var tex = itemTextures[texIdx];

        texturePath.textField.text = tex.path;
        texturePath.caret = tex.path.length;
        texturePath.onUpdateText();

        nick.textField.text = tex.nick;
        nick.caret = tex.nick.length;
        nick.onUpdateText();

        applyTexture();
    }

    //-------------------------------------------------------------------------------------------------------------------
    //-------------------------------------------------------------------------------------------------------------------
    //-------------------------------------------------------------------------------------------------------------------

    var lastValidX:String;
    var lastValidY:String;
    public function enterValues(_) {
        //check w
        if(Std.parseInt(gridWField.textField.text) != null){
            var value = Std.parseInt(gridWField.textField.text);
            if(value < 1){
                gridWField.textField.text = lastValidX;
            }
            else{
                lastValidX = Std.string(value);
                gridW = value;
            }
        }

        //check h
        if(Std.parseInt(gridHField.textField.text) != null){
            var value = Std.parseInt(gridHField.textField.text);
            if(value < 1){
                gridHField.textField.text = lastValidY;
            }
            else{
                lastValidY = Std.string(value);
                gridH = value;
            }
        }
    }

}