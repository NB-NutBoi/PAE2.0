package ui.premades;

import haxe.Json;
import gameside.inventory.Item.ItemJson;
import openfl.net.FileFilter;
import lowlevel.FileBrowser;
import utility.Language;
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
    var itemLang:String;
    //description uses "itemLang_Description" and name uses "itemLang_Name", that way only one lang needs to be saved, and it can be changed easily.

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

        var texW:TextField;
        var texH:TextField;

        var texX:TextField;
        var texY:TextField;
        //--------------------------------------------------------


    var lang:TextField;

    var maxQuant:TextField;
    var quantSafeIndicator:FlxSprite;
    var defAmmount:TextField;
    var ammountSafeIndicator:FlxSprite;

    var itemW:TextField;
    var itemH:TextField;
    var itemSizeSafeIndicator:FlxSprite;

    //--------------------------------------------------------

    var saveButton:Button;
    var loadButton:Button;
    var newButton:Button;

    override public function new(x:Float, y:Float) {
        super(x, y, 1000, 650);

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
        itemName = new FlxText(300,10,280,"Unnamed Item",20);
        itemName.setFormat("vcr",20,FlxColor.WHITE,CENTER);
        itemName.antialiasing = true;
        add(itemName);

        var sepparator = Utils.makeRamFriendlyRect(300,33,280,2);
        add(sepparator);

        itemDescription = new FlxText(300,42,280,"Description",16);
        itemDescription.setFormat("vcr",16,FlxColor.WHITE,CENTER);
        itemDescription.antialiasing = true;
        add(itemDescription);

        grid = new FlxSprite(340, 120, "embed/ui/inventoryBox.png");
        grid.antialiasing = false;
        grid.setGraphicSize(124, 124);
        grid.updateHitbox();
        grid.camera = cam;

        itemTexture = new Sprite(340,120,null);

        var label:FlxText = new FlxText(430,95,0,"Grid visualizer",17); label.font = "vcr"; add(label);

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

        label = new FlxText(175,120,0,"Texture",17); label.font = "vcr"; add(label);

        sepparator = Utils.makeRamFriendlyRect(132,140,180,2); add(sepparator); 

        texturePath = new TextField(175,150,150);
        add(texturePath);

        texturePath.onPressEnter.add(applyTexture_field);

        nick = new TextField(135,85,170);
        add(nick);

        nick.onPressEnter.add(applyNick);

        var selectButton = new Button(132,150,20,20,"...",browseTexture);
        add(selectButton);

        var setButton = new Button(132,175,20,20,"set",applyTexture);
        add(setButton);

        label = new FlxText(135,220,0,"Texture Properties",17); label.font = "vcr"; add(label);

        sepparator = Utils.makeRamFriendlyRect(132,240,180,2); add(sepparator); 
        

        label = new FlxText(135,245,0,"W",17); label.font = "vcr"; add(label);

        texW = new TextField(155,245,60);
        add(texW);

        texW.onPressEnter.add(enterWHValues);

        label = new FlxText(230,245,0,"H",17); label.font = "vcr"; add(label);

        texH = new TextField(250,245,60);
        add(texH);

        texH.onPressEnter.add(enterWHValues);

        label = new FlxText(135,280,0,"X",17); label.font = "vcr"; add(label);

        texX = new TextField(155,280,60);
        add(texX);
        texX.onPressEnter.add(enterXYValuesTex);

        label = new FlxText(230,280,0,"Y",17); label.font = "vcr"; add(label);

        texY = new TextField(250,280,60);
        add(texY);

        texY.onPressEnter.add(enterXYValuesTex);

        //item properties----------------------------------------------------------------------

        sepparator = Utils.makeRamFriendlyRect(132,405,180,2); add(sepparator);

        label = new FlxText(135,385,0,"Item properties",17); label.font = "vcr"; add(label);
        label = new FlxText(132,420,0,"Lang",17); label.font = "vcr"; add(label);

        lang = new TextField(180,420,120);
        add(lang);

        lang.onPressEnter.add(applyLang);

        label = new FlxText(135,455,0,"Item Size",17); label.font = "vcr"; add(label);
        label = new FlxText(135,480,0,"W",17); label.font = "vcr"; add(label);

        itemW = new TextField(155,480,60);
        add(itemW);

        label = new FlxText(230,480,0,"H",17); label.font = "vcr"; add(label);

        itemH = new TextField(250,480,60);
        add(itemH);

        itemSizeSafeIndicator = new FlxSprite(270,452,"embed/ui/tick.png");
        itemSizeSafeIndicator.color = FlxColor.GREEN;
        add(itemSizeSafeIndicator);

        itemW.onType.add(onType_indicator1);
        itemH.onType.add(onType_indicator1);
        itemW.onPressEnter.add(enterItemSizeValues);
        itemH.onPressEnter.add(enterItemSizeValues);

        sepparator = Utils.makeRamFriendlyRect(128,510,180,2); add(sepparator);

        label = new FlxText(130,516,0,"Max\nQuantity",17); label.font = "vcr"; add(label);

        maxQuant = new TextField(260,520,50);
        add(maxQuant);

        quantSafeIndicator = new FlxSprite(220,520,"embed/ui/tick.png");
        quantSafeIndicator.color = FlxColor.GREEN;
        add(quantSafeIndicator);

        maxQuant.onType.add(onType_indicator2);
        maxQuant.onPressEnter.add(enterMaxQuant);

        sepparator = Utils.makeRamFriendlyRect(128,550,180,2); add(sepparator);

        label = new FlxText(130,556,0,"Default\nAmmount",17); label.font = "vcr"; add(label);

        defAmmount = new TextField(260,560,50);
        add(defAmmount);

        ammountSafeIndicator = new FlxSprite(220,560,"embed/ui/tick.png");
        ammountSafeIndicator.color = FlxColor.GREEN;
        add(ammountSafeIndicator);

        defAmmount.onType.add(onType_indicator3);
        defAmmount.onPressEnter.add(enterItemAmmount);

        //---------------------------------------------------------------------------------------------------------

        saveButton = new Button(600,20,100,40,"Save",save);
        add(saveButton);

        loadButton = new Button(710,20,100,40,"Load",load);
        add(loadButton);

        newButton = new Button(820,20,100,40,"New",setupNewItem);
        add(newButton);

        add(itemTexture);

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

        textureList.setChoices(["default"]);
        
        itemTextures = [];
        curItemTexture = 0;

        itemTextures.push({
            nick: "default",
            index: 0,
            path: "embed/ui/default_item.asset",
            width: 124,
            height: 124,
            xOffset: 0,
            yOffset: 0
        });

        itemLang = "";
        itemWidth = 1;

        itemW.textField.text = "1";
        itemW.caret = 1;
        itemW.onUpdateText();
        lastValidItemW = "1";

        itemHeight = 1;

        itemH.textField.text = "1";
        itemH.caret = 1;
        itemH.onUpdateText();
        lastValidItemH = "1";

        maxQuantity = 1;

        maxQuant.textField.text = "1";
        maxQuant.caret = 1;
        maxQuant.onUpdateText();
        lastValidQuant = "1";

        defaultAmmount = 1;

        defAmmount.textField.text = "1";
        defAmmount.caret = 1;
        defAmmount.onUpdateText();
        lastValidAmmount = "1";

        onSelectTextureFromList(curItemTexture);
    }

    public function setTexture(t:Int) {
        if(itemTextures[t] == null) return;
        final texture = itemTextures[t];
        itemTexture.setAsset(ImageAsset.get(texture.path));
        itemTexture.setGraphicSize(texture.width, texture.height);
        itemTexture.updateHitbox();
        itemTexture.offset.subtract(texture.xOffset, texture.yOffset);
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
        FileBrowser.callback = _fileBrowsed;
        FileBrowser.browse([new FileFilter("Asset files", "*.asset")], false);
    }

    function _fileBrowsed() {
        switch (FileBrowser.latestResult){
            case SAVE, CANCEL, ERROR: return;
            case SELECT:
                texturePath.textField.text = FileBrowser.filePath;
                texturePath.caret = FileBrowser.filePath.length;
                texturePath.onUpdateText();

                applyTexture();
        }
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
        curItemTexture = i;
        var texIdx = getTextureIdxFromSelected(i);
        var tex = itemTextures[texIdx];

        texturePath.textField.text = tex.path;
        texturePath.caret = tex.path.length;
        texturePath.onUpdateText();

        nick.textField.text = tex.nick;
        nick.caret = tex.nick.length;
        nick.onUpdateText();

        texW.textField.text = Std.string(tex.width);
        texW.caret = Std.string(tex.width).length;
        texW.onUpdateText();

        texH.textField.text = Std.string(tex.height);
        texH.caret = Std.string(tex.height).length;
        texH.onUpdateText();

        lastValidW = Std.string(tex.width);
        lastValidH = Std.string(tex.height);

        texX.textField.text = Std.string(tex.xOffset);
        texX.caret = Std.string(tex.xOffset).length;
        texX.onUpdateText();

        texY.textField.text = Std.string(tex.yOffset);
        texY.caret = Std.string(tex.yOffset).length;
        texY.onUpdateText();

        lastValidTexX = Std.string(tex.xOffset);
        lastValidTexY = Std.string(tex.yOffset);

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
            if(value < 1){ //cannot be less than 1
                gridWField.textField.text = lastValidX;
            }
            else{
                lastValidX = Std.string(value);
                gridW = value;
            }
        }
        else{
            gridWField.textField.text = lastValidX;
        }

        //check h
        if(Std.parseInt(gridHField.textField.text) != null){
            var value = Std.parseInt(gridHField.textField.text);
            if(value < 1){ //cannot be less than 1
                gridHField.textField.text = lastValidY;
            }
            else{
                lastValidY = Std.string(value);
                gridH = value;
            }
        }
        else{
            gridHField.textField.text = lastValidY;
        }
    }

    var lastValidW:String;
    var lastValidH:String;
    public function enterWHValues(_) {
        var texIdx = getTextureIdxFromSelected(textureList.selected);
        var tex = itemTextures[texIdx];

        //check w
        if(Std.parseInt(texW.textField.text) != null){
            var value = Std.parseInt(texW.textField.text);
            if(value < 1){ //cannot be less than 1
                texW.textField.text = lastValidW;
            }
            else{
                lastValidW = Std.string(value);
                tex.width = value;
            }
        }
        else{
            texW.textField.text = lastValidW;
        }

        //check h
        if(Std.parseInt(texH.textField.text) != null){
            var value = Std.parseInt(texH.textField.text);
            if(value < 1){ //cannot be less than 1
                texH.textField.text = lastValidH;
            }
            else{
                lastValidH = Std.string(value);
                tex.height = value;
            }
        }
        else{
            texH.textField.text = lastValidH;
        }

        itemTexture.setGraphicSize(tex.width,tex.height);
        itemTexture.updateHitbox();
        itemTexture.offset.subtract(tex.xOffset, tex.yOffset);
    }

    var lastValidTexX:String;
    var lastValidTexY:String;
    public function enterXYValuesTex(_) {
        var texIdx = getTextureIdxFromSelected(textureList.selected);
        var tex = itemTextures[texIdx];

        //check x
        if(!Math.isNaN(Std.parseFloat(texX.textField.text))){
            var value = Std.parseFloat(texX.textField.text);

            lastValidTexX = Std.string(value);
            tex.xOffset = value;
        }
        else{
            texX.textField.text = lastValidX;
        }

        //check y
        if(!Math.isNaN(Std.parseFloat(texY.textField.text))){
            var value = Std.parseFloat(texY.textField.text);

            lastValidTexY = Std.string(value);
            tex.yOffset = value;
        }
        else{
            texY.textField.text = lastValidY;
        }

        itemTexture.updateHitbox();
        itemTexture.offset.subtract(tex.xOffset, tex.yOffset);
    }

    //-------------------------------------------------------------------------------------------------------------------
    //-------------------------------------------------------------------------------------------------------------------
    //-------------------------------------------------------------------------------------------------------------------

    public function applyLang(_:String) {
        if(_ == ""){
            itemName.text = "Unnamed Item";
            itemDescription.text = "Description";

            itemLang = "";
            return;
        }

        itemLang = _;

        itemName.text = LanguageManager.getText(_+"_Name");
        itemDescription.text = LanguageManager.getText(_+"_Description");
    }

    public function onType_indicator1() {
        itemSizeSafeIndicator.color = FlxColor.RED;
    }

    var lastValidItemW:String;
    var lastValidItemH:String;
    public function enterItemSizeValues(_) {
        //check w
        if(Std.parseInt(itemW.textField.text) != null){
            var value = Std.parseInt(itemW.textField.text);
            if(value < 1){ //cannot be less than 1 (item has to take at least 1 slot for technical (and logical) reasons.)
                itemW.textField.text = lastValidItemW;
            }
            else{
                lastValidItemW = Std.string(value);
                itemWidth = value;
            }
        }
        else{
            itemW.textField.text = lastValidItemW;
        }

        //check h
        if(Std.parseInt(itemH.textField.text) != null){
            var value = Std.parseInt(itemH.textField.text);
            if(value < 1){ //cannot be less than 1 (item has to take at least 1 slot for technical (and logical) reasons.)
                itemH.textField.text = lastValidItemH;
            }
            else{
                lastValidItemH = Std.string(value);
                itemHeight = value;
            }
        }
        else{
            itemH.textField.text = lastValidItemH;
        }

        itemSizeSafeIndicator.color = FlxColor.GREEN;
    }

    public function onType_indicator2() {
        quantSafeIndicator.color = FlxColor.RED;
    }

    public function onType_indicator3() {
        ammountSafeIndicator.color = FlxColor.RED;
    }

    var lastValidAmmount:String;
    public function enterItemAmmount(_) {
        var texIdx = getTextureIdxFromSelected(textureList.selected);
        var tex = itemTextures[texIdx];

        //check ammount
        if(!Math.isNaN(Std.parseFloat(defAmmount.textField.text))){
            var value = Std.parseFloat(defAmmount.textField.text);

            lastValidAmmount = Std.string(value);
            defaultAmmount = value;
        }
        else{
            defAmmount.textField.text = lastValidAmmount;
        }

        ammountSafeIndicator.color = FlxColor.GREEN;
    }

    var lastValidQuant:String;
    public function enterMaxQuant(_) {
        //check quantity
        if(Std.parseInt(maxQuant.textField.text) != null){
            var value = Std.parseInt(maxQuant.textField.text);
            if(value < 1){ //cannot be less than 1 (you cant hold 0 of this item while having it in your inventory bruhbruhbruh)
                maxQuant.textField.text = lastValidQuant;
            }
            else{
                lastValidQuant = Std.string(value);
                maxQuantity = value;
            }
        }
        else{
            maxQuant.textField.text = lastValidQuant;
        }

        quantSafeIndicator.color = FlxColor.GREEN;
    }

    //-------------------------------------------------------------------------------------------------------------------
    //-------------------------------------------------------------------------------------------------------------------
    //-------------------------------------------------------------------------------------------------------------------

    public function save() {
        var json:ItemJson = {
            maxQuantity: maxQuantity,
            defaultAmmount: defaultAmmount,
            langId: itemLang,
            textures: itemTextures,
            curTexture: curItemTexture,
            iWidth: itemWidth,
            iHeight: itemHeight
        }

        var c = Json.stringify(json,null," ");
        FileBrowser.save(c, "item.item");
    }

    public function load() {
        FileBrowser.callback = loadSelect;
        FileBrowser.browse([new FileFilter("ItemFiles", "*.item")], true);
    }

    function loadSelect() {
        switch (FileBrowser.latestResult){
            case SAVE, CANCEL, ERROR: return;
            case SELECT:
                var jsonSelect:ItemJson = cast Json.parse(FileBrowser.fileData);

                
                itemTextures = jsonSelect.textures;
                textureList.setChoices([itemTextures[0].nick]);

                for (i in 1...itemTextures.length) {
                    textureList.addChoice(itemTextures[i].nick);
                }

                curItemTexture = jsonSelect.curTexture;
                textureList.selected = curItemTexture;

                itemLang = jsonSelect.langId;
                applyLang(itemLang);

                itemWidth = jsonSelect.iWidth;

                itemW.textField.text = Std.string(itemWidth);
                itemW.caret = itemW.textField.text.length;
                itemW.onUpdateText();
                lastValidItemW = itemW.textField.text;

                itemHeight = jsonSelect.iHeight;

                itemH.textField.text = Std.string(itemHeight);
                itemH.caret = itemH.textField.text.length;
                itemH.onUpdateText();
                lastValidItemH = itemH.textField.text;

                maxQuantity = jsonSelect.maxQuantity;

                maxQuant.textField.text = Std.string(maxQuantity);
                maxQuant.caret = maxQuant.textField.text.length;
                maxQuant.onUpdateText();
                lastValidQuant = maxQuant.textField.text;

                defaultAmmount = jsonSelect.defaultAmmount;

                defAmmount.textField.text = Std.string(defaultAmmount);
                defAmmount.caret = defAmmount.textField.text.length;
                defAmmount.onUpdateText();
                lastValidAmmount = defAmmount.textField.text;

                onSelectTextureFromList(curItemTexture);
        }
    }

}