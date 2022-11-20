package ui.premades;

import rendering.Sprite;
import flixel.FlxSprite;
import flixel.text.FlxText;
import ui.elements.ContainerCloser;
import ui.elements.ContainerMover;

typedef ItemTexture = {
    public var nick:String;
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

    override public function new(x:Float, y:Float) {
        super(x, y, 300, 600);

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
    }

}