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

class SkinsSelState extends MusicBeatSubstate
{
	public static var curSelected:Int = 0;

	public static var skinMenuMoveBack:Bool = false;

	public static var devSkinMode:Bool = false;

	public static var menuItems:FlxTypedGroup<FlxSprite>;
	private var camGame:FlxCamera;
	private var camAchievement:FlxCamera;

	public static var platform:FlxSprite;
	public static var player:Character;
	public var transBox:FlxSprite;

	public static var leftArrow:FlxSprite;
	public static var rightArrow:FlxSprite;

	public static var cursor:FlxSprite;
	public static var cursorTrans:FlxSprite;

	var playHoverSound:Bool;
	
	var optionStuff:Array<String> = [
		'costumes',
		'interface'
	];

	var camFollow:FlxObject;
	var camFollowPos:FlxObject;
	var debugKeys:Array<FlxKey>;

	override function create()
	{
		WeekData.loadTheFirstEnabledMod();

		devSkinMode = true;

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("Skins Menu", null);
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

		cursor = new FlxSprite(0, 0).loadGraphic(Paths.image('fallmen/UI/cursor'));
		cursor.updateHitbox();
		cursor.antialiasing = ClientPrefs.globalAntialiasing;

		cursorTrans = new FlxSprite(0, 0).loadGraphic(Paths.image('fallmen/UI/cursorTrans'));
		cursorTrans.updateHitbox();
		cursorTrans.antialiasing = ClientPrefs.globalAntialiasing;

		BackgroundState.buttonHome.loadGraphic(Paths.image('fallmen/UI/Menu/buttonMain'));
		BackgroundState.buttonSkins.loadGraphic(Paths.image('fallmen/UI/Menu/buttonSkinsSel'));
		
		platform = new FlxSprite(71, 493).loadGraphic(Paths.image('fallmen/UI/Menu/plat1'));
		platform.scrollFactor.set();
		platform.updateHitbox();
		platform.antialiasing = ClientPrefs.globalAntialiasing;
		add(platform);

		if (FlxG.save.data.BFskin == "songDefault")
		{
			if (MainMenuState.curSong == 'free falling' || MainMenuState.curSong == 'splash zone' || MainMenuState.curSong == 'royal rumble' || MainMenuState.curSong == 'short circut')
			{
				player = new Character(44 - 224, 231 - 216, 'bf');
			}
			else
			{
				player = new Character(44, 231, 'bf');
			}
		}
		else if (FlxG.save.data.BFskin == 'og')
		{
			player = new Character(44 - 35, 231 - 10, 'bf');
		}
		else if (FlxG.save.data.BFskin == 'hotDog')
		{
			player = new Character(44 - 224, 231 - 216, 'bf');
		}
		else if (FlxG.save.data.BFskin == 'fallguy')
		{
			player = new Character(44 - 75, 231 - 190, 'bf');
		}
		else if (FlxG.save.data.BFskin == 'FgFan')
		{
			player = new Character(44 + 17, 231, 'bf');
		}
		else if (FlxG.save.data.BFskin == 'pigeon')
		{
			player = new Character(44 - 25, 231 - 60, 'bf');
		}
		else if (FlxG.save.data.BFskin == 'ninja')
		{
			player = new Character(44 + 13, 231 - 16, 'bf');
		}
		else if (FlxG.save.data.BFskin == 'sus')
		{
			player = new Character(44 - 10, 231 + 22, 'bf');
		}
		else if (FlxG.save.data.BFskin == 'winner')
		{
			player = new Character(44 - 10, 231 - 60, 'bf');
		}
		else if (FlxG.save.data.BFskin == 'Gglizzy')
		{
			player = new Character(44 - 224, 231 - 216, 'bf');
		}
		else
		{
			player = new Character(44, 231, 'bf');
		}

		player.scale.set(0.58, 0.58);
		add(player);

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		var scale:Float = 1;
		/*if(optionStuff.length > 6) {
			scale = 6 / optionStuff.length;
		}*/

		for (i in 0...optionStuff.length)
		{
			var offset:Float = -130 - (Math.max(optionStuff.length, 4) - 4) * 80;
			var menuItem:FlxSprite = new FlxSprite((i * 410) + offset, 0);
			menuItem.scale.x = scale;
			menuItem.scale.y = scale;
			menuItem.frames = Paths.getSparrowAtlas('fallmen/UI/Menu/Skins/' + optionStuff[i] + '_buttons');
			menuItem.animation.addByPrefix('idle', optionStuff[i] + "_idle", 24, true);
			menuItem.animation.addByPrefix('selected', optionStuff[i] + "_select", 24, true);
			menuItem.animation.addByPrefix('press', optionStuff[i] + "_press", 24, false);
			menuItem.animation.play('idle');
			menuItem.ID = i;
			menuItem.screenCenter(Y);
			menuItem.x = menuItem.x + 400;
			menuItems.add(menuItem);
			var scr:Float = (optionStuff.length - 4) * 0.135;
			if(optionStuff.length < 6) scr = 0;
			menuItem.scrollFactor.set(0, scr);
			menuItem.antialiasing = ClientPrefs.globalAntialiasing;
			//menuItem.setGraphicSize(Std.int(menuItem.width * 0.58));
			menuItem.updateHitbox();
		}

		changeItem();
		
		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.screenCenter(Y);
		});

		leftArrow = new FlxSprite(306, 269);
		leftArrow.scrollFactor.set();
		leftArrow.antialiasing = ClientPrefs.globalAntialiasing;
		leftArrow.frames = Paths.getSparrowAtlas('fallmen/UI/Menu/menu_arrows');
		leftArrow.animation.addByPrefix('idle', "left_arrow-idle", 24, true);
		leftArrow.animation.addByPrefix('press', "left_arrow-press", 24, true);
		leftArrow.animation.play('idle');
		add(leftArrow);

		rightArrow = new FlxSprite(1201, 269);
		rightArrow.scrollFactor.set();
		rightArrow.antialiasing = ClientPrefs.globalAntialiasing;
		rightArrow.frames = Paths.getSparrowAtlas('fallmen/UI/Menu/menu_arrows');
		rightArrow.animation.addByPrefix('idle', "right_arrow-idle", 24, true);
		rightArrow.animation.addByPrefix('press', "right_arrow-press", 24, true);
		rightArrow.animation.play('idle');
		add(rightArrow);

		if (skinMenuMoveBack != true)
		{
			menuTrans(0);
			skinMenuMoveBack = false;
		}
		else
		{
			skinMenuMoveBack = false;
		}
		
		transBox = new FlxSprite(296, 167);
		transBox.makeGraphic(984, 401, 0xFFFF0000);
		transBox.alpha = 0;
		transBox.updateHitbox();
		transBox.antialiasing = ClientPrefs.globalAntialiasing;
		add(transBox);

	    addTouchPad("LEFT_RIGHT", "A");
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
				platform.y = platform.y + 720;
				FlxTween.tween(platform, {y: platform.y - 720}, 1, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});

				player.y = player.y + 720;
				FlxTween.tween(player, {y: player.y - 720}, 1, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});
				
				menuItems.forEach(function(spr:FlxSprite)
				{
					spr.x = spr.x + 1280;
					FlxTween.tween(spr, {x: spr.x - 1280}, 2, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});
				});
				
				leftArrow.x = leftArrow.x + 1280;
				FlxTween.tween(leftArrow, {x: leftArrow.x - 1280}, 2, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});
				
				rightArrow.x = rightArrow.x + 1280;
				FlxTween.tween(rightArrow, {x: rightArrow.x - 1280}, 2, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});

				new FlxTimer().start(2, function(tmr:FlxTimer)
				{
					BackgroundState.transitioning = false;
					FlxG.mouse.visible = true;
					FlxG.mouse.load(cursor.pixels);
				});
			}
			else
			{
				FlxTween.tween(platform, {y: platform.y + 720}, 1, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});

				FlxTween.tween(player, {y: player.y + 720}, 1, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});

				menuItems.forEach(function(spr:FlxSprite)
				{
					FlxTween.tween(spr, {x: spr.x - 1280}, 2, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});
				});
				
				FlxTween.tween(leftArrow, {x: leftArrow.x - 1280}, 2, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});

				FlxTween.tween(rightArrow, {x: rightArrow.x - 1280}, 2, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});
			}
		}
	}

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{
		player.dance();

		if (FlxG.keys.justPressed.F)
		{
			FlxG.fullscreen = !FlxG.fullscreen;
		}

		var lerpVal:Float = CoolUtil.boundTo(elapsed * 7.5, 0, 1);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

		if (!selectedSomethin && BackgroundState.transitioning == false)
		{
			if (FlxG.mouse.overlaps(BackgroundState.buttonHome))
			{
				if (playHoverSound == true)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'));
					playHoverSound = false;
				}
				BackgroundState.buttonHome.setGraphicSize(Std.int(BackgroundState.buttonHome.width * 1.06636501));
				if (FlxG.mouse.justPressed)
				{
					FlxG.mouse.load(cursor.pixels);
					BackgroundState.buttonHome.loadGraphic(Paths.image('fallmen/UI/Menu/buttonMainSel'));
					BackgroundState.buttonSkins.loadGraphic(Paths.image('fallmen/UI/Menu/buttonSkins'));
					BackgroundState.buttonHome.setGraphicSize(Std.int(BackgroundState.buttonHome.width * 1));
					selectedSomethin = true;
					BackgroundState.stayingOnMenu = true;
					menuTrans(1);
					FlxG.sound.play(Paths.sound('confirmMenu2'));
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
			}
			else
			{
				BackgroundState.buttonHome.setGraphicSize(Std.int(BackgroundState.buttonHome.width * 1));
				playHoverSound = true;
			}

			if (FlxG.keys.justPressed.LBRACKET)
			{
				FlxG.mouse.load(cursor.pixels);
				BackgroundState.buttonHome.loadGraphic(Paths.image('fallmen/UI/Menu/buttonMainSel'));
				BackgroundState.buttonSkins.loadGraphic(Paths.image('fallmen/UI/Menu/buttonSkins'));
				selectedSomethin = true;
				BackgroundState.stayingOnMenu = true;
				menuTrans(1);
				FlxG.sound.play(Paths.sound('confirmMenu2'));
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

			if (FlxG.mouse.overlaps(transBox))
			{
				FlxG.mouse.load(cursorTrans.pixels);
			}
			else
			{
				FlxG.mouse.load(cursor.pixels);
			}

			if (controls.UI_LEFT_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(-1);
				leftArrow.animation.play('press');
			}
			else
			{
				leftArrow.animation.play('idle');
			}

			if (controls.UI_RIGHT_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(1);
				rightArrow.animation.play('press');
			}
			else
			{
				rightArrow.animation.play('idle');
			}

			if (controls.ACCEPT)
			{
				FlxG.mouse.load(cursor.pixels);
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
						case 'costumes':
							selectedSomethin = true;
							BackgroundState.stayingOnMenu = true;
							close();
							BackgroundState.curMenu = "Skins: Boyfriend";
							BackgroundState.fadeBackground();
							BackgroundState.doneSwitching = false;
						case 'interface':
							selectedSomethin = true;
							BackgroundState.stayingOnMenu = true;
							close();
							BackgroundState.curMenu = "Skins: Background 1";
							BackgroundState.doneSwitching = false;
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
