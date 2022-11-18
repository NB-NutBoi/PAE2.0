if(globals.audioListenerExists == false) requireComponent("AudioListener");
importPackage("Input");

var vertical:Int = 0;
var horizontal:Int = 0;

var speed:Float = 100;

function OnAwake()
{
	Keyboard.onKeyDown.add(OnKeyDown);
	Keyboard.onKeyUp.add(OnKeyUp);
}

function OnUpdate(elapsed:Float)
{
	if(vertical > 1) vertical = 1; if(horizontal > 1) horizontal = 1;
	if(vertical < -1) vertical = -1; if(horizontal < -1) horizontal = -1;
	transform.addPosition(horizontal * (speed*elapsed), vertical * (speed*elapsed));
}

function OnDraw()
{
	
}

function OnDestroy()
{
	Keyboard.onKeyDown.remove(OnKeyDown);
	Keyboard.onKeyUp.remove(OnKeyUp);
}

function OnKeyDown(key:KeyCode){
	if(key == KeyCode.W){
		vertical -= 1;
	}
	
	if(key == KeyCode.S){
		vertical += 1;
	}
	
	if(key == KeyCode.A){
		horizontal -= 1;
	}
	
	if(key == KeyCode.D){
		horizontal += 1;
	}
}

function OnKeyUp(key:KeyCode){
	if(key == KeyCode.W){
		vertical += 1;
	}
	
	if(key == KeyCode.S){
		vertical -= 1;
	}
	
	if(key == KeyCode.A){
		horizontal += 1;
	}
	
	if(key == KeyCode.D){
		horizontal -= 1;
	}
}