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
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
using flixel.util.FlxSpriteUtil;
import lime.app.Application;
import Achievements;
import editors.MasterEditorMenu;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxTimer;
import Character;

using StringTools;

class MainMenuState extends MusicBeatSubstate
{
	public static var curSelected:Int = 0;
	public static var showSelected:Bool = false;

	public static var psychEngineVersion:String = '0.5.2h';
	public static var fallinVersion:String = '0.3.0'; //This is also used for Discord RPC and checking for updates

	private var camGame:FlxCamera;
	private var camAchievement:FlxCamera;

	var selectedSomethin:Bool = false;
	
	var playHoverSound:Bool;

	public static var platformOPP:FlxSprite;
	public static var player3:Character;
	public static var platformGF:FlxSprite;
	public static var player2:Character;
	public static var platformBF:FlxSprite;
	public static var player1:Character;
	public static var showBuckBack:FlxSprite;
	public static var showBuckText:FlxText;
	public static var showBuck:FlxSprite;
	public static var kudoBack:FlxSprite;
	public static var kudoText:FlxText;
	public static var kudo:FlxSprite;
	public static var selectShow:FlxSprite;
	public static var playShow:FlxSprite;
	public static var logo:FlxSprite;

	public static var coverscreen:FlxSprite;

	public static var cursor:FlxSprite;

	var camFollow:FlxObject;
	var camFollowPos:FlxObject;
	var debugKeys:Array<FlxKey>;

	var GFbopping:FlxTween;

	public static var curSong:String;

	public static var isMenuCharacter:Bool;

	override function create()
	{
		/*
		CoolUtil.flixelSaveCheck('', '');
		CoolUtil.flixelSaveCheck("Denoohay", "Friday Night Fallin'");
		*/

		WeekData.loadTheFirstEnabledMod();

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end
		debugKeys = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));

		camGame = new FlxCamera();
		camAchievement = new FlxCamera();
		camAchievement.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camAchievement);
		FlxCamera.defaultCameras = [camGame];

		persistentUpdate = persistentDraw = true;
		
		/*
		trace(FlxG.save.data.BFskin);
		trace(FlxG.save.data.GFskin);
		trace(FlxG.save.data.FGskin);
		*/

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);

		cursor = new FlxSprite(0, 0).loadGraphic(Paths.image('fallmen/UI/cursor'));
		cursor.updateHitbox();
		cursor.antialiasing = ClientPrefs.globalAntialiasing;
		FlxG.mouse.load(cursor.pixels);
		
		BackgroundState.buttonHome.loadGraphic(Paths.image('fallmen/UI/Menu/buttonMainSel'));
		BackgroundState.buttonSkins.loadGraphic(Paths.image('fallmen/UI/Menu/buttonSkins'));

		var scale:Float = 1;

		isMenuCharacter = true;

		platformOPP = new FlxSprite(750, 450).loadGraphic(Paths.image('fallmen/UI/Menu/plat1'));
		platformOPP.scrollFactor.set();
		platformOPP.updateHitbox();
		platformOPP.antialiasing = ClientPrefs.globalAntialiasing;
		add(platformOPP);
		
		if (curSong == 'splash zone')
		{
			player3 = new Character(656, -51, 'moon');
		}
		else if (curSong == 'royal rumble')
		{
			player3 = new Character(610, 4, 'apple');
		}
		else if (curSong == 'stringbean')
		{
			player3 = new Character(685, 70, 'lolbean');
		}
		else if (curSong == 'better bean')
		{
			player3 = new Character(0, 0, 'nothing');
			platformOPP.alpha = 0;
		}
		else if (curSong == 'logic funkin collab')
		{
			player3 = new Character(0, 0, 'nothing');
			platformOPP.alpha = 0;
		}
		else if (curSong == 'short circut')
		{
			player3 = new Character(720, 185, 'beanbot');
		}
		else
		{
			if (FlxG.save.data.FGskin == "bolts")
			{
				player3 = new Character(610 + 25, 55, 'fall-guy');
			}
			else if (FlxG.save.data.FGskin == "furry")
			{
				player3 = new Character(610 + 29, 55 - 29, 'fall-guy');
			}
			else if (FlxG.save.data.FGskin == "hotDog")
			{
				player3 = new Character(610 + 47, 55 - 25, 'fall-guy');
			}
			else if (FlxG.save.data.FGskin == "longGuy")
			{
				player3 = new Character(610 + 32, 55 - 119, 'fall-guy');
			}
			else if (FlxG.save.data.FGskin == "sonic")
			{
				player3 = new Character(610 - 57, 55 - 74, 'fall-guy');
			}
			else if (FlxG.save.data.FGskin == "tankGuy")
			{
				player3 = new Character(610, 55, 'fall-guy');
			}
			else if (FlxG.save.data.FGskin == "cheesus")
			{
				player3 = new Character(610 + 22, 55 - 138, 'fall-guy');
			}
			else if (FlxG.save.data.FGskin == "sus")
			{
				player3 = new Character(610 + 24, 55 - 17, 'fall-guy');
			}
			else if (FlxG.save.data.FGskin == "rookie")
			{
				player3 = new Character(610 + 20, 55, 'fall-guy');
			}
			else if (FlxG.save.data.FGskin == "plush")
			{
				player3 = new Character(610 - 83, 55 - 171, 'fall-guy');
			}
			else if (FlxG.save.data.FGskin == "beta" || FlxG.save.data.FGskin == "demo" || FlxG.save.data.FGskin == "legacy1" || FlxG.save.data.FGskin == "legacy2")
			{
				player3 = new Character(610 - 236, 55 - 200, 'fall-guy');
			}
			else
			{
				player3 = new Character(610, 55, 'fall-guy');
			}
		}
		player3.setGraphicSize(Std.int(player3.width * 0.58));
		add(player3);

		platformGF = new FlxSprite(250, 450).loadGraphic(Paths.image('fallmen/UI/Menu/plat1'));
		platformGF.scrollFactor.set();
		platformGF.updateHitbox();
		platformGF.antialiasing = ClientPrefs.globalAntialiasing;
		add(platformGF);

		if (curSong == 'better bean')
		{
			player2 = new Character(165, 264, 'calobi-sus', true);
		}
		else if (curSong == 'logic funkin collab')
		{
			player2 = new Character(38, 71, 'fgLogic', true);
		}
		else
		{
			if (FlxG.save.data.GFskin == "songDefault")
			{
				if (MainMenuState.curSong == 'free falling' || MainMenuState.curSong == 'splash zone' || MainMenuState.curSong == 'royal rumble' || MainMenuState.curSong == 'short circut')
				{
					player2 = new Character(231, 85 - 31, 'gf');
				}
				else
				{
					player2 = new Character(231, 85, 'gf');
				}
			}
			else if (FlxG.save.data.GFskin == "og")
			{
				player2 = new Character(231 - 48, 85, 'gf-og-small');
			}
			else if (FlxG.save.data.GFskin == "og-small")
			{
				player2 = new Character(231 - 48, 85, 'gf-og-small');
			}
			else if (FlxG.save.data.GFskin == "trackstar")
			{
				player2 = new Character(231, 85 - 31, 'gf');
			}
			else if (FlxG.save.data.GFskin == "fallguy")
			{
				player2 = new Character(231 - 150, 85 - 130, 'gf');
			}
			else if (FlxG.save.data.GFskin == "FgFan")
			{
				player2 = new Character(231 + 17, 85, 'gf');
			}
			else if (FlxG.save.data.GFskin == "hotDog")
			{
				player2 = new Character(231 - 160, 85 - 152, 'gf');
			}
			else if (FlxG.save.data.GFskin == "pegwin")
			{
				player2 = new Character(231 + 27, 85 + 287, 'gf');
			}
			else if (FlxG.save.data.GFskin == "miku")
			{
				player2 = new Character(231 + 56, 85 + 33, 'gf');
			}
			else if (FlxG.save.data.GFskin == "robot")
			{
				player2 = new Character(231 - 40, 85 - 52, 'gf');
			}
			else
			{
				player2 = new Character(231, 85, 'gf');

				if (FlxG.save.data.GFskin == "nothing")
				{
					platformGF.alpha = 0;
				}
			}
		}
		player2.scale.set(0.58, 0.58);
		add(player2);
		player2.dance();
		if (curSong != 'better bean')
		{
			player2.dance();
			GFbopping = FlxTween.tween(player2, {alpha: 1}, 0.5, {type: LOOPING,
			onComplete: function(twn:FlxTween)
			{
				player2.dance();
			}
			});
		}
		else
		{
			GFbopping = FlxTween.tween(player2, {alpha: 1}, 1, {type: LOOPING});
		}

		platformBF = new FlxSprite(492, 488).loadGraphic(Paths.image('fallmen/UI/Menu/plat1'));
		platformBF.scrollFactor.set();
		platformBF.updateHitbox();
		platformBF.antialiasing = ClientPrefs.globalAntialiasing;
		add(platformBF);

		if (curSong == 'better bean')
		{
			player1 = new Character(431, 233, 'calobi-guy');
		}
		else if (curSong == 'logic funkin collab')
		{
			if (FlxG.save.data.FGskin == "bolts")
			{
				player1 = new Character(349 + 25, 95, 'fall-guy');
			}
			else if (FlxG.save.data.FGskin == "furry")
			{
				player1 = new Character(349 + 29, 95 - 29, 'fall-guy');
			}
			else if (FlxG.save.data.FGskin == "hotDog")
			{
				player1 = new Character(349 + 47, 95 - 25, 'fall-guy');
			}
			else if (FlxG.save.data.FGskin == "longGuy")
			{
				player1 = new Character(349 + 32, 95 - 119, 'fall-guy');
			}
			else if (FlxG.save.data.FGskin == "sonic")
			{
				player1 = new Character(349 - 57, 95 - 74, 'fall-guy');
			}
			else if (FlxG.save.data.FGskin == "tankGuy")
			{
				player1 = new Character(349, 95, 'fall-guy');
			}
			else if (FlxG.save.data.FGskin == "cheesus")
			{
				player1 = new Character(349 + 22, 95 - 138, 'fall-guy');
			}
			else if (FlxG.save.data.FGskin == "sus")
			{
				player1 = new Character(349 + 24, 95 - 17, 'fall-guy');
			}
			else if (FlxG.save.data.FGskin == "rookie")
			{
				player1 = new Character(349 + 20, 95, 'fall-guy');
			}
			else if (FlxG.save.data.FGskin == "plush")
			{
				player1 = new Character(349 - 83, 95 - 171, 'fall-guy');
			}
			else if (FlxG.save.data.FGskin == "beta" || FlxG.save.data.FGskin == "demo" || FlxG.save.data.FGskin == "legacy1" || FlxG.save.data.FGskin == "legacy2")
			{
				player1 = new Character(349 - 236, 95 - 200, 'fall-guy');
			}
			else
			{
				player1 = new Character(349, 95, 'fall-guy');
			}
			
		}
		else
		{
			if (FlxG.save.data.BFskin == "songDefault")
			{
				if (MainMenuState.curSong == 'free falling' || MainMenuState.curSong == 'splash zone' || MainMenuState.curSong == 'royal rumble' || MainMenuState.curSong == 'short circut')
				{
					player1 = new Character(454 - 169, 231 - 216, 'bf', true);
				}
				else
				{
					player1 = new Character(454, 231, 'bf', true);
				}
			}
			else if (FlxG.save.data.BFskin == 'og')
			{
				player1 = new Character(454 - 35, 231 - 10, 'bf', true);
			}
			else if (FlxG.save.data.BFskin == 'hotDog')
			{
				player1 = new Character(454 - 169, 231 - 216, 'bf', true);
			}
			else if (FlxG.save.data.BFskin == 'fallguy')
			{
				player1 = new Character(454 - 105, 231 - 190, 'bf', true);
			}
			else if (FlxG.save.data.BFskin == 'FgFan')
			{
				player1 = new Character(454 + 17, 231, 'bf', true);
			}
			else if (FlxG.save.data.BFskin == 'pigeon')
			{
				player1 = new Character(454 - 25, 231 - 60, 'bf', true);
			}
			else if (FlxG.save.data.BFskin == 'ninja')
			{
				player1 = new Character(454 + 13, 231 - 16, 'bf', true);
			}
			else if (FlxG.save.data.BFskin == 'sus')
			{
				player1 = new Character(454 - 60, 231 + 22, 'bf', true);
			}
			else if (FlxG.save.data.BFskin == 'winner')
			{
				player1 = new Character(454 + 10, 231 - 60, 'bf', true);
			}
			else if (FlxG.save.data.BFskin == 'Gglizzy')
			{
				player1 = new Character(454 - 169, 231 - 216, 'bf', true);
			}
			else
			{
				player1 = new Character(454, 231, 'bf', true);
			}
		}
		player1.setGraphicSize(Std.int(player1.width * 0.58));
		add(player1);

		showBuckBack = new FlxSprite(907, 95).loadGraphic(Paths.image('fallmen/UI/Menu/showback'));
		showBuckBack.scrollFactor.set();
		showBuckBack.updateHitbox();
		showBuckBack.antialiasing = ClientPrefs.globalAntialiasing;
		add(showBuckBack);

		showBuckText = new FlxText(968, 100, 200, FlxG.save.data.showbucksESTRDTYFUYGIUOHOIJKNBJHVCGUV);
		showBuckText.scrollFactor.set();
		showBuckText.setFormat(Paths.font("fall.ttf"), 22, FlxColor.WHITE, LEFT);
		showBuckText.antialiasing = ClientPrefs.globalAntialiasing;
		add(showBuckText);

		showBuck = new FlxSprite(890, 80).loadGraphic(Paths.image('fallmen/UI/Menu/showbuck'));
		showBuck.scrollFactor.set();
		showBuck.updateHitbox();
		showBuck.antialiasing = ClientPrefs.globalAntialiasing;
		add(showBuck);

		kudoBack = new FlxSprite(907, 21).loadGraphic(Paths.image('fallmen/UI/Menu/kudoback'));
		kudoBack.scrollFactor.set();
		kudoBack.updateHitbox();
		kudoBack.antialiasing = ClientPrefs.globalAntialiasing;
		add(kudoBack);

		kudoText = new FlxText(968, 25, 200, FlxG.save.data.kudosAHETSRYJDTUFKYGJLBVKJKGCYFILGKVJ);
		kudoText.scrollFactor.set();
		kudoText.setFormat(Paths.font("fall.ttf"), 22, FlxColor.WHITE, LEFT);
		kudoText.antialiasing = ClientPrefs.globalAntialiasing;
		add(kudoText);

		kudo = new FlxSprite(890, 7).loadGraphic(Paths.image('fallmen/UI/Menu/kudo'));
		kudo.scrollFactor.set();
		kudo.updateHitbox();
		kudo.antialiasing = ClientPrefs.globalAntialiasing;
		add(kudo);

		selectShow = new FlxSprite(899, 473).loadGraphic(Paths.image('fallmen/UI/Menu/Main/selshow'));
		selectShow.scrollFactor.set();
		selectShow.updateHitbox();
		selectShow.antialiasing = ClientPrefs.globalAntialiasing;
		add(selectShow);

		playShow = new FlxSprite(804, 599).loadGraphic(Paths.image('fallmen/UI/Menu/Main/play ' + curSong));
		playShow.scrollFactor.set();
		playShow.updateHitbox();
		playShow.antialiasing = ClientPrefs.globalAntialiasing;
		add(playShow);
		if (showSelected == false)
		{
			playShow.alpha = 0;
			selectShow.y = playShow.y;
		}

		logo = new FlxSprite(-13, -9).loadGraphic(Paths.image('fallmen/UI/Menu/Main/logo'));
		logo.scrollFactor.set();
		logo.updateHitbox();
		logo.antialiasing = ClientPrefs.globalAntialiasing;
		add(logo);

		coverscreen = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		if (BackgroundState.transitionFromNonMenu == true)
		{
			coverscreen.alpha = 1;
		}
		else
		{
			coverscreen.alpha = 0;
		}
		add(coverscreen);

		if (FlxG.save.data.freefalling == true && FlxG.save.data.splashzone == true && FlxG.save.data.royalrumble == true && FlxG.save.data.stringbean == true && FlxG.save.data.logicfunkincollab == true && FlxG.save.data.betterbean == true && FlxG.save.data.shortcircut == true && FlxG.save.data.seenendingcredits != true)
		{
			BackgroundState.transitionFromNonMenu = false;
			FlxG.save.data.seenendingcredits = true;

			GFbopping.cancel();
			close();
			BackgroundState.curMenu = "Credits";
			BackgroundState.showBackground();
			BackgroundState.doneSwitching = false;
		}
		else
		{
			menuTrans(0);
		}

		// NG.core.calls.event.logEvent('swag').send();

		#if ACHIEVEMENTS_ALLOWED
		Achievements.loadAchievements();
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18) {
			var achieveID:Int = Achievements.getAchievementIndex('friday_night_play');
			if(!Achievements.isAchievementUnlocked(Achievements.achievementsStuff[achieveID][2])) { //It's a friday night. WEEEEEEEEEEEEEEEEEE
				Achievements.achievementsMap.set(Achievements.achievementsStuff[achieveID][2], true);
				giveAchievement();
				ClientPrefs.saveSettings();
			}
		}
		#end

		super.create();
	}

	public static function menuTrans(INorOUT)
	{
		FlxTween.tween(coverscreen, {alpha: 0}, 1, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});
		BackgroundState.transitionFromNonMenu = false;

		if (ClientPrefs.menuTrans)
		{
			BackgroundState.transitioning = true;

			if (INorOUT == 0)
			{
				platformOPP.y = platformOPP.y + 720;
				FlxTween.tween(platformOPP, {y: platformOPP.y - 720}, 2, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});

				player3.y = player3.y + 720;
				FlxTween.tween(player3, {y: player3.y - 720}, 2, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});

				platformGF.y = platformGF.y + 720;
				FlxTween.tween(platformGF, {y: platformGF.y - 720}, 1.5, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});

				player2.y = player2.y + 720;
				FlxTween.tween(player2, {y: player2.y - 720}, 1.5, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});

				platformBF.y = platformBF.y + 720;
				FlxTween.tween(platformBF, {y: platformBF.y - 720}, 1, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});

				player1.y = player1.y + 720;
				FlxTween.tween(player1, {y: player1.y - 720}, 1, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});
				
				selectShow.x = selectShow.x + 500;
				FlxTween.tween(selectShow, {x: selectShow.x - 500}, 2, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});

				playShow.x = playShow.x + 500;
				FlxTween.tween(playShow, {x: playShow.x - 500}, 1.5, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});

				logo.x = logo.x - 500;
				FlxTween.tween(logo, {x: logo.x + 500}, 2, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});
				
				BackgroundState.buttonOptions.x = BackgroundState.buttonOptions.x + 300;
				FlxTween.tween(BackgroundState.buttonOptions, {x: BackgroundState.buttonOptions.x - 300}, 1.2, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});

				showBuckBack.y = showBuckBack.y - 300;
				FlxTween.tween(showBuckBack, {y: showBuckBack.y + 300}, 1, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});

				showBuckText.y = showBuckText.y - 300;
				FlxTween.tween(showBuckText, {y: showBuckText.y + 300}, 1, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});

				showBuck.y = showBuck.y - 300;
				FlxTween.tween(showBuck, {y: showBuck.y + 300}, 1, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});

				if (FreeplayState.kudoXslide == true)
				{
					kudoBack.x = kudoBack.x + 176;
					FlxTween.tween(kudoBack, {x: kudoBack.x - 176}, 2, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});
					
					kudoText.x = kudoText.x + 176;
					FlxTween.tween(kudoText, {x: kudoText.x - 176}, 2, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});
					
					kudo.x = kudo.x + 176;
					FlxTween.tween(kudo, {x: kudo.x - 176}, 2, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});

					FreeplayState.kudoXslide = false;
				}
				else
				{
					kudoBack.y = kudoBack.y - 100;
					FlxTween.tween(kudoBack, {y: kudoBack.y + 100}, 1, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});

					kudoText.y = kudoText.y - 100;
					FlxTween.tween(kudoText, {y: kudoText.y + 100}, 1, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});

					kudo.y = kudo.y - 100;
					FlxTween.tween(kudo, {y: kudo.y + 100}, 1, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});
				}
					
				if (BackgroundState.stayingOnMenu != true)
				{
					BackgroundState.topBar.y = BackgroundState.topBar.y - 100;
					FlxTween.tween(BackgroundState.topBar, {y: BackgroundState.topBar.y + 100}, 1.2, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});

					BackgroundState.buttonHome.y = BackgroundState.buttonHome.y - 100;
					FlxTween.tween(BackgroundState.buttonHome, {y: BackgroundState.buttonHome.y + 100}, 1.2, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});

					BackgroundState.buttonSkins.y = BackgroundState.buttonSkins.y - 100;
					FlxTween.tween(BackgroundState.buttonSkins, {y: BackgroundState.buttonSkins.y + 100}, 1.2, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});
				}
				else
				{
					BackgroundState.topBar.y = 0;

					BackgroundState.buttonHome.y = 13;

					BackgroundState.buttonSkins.y = 13;

					BackgroundState.stayingOnMenu = false;
				}

				new FlxTimer().start(2, function(tmr:FlxTimer)
				{
					BackgroundState.transitioning = false;
					FlxG.mouse.visible = true;
					FlxG.mouse.load(cursor.pixels);
				});
			}
			else
			{
				FlxTween.tween(platformOPP, {y: platformOPP.y + 720}, 2, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});

				FlxTween.tween(player3, {y: player3.y + 720}, 2, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});

				FlxTween.tween(platformGF, {y: platformGF.y + 720}, 1.5, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});

				FlxTween.tween(player2, {y: player2.y + 720}, 1.5, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});

				FlxTween.tween(platformBF, {y: platformBF.y + 720}, 1, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});

				FlxTween.tween(player1, {y: player1.y + 720}, 1, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});
				
				FlxTween.tween(selectShow, {x: selectShow.x + 500}, 2, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});

				FlxTween.tween(playShow, {x: playShow.x + 500}, 1.5, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});

				FlxTween.tween(logo, {x: logo.x - 500}, 2, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});
				
				FlxTween.tween(BackgroundState.buttonOptions, {x: BackgroundState.buttonOptions.x + 300}, 1.2, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});

				if (BackgroundState.curMenu != "Main" || BackgroundState.curMenu != "Pass" || BackgroundState.curMenu != "Shop")
				{
					FlxTween.tween(showBuckBack, {y: showBuckBack.y - 300}, 1, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});

					FlxTween.tween(showBuckText, {y: showBuckText.y - 300}, 1, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});

					FlxTween.tween(showBuck, {y: showBuck.y - 300}, 1, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});
				
					if (FreeplayState.kudoXslide == true)
					{
						FlxTween.tween(kudoBack, {x: kudoBack.x + 176}, 2, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});

						FlxTween.tween(kudoText, {x: kudoText.x + 176}, 2, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});

						FlxTween.tween(kudo, {x: kudo.x + 176}, 2, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});
					}
					else
					{
						FlxTween.tween(kudoBack, {y: kudoBack.y - 100}, 1, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});

						FlxTween.tween(kudoText, {y: kudoText.y - 100}, 1, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});

						FlxTween.tween(kudo, {y: kudo.y - 100}, 1, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});
					}
				}

				if (BackgroundState.stayingOnMenu != true)
				{
					FlxTween.tween(BackgroundState.topBar, {y: BackgroundState.topBar.y - 100}, 1.2, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});

					FlxTween.tween(BackgroundState.buttonHome, {y: BackgroundState.buttonHome.y - 100}, 1.2, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});

					FlxTween.tween(BackgroundState.buttonSkins, {y: BackgroundState.buttonSkins.y - 100}, 1.2, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});
				}
				else
				{
					BackgroundState.stayingOnMenu = false;
				}

			}
		}
		else
		{
			FlxG.mouse.visible = true;
			FlxG.mouse.load(cursor.pixels);
		}
	}

	override function update(elapsed:Float)
	{
		player1.dance();
		if (curSong == 'better bean')
		{
			player2.dance();
		}
		player3.dance();

		if(FlxG.sound.music == null)
		{
			FlxG.sound.playMusic(Paths.music('freakyMenu'), 0.5);
		}
		
		if (FlxG.sound.music.volume != 0.5)
		{
			FlxG.sound.music.volume = 0.5;
		}

		if (FlxG.keys.justPressed.F)
		{
			FlxG.fullscreen = !FlxG.fullscreen;
		}

		/*
		if (FlxG.keys.justPressed.B)
		{
			GFbopping.cancel();
			MusicBeatState.switchState(new BackgroundTestState());
		}
		*/

		var lerpVal:Float = CoolUtil.boundTo(elapsed * 7.5, 0, 1);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
		
		if (selectedSomethin == false && BackgroundState.transitioning == false)
		{
			if (FlxG.mouse.overlaps(BackgroundState.buttonSkins))
			{
				if (playHoverSound == true)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'));
					playHoverSound = false;
				}
				BackgroundState.buttonSkins.setGraphicSize(Std.int(BackgroundState.buttonSkins.width * 1.06636501));
				if (FlxG.mouse.justPressed)
				{
					BackgroundState.buttonHome.loadGraphic(Paths.image('fallmen/UI/Menu/buttonMain'));
					BackgroundState.buttonSkins.loadGraphic(Paths.image('fallmen/UI/Menu/buttonSkinsSel'));
					BackgroundState.buttonSkins.setGraphicSize(Std.int(BackgroundState.buttonSkins.width * 1));
					selectedSomethin = true;
					BackgroundState.stayingOnMenu = true;
					menuTrans(1);
					FlxG.sound.play(Paths.sound('confirmMenu2'));
					if (ClientPrefs.menuTrans)
					{
						new FlxTimer().start(2, function(tmr:FlxTimer)
						{
							GFbopping.cancel();
							close();
							BackgroundState.curMenu = "Skins";
							BackgroundState.fadeBackground();
							BackgroundState.doneSwitching = false;
						});
					}
					else
					{
						GFbopping.cancel();
						close();
						BackgroundState.curMenu = "Skins";
						BackgroundState.fadeBackground();
						BackgroundState.doneSwitching = false;
					}
					BackgroundState.stayingOnMenu = false;
				}
			}
			else
			{
				BackgroundState.buttonSkins.setGraphicSize(Std.int(BackgroundState.buttonSkins.width * 1));
				
				if (FlxG.mouse.overlaps(BackgroundState.buttonOptions))
				{
					if (playHoverSound == true)
					{
						FlxG.sound.play(Paths.sound('scrollMenu'));
						playHoverSound = false;
					}
					BackgroundState.buttonOptions.setGraphicSize(Std.int(BackgroundState.buttonOptions.width * 1.06636501));
					if (FlxG.mouse.justPressed)
					{
						FlxG.mouse.visible = false;
						menuTrans(1);
						FlxG.sound.play(Paths.sound('confirmMenu2'));
						if (ClientPrefs.menuTrans)
						{
							new FlxTimer().start(2, function(tmr:FlxTimer)
							{
								GFbopping.cancel();
								close();
								BackgroundState.curMenu = "Settings";
								BackgroundState.fadeBackground();
								BackgroundState.doneSwitching = false;
							});
						}
						else
						{
							GFbopping.cancel();
							close();
							BackgroundState.curMenu = "Settings";
							BackgroundState.fadeBackground();
							BackgroundState.doneSwitching = false;
						}
					}
				}
				else
				{
					BackgroundState.buttonOptions.setGraphicSize(Std.int(BackgroundState.buttonOptions.width * 1));

					if (FlxG.mouse.overlaps(playShow) && showSelected == true)
					{
						playShow.x = 786;
						playShow.loadGraphic(Paths.image('fallmen/UI/Menu/Main/playSel ' + curSong));
						selectShow.x = 899;
						selectShow.loadGraphic(Paths.image('fallmen/UI/Menu/Main/selshow'));
						if (playHoverSound == true)
						{
							FlxG.sound.play(Paths.sound('scrollMenu'));
							playHoverSound = false;
						}
						if (FlxG.mouse.justPressed)
						{
							if (showSelected == false)
							{
								FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), 0.2);
								camGame.shake(0.005, 0.2);
								trace('no <3');
							}
							else
							{
								menuTrans(1);
								selectedSomethin = true;
								FlxG.mouse.visible = false;
								FlxG.sound.play(Paths.sound('confirmMenu'));
								FlxG.sound.music.fadeOut();
				
								if (ClientPrefs.menuTrans)
								{
									FlxTween.tween(coverscreen, {alpha: 1}, 1, {startDelay: 1, ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});
									new FlxTimer().start(2.1, function(tmr:FlxTimer)
									{
										BackgroundState.coverscreen.alpha = 1;
										GFbopping.cancel();
										trace(FreeplayState.universalPoop);
										PlayState.SONG = Song.loadFromJson(FreeplayState.universalPoop, FreeplayState.freeplaySongName.toLowerCase());
										PlayState.isStoryMode = false;
										PlayState.storyDifficulty = FreeplayState.curDifficulty;
										if (curSong == "better bean")
										{
											FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
											MusicBeatState.switchState(new BetterBeanSelState());
										}
										else
										{
											FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
											LoadingState.loadAndSwitchState(new PlayState());
										}
									});
								}
								else
								{
									FlxTween.tween(coverscreen, {alpha: 1}, 1, {startDelay: 0.5, ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});
									new FlxTimer().start(1.6, function(tmr:FlxTimer)
									{
										BackgroundState.coverscreen.alpha = 1;
										GFbopping.cancel();
										trace(FreeplayState.universalPoop);
										PlayState.SONG = Song.loadFromJson(FreeplayState.universalPoop, FreeplayState.freeplaySongName.toLowerCase());
										PlayState.isStoryMode = false;
										PlayState.storyDifficulty = FreeplayState.curDifficulty;
										if (curSong == "better bean")
										{
											MusicBeatState.switchState(new BetterBeanSelState());
										}
										else
										{
											LoadingState.loadAndSwitchState(new PlayState());
										}
									});
								}
							}
						}
					}
					else
					{
						playShow.x = 804;
						playShow.loadGraphic(Paths.image('fallmen/UI/Menu/Main/play ' + curSong));

						if (FlxG.mouse.overlaps(selectShow))
						{
							selectShow.x = 881;
							selectShow.loadGraphic(Paths.image('fallmen/UI/Menu/Main/selshowSel'));
							playShow.x = 804;
							playShow.loadGraphic(Paths.image('fallmen/UI/Menu/Main/play ' + curSong));
							if (playHoverSound == true)
							{
								FlxG.sound.play(Paths.sound('scrollMenu'));
								playHoverSound = false;
							}
							if (FlxG.mouse.justPressed)
							{
								FlxG.mouse.visible = false;
								selectedSomethin = true;
								FreeplayState.kudoXslide = true;
								menuTrans(1);
								FlxG.sound.play(Paths.sound('confirmMenu2'));
								if (ClientPrefs.menuTrans)
								{
									new FlxTimer().start(2, function(tmr:FlxTimer)
									{
										GFbopping.cancel();
										close();
										BackgroundState.curMenu = "Freeplay";
										BackgroundState.fadeBackground();
										BackgroundState.doneSwitching = false;
									});
								}
								else
								{
									GFbopping.cancel();
									close();
									BackgroundState.curMenu = "Freeplay";
									BackgroundState.fadeBackground();
									BackgroundState.doneSwitching = false;
								}
							}
						}
						else
						{
							selectShow.x = 899;
							selectShow.loadGraphic(Paths.image('fallmen/UI/Menu/Main/selshow'));
							playHoverSound = true;
						}
					}
				}
			}
			
			if (FlxG.keys.justPressed.RBRACKET)
			{
				BackgroundState.buttonHome.loadGraphic(Paths.image('fallmen/UI/Menu/buttonMain'));
				BackgroundState.buttonSkins.loadGraphic(Paths.image('fallmen/UI/Menu/buttonSkinsSel'));
				selectedSomethin = true;
				BackgroundState.stayingOnMenu = true;
				menuTrans(1);
				FlxG.sound.play(Paths.sound('confirmMenu2'));
				if (ClientPrefs.menuTrans)
				{
					new FlxTimer().start(2, function(tmr:FlxTimer)
					{
						GFbopping.cancel();
						close();
						BackgroundState.curMenu = "Skins";
						BackgroundState.fadeBackground();
						BackgroundState.doneSwitching = false;
					});
				}
				else
				{
					GFbopping.cancel();
					close();
					BackgroundState.curMenu = "Skins";
					BackgroundState.fadeBackground();
					BackgroundState.doneSwitching = false;
				}
				BackgroundState.stayingOnMenu = false;
			}
			
			if (FlxG.keys.justPressed.CONTROL)
			{
				selectShow.x = 881;
				selectShow.loadGraphic(Paths.image('fallmen/UI/Menu/Main/selshowSel'));
				FlxG.mouse.visible = false;
				FreeplayState.kudoXslide = true;
				menuTrans(1);
				FlxG.sound.play(Paths.sound('confirmMenu2'));
				if (ClientPrefs.menuTrans)
				{
					new FlxTimer().start(2, function(tmr:FlxTimer)
					{
						GFbopping.cancel();
						close();
						BackgroundState.curMenu = "Freeplay";
						BackgroundState.fadeBackground();
						BackgroundState.doneSwitching = false;
					});
				}
				else
				{
					GFbopping.cancel();
					close();
					BackgroundState.curMenu = "Freeplay";
					BackgroundState.fadeBackground();
					BackgroundState.doneSwitching = false;
				}
			}
			
			if (controls.BACK)
			{
				FlxG.mouse.visible = false;
				menuTrans(1);
				FlxG.sound.play(Paths.sound('confirmMenu2'));
				if (ClientPrefs.menuTrans)
				{
					new FlxTimer().start(2, function(tmr:FlxTimer)
					{
						GFbopping.cancel();
						close();
						BackgroundState.curMenu = "Settings";
						BackgroundState.fadeBackground();
						BackgroundState.doneSwitching = false;
					});
				}
				else
				{
					GFbopping.cancel();
					close();
					BackgroundState.curMenu = "Settings";
					BackgroundState.fadeBackground();
					BackgroundState.doneSwitching = false;
				}
			}

			if (controls.ACCEPT)
			{
				FlxG.mouse.visible = false;
				if (showSelected == false)
				{
					selectShow.x = 881;
					selectShow.loadGraphic(Paths.image('fallmen/UI/Menu/Main/selshowSel'));
					FreeplayState.kudoXslide = true;
					menuTrans(1);
					FlxG.sound.play(Paths.sound('confirmMenu2'));
					if (ClientPrefs.menuTrans)
					{
						new FlxTimer().start(2, function(tmr:FlxTimer)
						{
							GFbopping.cancel();
							close();
							BackgroundState.curMenu = "Freeplay";
							BackgroundState.fadeBackground();
							BackgroundState.doneSwitching = false;
						});
					}
					else
					{
						GFbopping.cancel();
						close();
						BackgroundState.curMenu = "Freeplay";
						BackgroundState.fadeBackground();
						BackgroundState.doneSwitching = false;
					}
				}
				else
				{
					playShow.x = 786;
					playShow.loadGraphic(Paths.image('fallmen/UI/Menu/Main/playSel ' + curSong));
					menuTrans(1);
					FreeplayState.kudoXslide = false;
					selectedSomethin = true;
					FlxG.mouse.visible = false;
					FlxG.sound.play(Paths.sound('confirmMenu'));
					FlxG.sound.music.fadeOut();
				
					if (ClientPrefs.menuTrans)
					{
						FlxTween.tween(coverscreen, {alpha: 1}, 1, {startDelay: 1, ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});
						new FlxTimer().start(2.1, function(tmr:FlxTimer)
						{
							BackgroundState.coverscreen.alpha = 1;
							GFbopping.cancel();
							trace(FreeplayState.universalPoop);
							PlayState.SONG = Song.loadFromJson(FreeplayState.universalPoop, FreeplayState.freeplaySongName.toLowerCase());
							PlayState.isStoryMode = false;
							PlayState.storyDifficulty = FreeplayState.curDifficulty;
							if (curSong == "better bean")
							{
								FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
								MusicBeatState.switchState(new BetterBeanSelState());
							}
							else
							{
								FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
								LoadingState.loadAndSwitchState(new PlayState());
							}
						});
					}
					else
					{
						FlxTween.tween(coverscreen, {alpha: 1}, 1, {startDelay: 0.5, ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});
						new FlxTimer().start(1.6, function(tmr:FlxTimer)
						{
							BackgroundState.coverscreen.alpha = 1;
							GFbopping.cancel();
							trace(FreeplayState.universalPoop);
							PlayState.SONG = Song.loadFromJson(FreeplayState.universalPoop, FreeplayState.freeplaySongName.toLowerCase());
							PlayState.isStoryMode = false;
							PlayState.storyDifficulty = FreeplayState.curDifficulty;
							if (curSong == "better bean")
							{
								FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
								MusicBeatState.switchState(new BetterBeanSelState());
							}
							else
							{
								FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
								LoadingState.loadAndSwitchState(new PlayState());
							}
						});
					}
				}
			}
		}

		super.update(elapsed);
	}
}
