package;

#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;
import Achievements;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxTimer;

using StringTools;

class SettingsMenuState extends MusicBeatSubstate
{
	public static var curSelected:Int = 0;

	public static var versionStuff:FlxText;
	public static var fallinStuff:FlxText;

	public static var menuItems:FlxTypedGroup<FlxSprite>;
	private var camGame:FlxCamera;
	private var camAchievement:FlxCamera;
	
	var optionStuff:Array<String> = [
		'options',
		'credits',
		'exit'
	];

	var camFollow:FlxObject;
	var camFollowPos:FlxObject;
	var debugKeys:Array<FlxKey>;

	override function create()
	{
		WeekData.loadTheFirstEnabledMod();

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Settings Menu", null);
		#end

		camGame = new FlxCamera();
		camAchievement = new FlxCamera();
		camAchievement.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camAchievement);
		FlxCamera.defaultCameras = [camGame];

		persistentUpdate = persistentDraw = true;

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);

		FlxG.mouse.visible = false;

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		var scale:Float = 1;
		/*if(optionStuff.length > 6) {
			scale = 6 / optionStuff.length;
		}*/

		for (i in 0...optionStuff.length)
		{
			var offset:Float = -90 - (Math.max(optionStuff.length, 4) - 4) * 80;
			var menuItem:FlxSprite = new FlxSprite((i * 410) + offset, 0);
			menuItem.scale.x = scale;
			menuItem.scale.y = scale;
			menuItem.frames = Paths.getSparrowAtlas('fallmen/UI/Menu/Settings/' + optionStuff[i] + '_buttons');
			menuItem.animation.addByPrefix('idle', optionStuff[i] + "_idle", 24, true);
			menuItem.animation.addByPrefix('selected', optionStuff[i] + "_select", 24, true);
			menuItem.animation.addByPrefix('press', optionStuff[i] + "_press", 24, false);
			menuItem.animation.play('idle');
			menuItem.ID = i;
			menuItem.screenCenter(Y);
			menuItems.add(menuItem);
			var scr:Float = (optionStuff.length - 4) * 0.135;
			if(optionStuff.length < 6) scr = 0;
			menuItem.scrollFactor.set(0, scr);
			menuItem.antialiasing = ClientPrefs.globalAntialiasing;
			//menuItem.setGraphicSize(Std.int(menuItem.width * 0.58));
			menuItem.updateHitbox();
		}

		versionStuff = new FlxText(5, 675, 200, "Psych v" + MainMenuState.psychEngineVersion, 12);
		versionStuff.scrollFactor.set();
		versionStuff.setFormat(Paths.font("phantom.ttf"), 16, FlxColor.BLACK, LEFT);
		versionStuff.antialiasing = ClientPrefs.globalAntialiasing;
		versionStuff.alpha = 0.4;
		add(versionStuff);

		fallinStuff = new FlxText(5, 695, 400, "Fallin' Cancelled Build (v" + MainMenuState.fallinVersion + ")", 12);
		fallinStuff.scrollFactor.set();
		fallinStuff.setFormat(Paths.font("phantom.ttf"), 16, FlxColor.BLACK, LEFT);
		fallinStuff.antialiasing = ClientPrefs.globalAntialiasing;
		fallinStuff.alpha = 0.4;
		add(fallinStuff);

		changeItem();

		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.screenCenter(Y);
		});

		menuTrans(0);

		addTouchPad("LEFT_RIGHT", "A_B");
		addTouchPadCamera();
		
		super.create();
	}
	
	public static function menuTrans(INorOUT)
	{
		if (ClientPrefs.menuTrans)
		{
			BackgroundState.transitioning = true;

			if (INorOUT == 0)
			{
				versionStuff.alpha = 0;
				FlxTween.tween(versionStuff, {alpha: 0.4}, 1, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});

				fallinStuff.alpha = 0;
				FlxTween.tween(fallinStuff, {alpha: 0.4}, 1, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});

				menuItems.forEach(function(spr:FlxSprite)
				{
					spr.y = spr.y + 720;
					FlxTween.tween(spr, {y: spr.y - 720}, 2, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});
				});

				new FlxTimer().start(2, function(tmr:FlxTimer)
				{
					BackgroundState.transitioning = false;
				});
			}
			else
			{
				FlxTween.tween(versionStuff, {alpha: 0}, 1, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});

				FlxTween.tween(fallinStuff, {alpha: 0}, 1, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});

				menuItems.forEach(function(spr:FlxSprite)
				{
					FlxTween.tween(spr, {y: spr.y - 720}, 2, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});
				});
			}
		}
	}

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{
		if (FlxG.keys.justPressed.F)
		{
			FlxG.fullscreen = !FlxG.fullscreen;
		}
		
		var lerpVal:Float = CoolUtil.boundTo(elapsed * 7.5, 0, 1);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

		if (!selectedSomethin && BackgroundState.transitioning == false)
		{
			if (controls.UI_LEFT_P || touchPad.buttonLeft.justPressed)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(-1);
			}

			if (controls.UI_RIGHT_P || touchPad.buttonRight.justPressed)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(1);
			}

			if (controls.BACK || touchPad.buttonB.justPressed)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				menuTrans(1);
				if (ClientPrefs.menuTrans)
				{
					new FlxTimer().start(2, function(tmr:FlxTimer)
					{
						close();
						BackgroundState.curMenu = "Main";
						BackgroundState.fadeBackground();
						BackgroundState.doneSwitching = false;
					});
				}
				else
				{
					close();
					BackgroundState.curMenu = "Main";
					BackgroundState.fadeBackground();
					BackgroundState.doneSwitching = false;
				}
			}

			if (controls.ACCEPT || touchPad.buttonA.justPressed)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('confirmMenu2'));
				
				var daChoice:String = optionStuff[curSelected];

				menuItems.forEach(function(spr:FlxSprite)
				{
					if (curSelected != spr.ID)
					{
						spr.animation.play('idle');
					}
					else
					{
						spr.animation.play('press');
					}
				});
				
				new FlxTimer().start(1, function(tmr:FlxTimer)
				{
					switch (daChoice)
					{
						case 'options':
							close();
							BackgroundState.curMenu = "Options";
							BackgroundState.fadeBackground();
							BackgroundState.doneSwitching = false;
						case 'credits':
							close();
							BackgroundState.curMenu = "Credits";
							BackgroundState.fadeBackground();
							BackgroundState.doneSwitching = false;
						case 'exit':
							Sys.exit(0);
					}
				});
			}
		}

		super.update(elapsed);
	}

	function changeItem(huh:Int = 0)
	{
		curSelected += huh;

		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;

		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.animation.play('idle');
			spr.updateHitbox();

			if (spr.ID == curSelected)
			{
				spr.animation.play('selected');
				var add:Float = 0;
				if(menuItems.length > 4) {
					add = menuItems.length * 8;
				}
				spr.centerOffsets();
			}
		});
		
		menuItems.forEach(function(spr:FlxSprite)
		{
			if (BackgroundState.transitioning == false)
			{
				spr.screenCenter(Y);
			}
		});
	}
}
