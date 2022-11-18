package assets;
//------------------------------------------------------------
//------------------------------------------------------------
//---------------------------------------------------------------------------------------------------------|
/* This file is under protection and belongs to the PA: AUN project team.                                  |
 * You may learn from this code and / or modify the source code for redistribution with proper accrediting.|
 * -NUT                                                                                                    |
 *///                                                                                                      |
//---------------------------------------------------------------------------------------------------------|

import sys.FileSystem;
import utility.LogFile;

class AssetPaths
{
	static public function getPath(initalDirectory:String, file:Null<String>, ?xtraLibraries:Null<Array<String>>, ?assetType:Null<Array<String>>):String
	{
		var startingLibrary:String = "";
		if(FileSystem.exists(initalDirectory)){
			if(FileSystem.isDirectory(initalDirectory))
				startingLibrary = initalDirectory;
		}
		
		var completeLibraryData:Array<String>;
		completeLibraryData = recursiveLoop(startingLibrary);
		// trace(completeLibraryData);

		if (xtraLibraries == null)
		{
			for (s in completeLibraryData)
			{
				var p = new haxe.io.Path(s);
				if(file == null){
					if (assetType != null)
					{
						if (assetType.contains(p.ext))
						{
							return s;
						}
					}
					else
					{
						return s;
					}
				}
				else if (p.file == file)
				{
					if (assetType != null)
					{
						if (assetType.contains(p.ext))
						{
							return s;
						}
					}
					else
					{
						return s;
					}
				}
			}
		}
		else
		{
			for (s in completeLibraryData)
			{
				var libs = s.split("/");
				var p = new haxe.io.Path(s);
				if(file == null){
					var matching = 0;
					for (ss in xtraLibraries)
					{
						if (libs.contains(ss))
							matching++;
					}
					if (matching != xtraLibraries.length)
						continue;

					if (assetType != null)
					{
						if (assetType.contains(p.ext))
						{
							return s;
						}
					}
					else
					{
						return s;
					}
				}
				else if (p.file == file)
				{
					var matching = 0;
					for (ss in xtraLibraries)
					{
						if (libs.contains(ss))
							matching++;
					}
					if (matching != xtraLibraries.length)
						continue;

					if (assetType != null)
					{
						if (assetType.contains(p.ext))
						{
							return s;
						}
					}
					else
					{
						return s;
					}
				}
			}
		}
		trace("file not found! brace for crash! [parameters:("
			+ " file: "
			+ file
			+ ", xtraLibraries: "
			+ xtraLibraries
			+ ", assetType: "
			+ assetType
			+ ")]");
		return "FILE NOT FOUND";
	}

	public static function getPathList(initalDirectory:String, ?xtraLibraries:Null<Array<String>>, ?assetType:Null<Array<String>>):Array<String> {
		var startingLibrary:String = "";
		if(FileSystem.exists(initalDirectory)){
			if(FileSystem.isDirectory(initalDirectory))
				startingLibrary = initalDirectory;
		}
		
		var completeLibraryData:Array<String> = [];
		completeLibraryData = recursiveLoop(startingLibrary);

		var returnables:Array<String> = [];
		if (xtraLibraries == null)
		{
			for (s in completeLibraryData)
			{
				var p = new haxe.io.Path(s);
			
				if (assetType != null)
				{
					if (assetType.contains(p.ext))
					{
						returnables.push(s);
					}
				}
				else
				{
					returnables.push(s);
				}				
			}
		}
		else{
			for (s in completeLibraryData)
			{
				var libs = s.split("/");
				var p = new haxe.io.Path(s);
				
				var matching = 0;
				for (ss in xtraLibraries)
				{
					if (libs.contains(ss))
						matching++;
				}
				if (matching != xtraLibraries.length)
					continue;

				if (assetType != null)
				{
					if (assetType.contains(p.ext))
					{
						returnables.push(s);
					}
				}
				else
				{
					returnables.push(s);
				}
			}
		}

		if(returnables.length == 0){
			returnables = ["FILE NOT FOUND"];
		}
		
		return returnables;
	}

	public static function recursiveLoop(directory:String):Array<String>
	{
		if (sys.FileSystem.exists(directory))
		{
			// trace("directory found: " + directory);
			var fileList:Array<String> = [];
			for (file in sys.FileSystem.readDirectory(directory))
			{
				var path = haxe.io.Path.join([directory, file]);
				if (!sys.FileSystem.isDirectory(path))
				{
					// trace("file found: " + path);
					// do something with file
					fileList.push(path);
				}
				else
				{
					var directory = haxe.io.Path.addTrailingSlash(path);
					// trace("directory found: " + directory);
					for (s in recursiveLoop(directory))
					{
						fileList.push(s);
					}
				}
			}
			return fileList;
		}
		else
		{
			LogFile.error('"$directory" does not exist\n',true);
			return [];
		}
	}
}
