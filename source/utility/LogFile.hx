package utility;
//------------------------------------------------------------
//------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------|
/* This file is under protection and belongs to the PA: AUN project team.                                  |
 * You may learn from this code and / or modify the source code for redistribution with proper accrediting.|
 * -NUT                                                                                                    |
 *///                                                                                                      |
//---------------------------------------------------------------------------------------------------------|


import flixel.util.typeLimit.OneOfTwo;
import openfl.errors.Error;
import sys.io.File;

using StringTools;

#if USING_DCONSOLE
import pgr.dconsole.DC;
#end


typedef LogMessage = {
	public var message:String;
	public var caller:String;
	public var id:Int;
}

typedef Message = OneOfTwo<Dynamic,LogMessage>;

/**
 * very basic log file functionality, static.
 * 
 * this morphed from readable code to "what the fuck am i looking at"
 * @author NutBoi
 */
@:allow(Main)
class LogFile {
	static var logCallerAndID:Bool = false;

	//----------------------------------------------------------------------------------------------------------------------------------------

    public static function Init() {
		var initContext:String = "PAE ENGINE LOG \n----------------------------\nVersion " + Main.GameVersion + "\n\n";
		if(Main.DEBUG){
			initContext += "DEVELEOPER MODE ACTIVE.\n\n";
		}

		if(true)//TODO
		{
			initContext += "Device info\n----------------------\n\nPLATFORM: "+Utils.getPlatform()+"\nGPU: "+Utils.getSystemGpu()+"\nCPU: "+Utils.getSystemCpu()+"\n  - Threads: "+Utils.getThreads()+"\n\n----------------------\n\n";
		}

		if(Main.buildType == TESTER_BUILD){
			initContext += "Tester build.\nBuildID: "+1+"\n\n\n";
		}
		else{
			initContext += "\n";
		}
		
		File.saveContent("Log.txt", initContext);
    }
	
	//----------------------------------------------------------------------------------------------------------------------------------------

	private static function _flog(message:Message,?Trace:Bool=false) {
		
		if (Type.typeof(message) == TObject){
			var m:LogMessage = cast message;
			
			var s = m.message.replace("[br]", "\n");
			var f = File.append("Log.txt");

			if(logCallerAndID)
				f.writeString("["+m.caller+"]"+" -  :"+m.id+":  "+"->  ");
			
			if(!s.endsWith("\n")) s += "\n";
			f.writeString(s);
			f.close();

			if (Trace)
				trace(s.replace("\n", "[br]"));

			f = null;
			message = null;
		}
		else {
			var message = Std.string(message);
			
			message = message.replace("[br]", "\n");
			var f = File.append("Log.txt");

			if(!message.endsWith("\n")) message += "\n";
			f.writeString(message);
			f.close();

			if (Trace)
				trace(message.replace("\n", "[br]"));

			f = null;
			message = null;
		}
    }

	/**
	 * Logs a message.
	 * @param Message the message
	 * @param Trace if it should be traced to the powershell console
	 */
	public static function log(Message:Message,?Trace:Bool=false) {

		var result = false;
		var test:LogMessage = cast Message;
		if(test.caller != null) result = true;

		test = null;
		
		if (result)
		{
			var m:LogMessage = cast Message;
			m.message = m.message.replace("[br]", "\n");
			Console.log(m.message);
			Message = m;
		}
		else {
			var message = Std.string(Message);

			message.replace("[br]", "\n");
			Console.log(message);
			
			Message = message;
		}
		
		_flog(Message, Trace);
    }

	/**
	 * Produces a warning in the log.
	 * @param Message the warning message
	 * @param Trace if it should be traced to the powershell console
	 */
	public static function warning(Message:Message, ?Trace:Bool = false)
	{
		var result = false;
		var test:LogMessage = cast Message;
		if(test.caller != null) result = true;
		
		test = null;
		
		if (result)
		{
			var m:LogMessage = cast Message;
			m.message = ("WARNING: " + m.message).replace("[br]", "\n");
			Console.logWarning(m.message);
			Message = m;
		}
		else {
			var message = Std.string(Message);
			
			message = ("WARNING: " + message).replace("[br]", "\n");
			Console.logWarning(message);

			Message = message;
		}
		
		_flog(Message, Trace);
	}

	/**
	 * Produces an error in the log.
	 * @param Message the error message
	 * @param Trace if it should be traced to the powershell console
	 */
	public static function error(Message:Message, ?Trace:Bool = false)
	{
		var result = false;
		var test:LogMessage = cast Message;
		if(test.caller != null) result = true;

		test = null;
		
		if (result)
		{
			var m:LogMessage = cast Message;
			m.message = ("ERROR: " + m.message).replace("[br]", "\n");
			Console.logError(m.message);
			Message = m;
		}
		else {
			var message = Std.string(Message);

			message = ("ERROR: " + message).replace("[br]", "\n");
			Console.logError(message);

			Message = message;
		}

		_flog(Message, Trace);
	}

	/**
	 * Produces an error in the log, popup window, and closes the game.
	 * @param Message the error message
	 * @param Trace if it should be traced to the powershell console
	 */
	public static function fatalError(Message:Message, ErrorId:Int = 0, ?Trace:Bool = false)
	{
		var m:String = "";
		var result = false;
		var test:LogMessage = cast Message;
		if(test.caller != null) result = true;

		test = null;
		
		if (result)
		{
			var ms:LogMessage = cast Message;
			ms.id = ErrorId;
			ms.message = ("FATAL ERROR (CODE " + ErrorId + "): " + ms.message).replace("[br]", "\n");
			Message = ms;
			m = ms.message;
		}	
		else
		{
			var Message = Std.string(Message);

			m = ("FATAL ERROR (CODE " + ErrorId + "): " + Message).replace("[br]", "\n");
		}
		
		_flog(Message,Trace);

		//only want the log and processes to wrap up
		Main.PreCloseGame();
		
		throw new Error(m.replace("\n",""), ErrorId);
	}
}