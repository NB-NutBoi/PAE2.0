package lowlevel;

class OverrideableEvent {
    
    var event:Dynamic;

    public function new(x:Dynamic) {
        event = x;
    }

    public function execute(?args:Array<Dynamic> = null) {
        if(args == null) args = [];
        Reflect.callMethod(this, event, args);
    }
}