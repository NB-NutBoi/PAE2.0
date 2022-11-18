package utility;
//------------------------------------------------------------
//------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------|
/* This file is under protection and belongs to the PA: AUN project team.                                  |
 * You may learn from this code and / or modify the source code for redistribution with proper accrediting.|
 * -NUT                                                                                                    |
 *///                                                                                                      |
//---------------------------------------------------------------------------------------------------------|

import flixel.math.FlxMath;
import haxe.Timer;
import lime.app.Application;
import openfl.events.Event;
import openfl.system.System;
import openfl.text.TextField;
import openfl.text.TextFormat;

/**
 * FPS class extension to display memory usage.
 * @author Kirill Poletaev, extended functionality by NutBoi
 */
class FPS_Mem extends TextField
{
	private var times:Array<Float>;

	public var mempeak:String = "";
	public var vmemtotal:String = "";

	private var average:Float = 0;
	private var averages:Array<Float> = [];

	// additions by nutboi
	public var mousePos:String = "";
	public var extraInfo:String = "";

	public function new(inX:Float = 10.0, inY:Float = 10.0, inCol:Int = 0x000000)
	{
		super();
		x = inX;
		y = inY;
		selectable = false;
		defaultTextFormat = new TextFormat("_sans", 12, inCol);
		text = "FPS: ";
		times = [];
		addEventListener(Event.ENTER_FRAME, onEnter);
	}

	var stamp:Float = 0;
	var i:Int = 0;
	var totalMems:Float = 0;
	var now:Float = 0;
	var afElapsed:Float = 0;
	var mem:Float = 0;
	var vmem:Float = 0;

	private function onEnter(_)
	{
		width = Application.current.window.width - x;
		height = Application.current.window.height - y;

		now = Timer.stamp();
		afElapsed = now - stamp;

		stamp = now;
		times.push(now);



		while (times[0] < now - 1)
			times.shift();

		mem = Math.round(System.totalMemory / 1024 / 1024 * 100) / 100;


		vmem = Math.round(stage.context3D.totalGPUMemory / 1024 / 1024 * 100) / 100;
		if(vmem < 0) vmem = (-vmem); //idk why it returns negative sometimes?
		vmemtotal = Std.string(vmem + " MB");

		if (i >= 100)
		{
			i = 0;
			totalMems = 0;
			for (f in averages)
			{
				totalMems += f;
			}

			average = FlxMath.roundDecimal(totalMems / averages.length, 2);
		}
		
		averages[i] = mem;
		i++;

		if (visible)
		{
			text = mousePos
				+ extraInfo
				+ "\nFPS: "
				+ times.length
				+ "\nMEM: "
				+ mem
				+ " MB\nMEM average: "
				+ average
				+ " MB\nMEM peak: "
				+ mempeak
				+ "\nGPU MEM: "
				+ vmemtotal;
		}
	}
}