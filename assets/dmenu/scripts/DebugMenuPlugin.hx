import ("flixel.text.FlxText", "FlxText");

var testable:FlxText = null;

function OnAwake()
{
	trace("AWAKEN MY MASTERS!");
	
	testable = new FlxText(10,280,0,"hi!, this is a plugin!",18);
	testable.font = "vcr";
	
	DMenu.add(testable);
	trace("Back to mimir.");
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