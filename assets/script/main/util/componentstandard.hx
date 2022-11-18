//THESE FUNCTIONS WILL GET ADDED TO THE END OF EVERY COMPONENT SCRIPT!
//basic functionality so scripts can get script variables.

//------------------------------------------------------------------------------

function __setComponentValue(name:String, to:Dynamic)
{
	if(!__this.interpreter.locals.exists(name)) return;
	return __this.interpreter.locals.get(name).r = to;
}

function __getComponentValue(name:String):Dynamic
{
	if(!__this.interpreter.locals.exists(name)) return null;
	return __this.interpreter.locals.get(name).r;
}