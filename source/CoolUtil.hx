package;

import flixel.FlxG;
import openfl.utils.Assets;
import lime.utils.Assets as LimeAssets;
import lime.utils.AssetLibrary;
import flixel.util.FlxColor;
import lime.utils.AssetManifest;
#if sys
import sys.io.File;
import sys.FileSystem;
#else
import openfl.utils.Assets;
#end

using StringTools;

class CoolUtil
{
	public static var defaultDifficulties:Array<String> = [
		'Easy',
		'Normal',
		'Hard'
	];
	public static var defaultDifficulty:String = 'Normal'; //The chart that has no suffix and starting difficulty on Freeplay/Story Mode

	public static var difficulties:Array<String> = [];

	public static function getDifficultyFilePath(num:Null<Int> = null)
	{
		if(num == null) num = PlayState.storyDifficulty;

		var fileSuffix:String = difficulties[num];
		if(fileSuffix != defaultDifficulty)
		{
			fileSuffix = '-' + fileSuffix;
		}
		else
		{
			fileSuffix = '';
		}
		return Paths.formatToSongPath(fileSuffix);
	}

	public static function difficultyString():String
	{
		return difficulties[PlayState.storyDifficulty].toUpperCase();
	}

	inline public static function boundTo(value:Float, min:Float, max:Float):Float {
		return Math.max(min, Math.min(max, value));
	}

	public static function coolTextFile(path:String):Array<String>
	{
		var daList:Array<String> = [];
		#if sys
		if(FileSystem.exists(path)) daList = File.getContent(path).trim().split('\n');
		#else
		if(Assets.exists(path)) daList = Assets.getText(path).trim().split('\n');
		#end

		for (i in 0...daList.length)
		{
			daList[i] = daList[i].trim();
		}

		return daList;
	}
	public static function colorFromString(color:String):FlxColor
	{
		var hideChars = ~/[\t\n\r]/;
		var color:String = hideChars.split(color).join('').trim();
		if(color.startsWith('0x')) color = color.substring(color.length - 6);

		var colorNum:Null<FlxColor> = FlxColor.fromString(color);
		if(colorNum == null) colorNum = FlxColor.fromString('#$color');
		return colorNum != null ? colorNum : FlxColor.WHITE;
	}
	public static function listFromString(string:String):Array<String>
	{
		var daList:Array<String> = [];
		daList = string.trim().split('\n');

		for (i in 0...daList.length)
		{
			daList[i] = daList[i].trim();
		}

		return daList;
	}
	public static function dominantColor(sprite:flixel.FlxSprite):Int{
		var countByColor:Map<Int, Int> = [];
		for(col in 0...sprite.frameWidth){
			for(row in 0...sprite.frameHeight){
			  var colorOfThisPixel:Int = sprite.pixels.getPixel32(col, row);
			  if(colorOfThisPixel != 0){
				  if(countByColor.exists(colorOfThisPixel)){
				    countByColor[colorOfThisPixel] =  countByColor[colorOfThisPixel] + 1;
				  }else if(countByColor[colorOfThisPixel] != 13520687 - (2*13520687)){
					 countByColor[colorOfThisPixel] = 1;
				  }
			  }
			}
		 }
		var maxCount = 0;
		var maxKey:Int = 0;//after the loop this will store the max color
		countByColor[flixel.util.FlxColor.BLACK] = 0;
			for(key in countByColor.keys()){
			if(countByColor[key] >= maxCount){
				maxCount = countByColor[key];
				maxKey = key;
			}
		}
		return maxKey;
	}

	public static function numberArray(max:Int, ?min = 0):Array<Int>
	{
		var dumbArray:Array<Int> = [];
		for (i in min...max)
		{
			dumbArray.push(i);
		}
		return dumbArray;
	}
	
	public static function flixelSaveCheck(company:String, title:String, localPath:String = 'ninjamuffin99', name:String = 'funkin', newPath:Bool = false):Bool
	{
		// I STOLE THIS FROM DOKI DOKI TAKEOVER PLUS,.',;.;''.; PLEASE PLASEEDS DON'T KILL ME;'';'.; PLAY THE MOD---> https://gamebanana.com/mods/47364 || https://github.com/Jorge-SunSpirit/Doki-Doki-Takeover

		//CoolUtil.flixelSaveCheck('ninjamuffin99', '');

		var invalidChars = ~/[ ~%&\\;:"',<>?#]+/;

		// Avoid checking for .sol files directly in AppData
		if (localPath == "")
		{
			var path = company;

			if (path == null || path == "")
			{
				path = "HaxeFlixel";
			}
			else
			{
				#if html5
				// most chars are fine on browsers
				#else
				path = invalidChars.split(path).join("-");
				#end
			}

			localPath = path;
		}

		var directory = lime.system.System.applicationStorageDirectory;
		var path = '';

		if (newPath)
			path = haxe.io.Path.normalize('$directory/../../../$localPath') + "/";
		else
			path = haxe.io.Path.normalize('$directory/../../../$company/$title/$localPath') + "/";

		name = StringTools.replace(name, "//", "/");
		name = StringTools.replace(name, "//", "/");

		if (StringTools.startsWith(name, "/"))
		{
			name = name.substr(1);
		}

		if (StringTools.endsWith(name, "/"))
		{
			name = name.substring(0, name.length - 1);
		}

		if (name.indexOf("/") > -1)
		{
			var split = name.split("/");
			name = "";

			for (i in 0...(split.length - 1))
			{
				name += "#" + split[i] + "/";
			}

			name += split[split.length - 1];
		}

		/*
		if (FileSystem.exists(path + name + ".sol"))
		{
			trace(path + name + ".sol || IS REALLL");
		}
		else
		{
			trace(path + name + ".sol || err...not real lol");
		}
		*/

		return FileSystem.exists(path + name + ".sol");
	}

	//uhhhh does this even work at all? i'm starting to doubt
	public static function precacheSound(sound:String, ?library:String = null):Void {
		precacheSoundFile(Paths.sound(sound, library));
	}

	public static function precacheMusic(sound:String, ?library:String = null):Void {
		precacheSoundFile(Paths.music(sound, library));
	}

	private static function precacheSoundFile(file:Dynamic):Void {
		if (Assets.exists(file, SOUND) || Assets.exists(file, MUSIC))
			Assets.getSound(file, true);
	}

	public static function browserLoad(site:String) {
		#if linux
		Sys.command('/usr/bin/xdg-open', [site]);
		#else
		FlxG.openURL(site);
		#end
	}
	
	public static function showPopUp(message:String, title:String):Void
	{
		/*#if android
		android.Tools.showAlertDialog(title, message, {name: "OK", func: null}, null);
		#else*/
		FlxG.stage.window.alert(message, title);
		//#end
	}
}
