import ("flixel.text.FlxText", "FlxText");

var testable:FlxText = null;

function OnAwake()
{
	testable = new FlxText(10,10,0,"hi!, this is a test menu!",18);
	testable.font = "vcr";
	
	DMenu.add(testable);
}

function OnUpdate(elapsed:Float)
{

}

function OnUpdateInputs(elapsed:Float)
{

}

function OnPostUpdate(elapsed:Float)
{

}