package;

#if desktop
import Discord.DiscordClient;
import sys.thread.Thread;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.input.keyboard.FlxKey;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import haxe.Json;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end
import options.GraphicsSettingsSubState;
//import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.system.ui.FlxSoundTray;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.app.Application;
import openfl.Assets;

using StringTools;

typedef TitleData =
{
	titlex:Float,
	titley:Float,
	startx:Float,
	starty:Float,
	gfx:Float,
	gfy:Float,
	backgroundSprite:String,
	bpm:Int
}

class TitleState extends MusicBeatState
{
	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];

	public static var initialized:Bool = false;

	var coverscreen:FlxSprite;

	var phantomArcaded:Bool = false;

	var onSplashScreen:Bool = false;

	var credGroup:FlxGroup;
	var credTextStuff:Alphabet;
	var textGroup:FlxGroup;
	var ngSpr:FlxSprite;

	var splash:FlxSprite;
	var titleGuy:FlxSprite;
	var logo:FlxSprite;
	var titleText:FlxText;
	
	public var bg:FlxSprite;
	public var bgPattern:FlxSprite;
	public var bgPatternGroup:FlxTypedGroup<FlxSprite>;

	var wackyImage:FlxSprite;

	public static var mustUpdate:Bool = false;
	
	public static var updateVersion:String = '';
	public static var newUpdates:String = '';

	override public function create():Void
	{
		FlxG.autoPause = false;
		
		FlxG.mouse.visible = false;
		
		#if (hxvlc < "1.4.1")
		hxvlc.libvlc.Handle.init();
        #else
		hxvlc.util.Handle.init();
		#end

		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		// Just to load a mod on start up if ya got one. For mods that change the menu music and bg
		WeekData.loadTheFirstEnabledMod();
		
		//trace(path, FileSystem.exists(path));

		/*#if (polymod && !html5)
		if (sys.FileSystem.exists('mods/')) {
			var folders:Array<String> = [];
			for (file in sys.FileSystem.readDirectory('mods/')) {
				var path = haxe.io.Path.join(['mods/', file]);
				if (sys.FileSystem.isDirectory(path)) {
					folders.push(file);
				}
			}
			if(folders.length > 0) {
				polymod.Polymod.init({modRoot: "mods", dirs: folders});
			}
		}
		#end*/
		
		if(!closedState) {
			trace('checking for update');
			var http = new haxe.Http("https://raw.githubusercontent.com/Denoohay/fallin-source/main/gitFinalVersion.txt");
			
			http.onData = function (data:String)
			{
				updateVersion = data.split('\n')[0].trim();
				var curVersion:String = MainMenuState.fallinVersion.trim();
				trace('version online: ' + updateVersion + ', your version: ' + curVersion);
				if(updateVersion != curVersion)
				{
					trace('versions arent matching!');
					mustUpdate = true;
				}
			}
			
			http.onError = function (error) {
				trace('error: $error');
			}
			
			http.request();

			
			var httpTextFile = new haxe.Http("https://raw.githubusercontent.com/Denoohay/fallin-source/main/gitDemoVersionText.txt");
			
			httpTextFile.onData = function (data:String)
			{
				newUpdates = data.split('\n')[0].trim();
			}
			
			httpTextFile.onError = function (error)
			{
				trace('error: $error');
			}
			
			httpTextFile.request();
		}

		FlxG.game.focusLostFramerate = 60;
		FlxG.sound.muteKeys = muteKeys;
		FlxG.sound.volumeDownKeys = volumeDownKeys;
		FlxG.sound.volumeUpKeys = volumeUpKeys;
		FlxG.keys.preventDefaultKeys = [TAB];

		PlayerSettings.init();

		// DEBUG BULLSHIT

		super.create();

		FlxG.save.bind('funkin', 'ninjamuffin99');
		
		ClientPrefs.loadPrefs();
		
		Highscore.load();

		if(!initialized && FlxG.save.data != null && FlxG.save.data.fullscreen)
		{
			FlxG.fullscreen = FlxG.save.data.fullscreen;
			//trace('LOADED FULLSCREEN SETTING!!');
		}

		if (FlxG.save.data.weekCompleted != null)
		{
			StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;
		}

		FlxG.mouse.visible = false;
		#if FREEPLAY
		MusicBeatState.switchState(new FreeplayState());
		#elseif CHARTING
		MusicBeatState.switchState(new ChartingState());
		#else
		if(FlxG.save.data.HasPlayed != true)
		{
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			MusicBeatState.switchState(new FlashingState());
		} else {
			#if desktop
			if (!DiscordClient.isInitialized)
			{
				DiscordClient.initialize();
				Application.current.onExit.add (function (exitCode) {
					DiscordClient.shutdown();
				});
			}
			#end

			new FlxTimer().start(1, function(tmr:FlxTimer)
			{
				startIntro();
			});
		}
		#end
	}

	function startIntro()
	{
		if (!initialized)
		{
			/*var diamond:FlxGraphic = FlxGraphic.fromClass(GraphicTransTileDiamond);
			diamond.persist = true;
			diamond.destroyOnNoUse = false;

			FlxTransitionableState.defaultTransIn = new TransitionData(FADE, FlxColor.BLACK, 1, new FlxPoint(0, -1), {asset: diamond, width: 32, height: 32},
				new FlxRect(-300, -300, FlxG.width * 1.8, FlxG.height * 1.8));
			FlxTransitionableState.defaultTransOut = new TransitionData(FADE, FlxColor.BLACK, 0.7, new FlxPoint(0, 1),
				{asset: diamond, width: 32, height: 32}, new FlxRect(-300, -300, FlxG.width * 1.8, FlxG.height * 1.8));
				
			transIn = FlxTransitionableState.defaultTransIn;
			transOut = FlxTransitionableState.defaultTransOut;*/

			// HAD TO MODIFY SOME BACKEND SHIT
			// IF THIS PR IS HERE IF ITS ACCEPTED UR GOOD TO GO
			// https://github.com/HaxeFlixel/flixel-addons/pull/348

			// var music:FlxSound = new FlxSound();
			// music.loadStream(Paths.music('freakyMenu'));
			// FlxG.sound.list.add(music);
			// music.play();
		}

		Conductor.changeBPM(125);
		persistentUpdate = true;
		
		bg = new FlxSprite();
		bg.makeGraphic(FlxG.width, FlxG.height, 0xFFFFFFFF);
		bg.color = 0xFFFFC300;
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);

		bgPatternGroup = new FlxTypedGroup<FlxSprite>();
		add(bgPatternGroup);

		var currentY:Float = 0;
		var currentX:Float = 0;
		for (i in 0...40)
		{
			if (i == 0)
			{
				bgPattern = new FlxSprite(0, 0);
			}
			else
			{
				currentX = currentX + 160;
				bgPattern = new FlxSprite(currentX, currentY);
			}

			if (i == 8 || i == 16 || i == 24 || i == 32 || i == 40)
			{
				currentY = currentY + 160;
				currentX = 0;
				bgPattern = new FlxSprite(currentX, currentY);
			}
			bgPattern.makeGraphic(FlxG.width, FlxG.height, FlxColor.TRANSPARENT);
			bgPattern.loadGraphic(Paths.image('fallmen/UI/Menu/Skins/Patterns/default'));
			bgPattern.color = 0xFFFFD200;
			bgPattern.antialiasing = ClientPrefs.globalAntialiasing;
			bgPatternGroup.add(bgPattern);
			//trace(i + ' x:' + currentX + ', y:' + currentY);
		}

		logo = new FlxSprite(0, 0);
		logo.frames = Paths.getSparrowAtlas('fallmen/title/logo');
		logo.alpha = 0;
		logo.screenCenter();
		logo.antialiasing = ClientPrefs.globalAntialiasing;
		logo.animation.addByPrefix('start', "logo pop", 24, false);
		logo.updateHitbox();
		add(logo);

		splash = new FlxSprite(0, 0).loadGraphic(Paths.image('fallmen/title/splash'));
		splash.antialiasing = ClientPrefs.globalAntialiasing;
		splash.updateHitbox();
		add(splash);

		coverscreen = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		add(coverscreen);

		credGroup = new FlxGroup();
		add(credGroup);
		textGroup = new FlxGroup();

		credTextStuff = new Alphabet(0, 0, "", true);
		credTextStuff.screenCenter();

		// credTextStuff.alignment = CENTER;

		credTextStuff.visible = false;

		ngSpr = new FlxSprite(0, FlxG.height * 0.52).loadGraphic(Paths.image('newgrounds_logo'));
		add(ngSpr);
		ngSpr.visible = false;
		ngSpr.setGraphicSize(Std.int(ngSpr.width * 0.8));
		ngSpr.updateHitbox();
		ngSpr.screenCenter(X);
		ngSpr.antialiasing = ClientPrefs.globalAntialiasing;

		FlxTween.tween(credTextStuff, {y: credTextStuff.y + 20}, 2.9, {ease: FlxEase.quadInOut, type: PINGPONG});

		if (initialized)
			skipIntro();
		else
			initialized = true;

		// credGroup.add(credTextStuff);
	}

	var transitioning:Bool = false;
	var youcanpress:Bool = false;
	var textTransitioned:Bool = false;
	private static var playJingle:Bool = false;

	override function update(elapsed:Float)
	{
		FlxG.mouse.visible = false;

		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;
		// FlxG.watch.addQuick('amp', FlxG.sound.music.amplitude);

		if (FlxG.keys.justPressed.F)
		{
			FlxG.fullscreen = !FlxG.fullscreen;
		}

		if (FlxG.keys.justPressed.P)
		{
			phantomArcaded = true;
		}
		
		var pressedEnter:Bool = FlxG.keys.justPressed.ENTER || controls.ACCEPT;

		#if mobile
		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed)
			{
				pressedEnter = true;
			}
		}
		#end

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		if (gamepad != null)
		{
			if (gamepad.justPressed.START)
				pressedEnter = true;

			#if switch
			if (gamepad.justPressed.B)
				pressedEnter = true;
			#end
		}

		if (controls.ACCEPT && onSplashScreen == true)
		{
			onSplashScreen = false;
			FlxTween.tween(coverscreen, {alpha: 1}, 1, {ease: FlxEase.quadInOut,
			onComplete: function(twn:FlxTween)
				{
					splash.alpha = 0;

					new FlxTimer().start(0.5, function(tmr:FlxTimer)
					{
						FlxTween.tween(coverscreen, {alpha: 0}, 0.5, {ease: FlxEase.quadInOut});

						new FlxTimer().start(0.5, function(tmr:FlxTimer)
						{
							logo.alpha = 1;
							logo.animation.play('start');
							new FlxTimer().start(0.2, function(tmr:FlxTimer)
							{
								if (phantomArcaded == true)
								{
									FlxG.sound.play(Paths.sound('phantom_arcade_is_a_fall_guy'), 0.5);
								}
								FlxG.sound.play(Paths.sound('logoPop'), 0.5);
							});
							youcanpress = true;
						});
					});
				}
			});
		}

		if (initialized && !transitioning && skippedIntro && youcanpress == true)
		{
			if(pressedEnter)
			{
				if(titleText != null) titleText.animation.play('press');

				BackgroundState.transitionFromNonMenu = true;
				
				if (FlxG.save.data.kudosAHETSRYJDTUFKYGJLBVKJKGCYFILGKVJ == null)
				{
					FlxG.save.data.kudosAHETSRYJDTUFKYGJLBVKJKGCYFILGKVJ = 0;
				}
				if (FlxG.save.data.showbucksESTRDTYFUYGIUOHOIJKNBJHVCGUV == null)
				{
					FlxG.save.data.showbucksESTRDTYFUYGIUOHOIJKNBJHVCGUV = 0;
				}
				if (FlxG.save.data.fameSEASON1QWERTYUIOEJFNCJCSKCJSKNSKS == null)
				{
					FlxG.save.data.fameSEASON1QWERTYUIOEJFNCJCSKCJSKNSKS = 0;
				}
				if (FlxG.save.data.backgroundTheme == null)
				{
					FlxG.save.data.backgroundTheme = "default";
				}
				if (FlxG.save.data.backgroundTheme2 == null)
				{
					FlxG.save.data.backgroundTheme2 = "defaultBlue";
				}
				if (FlxG.save.data.nameplate == null)
				{
					FlxG.save.data.nameplate = "rookie";
				}
				if (FlxG.save.data.BFskin == null)
				{
					FlxG.save.data.BFskin = "";
				}
				if (FlxG.save.data.GFskin == null)
				{
					FlxG.save.data.GFskin = "";
				}
				if (FlxG.save.data.FGskin == null)
				{
					FlxG.save.data.FGskin = "";
				}
				
				if (FlxG.save.data.bf_default != 1)
				{
					FlxG.save.data.bf_default = 1;
				}
				if (FlxG.save.data.bf_og == null)
				{
					FlxG.save.data.bf_og = 0;
				}
				if (FlxG.save.data.bf_hotDog != 1)
				{
					FlxG.save.data.bf_hotDog = 1;
				}
				if (FlxG.save.data.bf_FgFan == null)
				{
					FlxG.save.data.bf_FgFan = 0;
				}
				if (FlxG.save.data.bf_pigeon == null)
				{
					FlxG.save.data.bf_pigeon = 0;
				}
				if (FlxG.save.data.bf_ninja == null)
				{
					FlxG.save.data.bf_ninja = 0;
				}
				if (FlxG.save.data.bf_fallguy == null)
				{
					FlxG.save.data.bf_fallguy = 0;
				}
				if (FlxG.save.data.bf_Gglizzy == null)
				{
					FlxG.save.data.bf_Gglizzy = 0;
				}
				if (FlxG.save.data.bf_winner == null)
				{
					FlxG.save.data.bf_winner = 0;
				}
				if (FlxG.save.data.bf_sus == null)
				{
					FlxG.save.data.bf_sus = 0;
				}
				
				if (FlxG.save.data.gf_nothing != 1)
				{
					FlxG.save.data.gf_nothing = 1;
				}
				if (FlxG.save.data.gf_default != 1)
				{
					FlxG.save.data.gf_default = 1;
				}
				if (FlxG.save.data.gf_og == null)
				{
					FlxG.save.data.gf_og = 0;
				}
				if (FlxG.save.data.gf_trackstar != 1)
				{
					FlxG.save.data.gf_trackstar = 1;
				}
				if (FlxG.save.data.gf_FgFan == null)
				{
					FlxG.save.data.gf_FgFan = 0;
				}
				if (FlxG.save.data.gf_fallguy == null)
				{
					FlxG.save.data.gf_fallguy = 0;
				}
				if (FlxG.save.data.gf_miku == null)
				{
					FlxG.save.data.gf_miku = 0;
				}
				if (FlxG.save.data.gf_robot == null)
				{
					FlxG.save.data.gf_robot = 0;
				}
				if (FlxG.save.data.gf_pegwin == null)
				{
					FlxG.save.data.gf_pegwin = 0;
				}
				if (FlxG.save.data.gf_hotDog == null)
				{
					FlxG.save.data.gf_hotDog = 0;
				}
				
				if (FlxG.save.data.fallguy_default != 1)
				{
					FlxG.save.data.fallguy_default = 1;
				}
				if (FlxG.save.data.fallguy_sonic == null)
				{
					FlxG.save.data.fallguy_sonic = 0;
				}
				if (FlxG.save.data.fallguy_longGuy == null)
				{
					FlxG.save.data.fallguy_longGuy = 0;
				}
				if (FlxG.save.data.fallguy_rookie == null)
				{
					FlxG.save.data.fallguy_rookie = 0;
				}
				if (FlxG.save.data.fallguy_hotDog == null)
				{
					FlxG.save.data.fallguy_hotDog = 0;
				}
				if (FlxG.save.data.fallguy_tankGuy == null)
				{
					FlxG.save.data.fallguy_tankGuy = 0;
				}
				if (FlxG.save.data.fallguy_sus == null)
				{
					FlxG.save.data.fallguy_sus = 0;
				}
				if (FlxG.save.data.fallguy_cheesus == null)
				{
					FlxG.save.data.fallguy_cheesus = 0;
				}
				if (FlxG.save.data.fallguy_furry == null)
				{
					FlxG.save.data.fallguy_furry = 0;
				}
				if (FlxG.save.data.fallguy_bolts == null)
				{
					FlxG.save.data.fallguy_bolts = 0;
				}
				if (FlxG.save.data.fallguy_plush == null)
				{
					FlxG.save.data.fallguy_plush = 0;
				}
				if (FlxG.save.data.fallguy_beta == null)
				{
					FlxG.save.data.fallguy_beta = 0;
				}
				if (FlxG.save.data.fallguy_demo == null)
				{
					FlxG.save.data.fallguy_demo = 0;
				}
				if (FlxG.save.data.fallguy_legacy1 == null)
				{
					FlxG.save.data.fallguy_legacy1 = 0;
				}
				if (FlxG.save.data.fallguy_legacy2 == null)
				{
					FlxG.save.data.fallguy_legacy2 = 0;
				}
				
				if (FlxG.save.data.nameplate_rookie != 1)
				{
					FlxG.save.data.nameplate_rookie = 1;
				}
				if (FlxG.save.data.nameplate_rainbow == null)
				{
					FlxG.save.data.nameplate_rainbow = 0;
				}
				if (FlxG.save.data.nameplate_fallguy == null)
				{
					FlxG.save.data.nameplate_fallguy = 0;
				}
				if (FlxG.save.data.nameplate_babyGlaggle == null)
				{
					FlxG.save.data.nameplate_babyGlaggle = 0;
				}
				if (FlxG.save.data.nameplate_tada == null)
				{
					FlxG.save.data.nameplate_tada = 0;
				}
				if (FlxG.save.data.nameplate_mic == null)
				{
					FlxG.save.data.nameplate_mic = 0;
				}
				if (FlxG.save.data.nameplate_pizza == null)
				{
					FlxG.save.data.nameplate_pizza = 0;
				}
				if (FlxG.save.data.nameplate_fire == null)
				{
					FlxG.save.data.nameplate_fire = 0;
				}
				if (FlxG.save.data.nameplate_donut == null)
				{
					FlxG.save.data.nameplate_donut = 0;
				}
				if (FlxG.save.data.nameplate_fame == null)
				{
					FlxG.save.data.nameplate_fame = 0;
				}
				if (FlxG.save.data.nameplate_heart == null)
				{
					FlxG.save.data.nameplate_heart = 0;
				}
				if (FlxG.save.data.nameplate_egg == null)
				{
					FlxG.save.data.nameplate_egg = 0;
				}
				if (FlxG.save.data.nameplate_cake == null)
				{
					FlxG.save.data.nameplate_cake = 0;
				}
				if (FlxG.save.data.nameplate_flower == null)
				{
					FlxG.save.data.nameplate_flower = 0;
				}
				if (FlxG.save.data.nameplate_star == null)
				{
					FlxG.save.data.nameplate_star = 0;
				}
				
				if (FlxG.save.data.background_default != 1)
				{
					FlxG.save.data.background_default = 1;
				}
				if (FlxG.save.data.background_defaultBlue != 1)
				{
					FlxG.save.data.background_defaultBlue = 1;
				}
				if (FlxG.save.data.background_fire == null)
				{
					FlxG.save.data.background_fire = 0;
				}
				if (FlxG.save.data.background_charge == null)
				{
					FlxG.save.data.background_charge = 0;
				}
				if (FlxG.save.data.background_gold == null)
				{
					FlxG.save.data.background_gold = 0;
				}
				if (FlxG.save.data.background_cyber == null)
				{
					FlxG.save.data.background_cyber = 0;
				}
				if (FlxG.save.data.background_flower == null)
				{
					FlxG.save.data.background_flower = 0;
				}
				if (FlxG.save.data.background_garden == null)
				{
					FlxG.save.data.background_garden = 0;
				}
				if (FlxG.save.data.background_rain == null)
				{
					FlxG.save.data.background_rain = 0;
				}
				if (FlxG.save.data.background_cherry == null)
				{
					FlxG.save.data.background_cherry = 0;
				}
				if (FlxG.save.data.background_fireworks == null)
				{
					FlxG.save.data.background_fireworks = 0;
				}
				if (FlxG.save.data.background_lovey == null)
				{
					FlxG.save.data.background_lovey = 0;
				}
				if (FlxG.save.data.background_shamrock == null)
				{
					FlxG.save.data.background_shamrock = 0;
				}
				if (FlxG.save.data.background_pastel == null)
				{
					FlxG.save.data.background_pastel = 0;
				}
				if (FlxG.save.data.background_bombPop == null)
				{
					FlxG.save.data.background_bombPop = 0;
				}
				if (FlxG.save.data.background_trifecta == null)
				{
					FlxG.save.data.background_trifecta = 0;
				}
				if (FlxG.save.data.background_birthday == null)
				{
					FlxG.save.data.background_birthday = 0;
				}
				if (FlxG.save.data.background_winner == null)
				{
					FlxG.save.data.background_winner = 0;
				}
				if (FlxG.save.data.background_spooky == null)
				{
					FlxG.save.data.background_spooky = 0;
				}
				if (FlxG.save.data.background_merry == null)
				{
					FlxG.save.data.background_merry = 0;
				}
				
				FlxG.save.data.VersionONEonluwcalmcfbngybrwewqrwetyuiopibvfjkgbvxzryincvnb = true;
				FlxG.save.data.HasPlayed = true;

				//exit state animations
				FlxG.mouse.visible = false;
				youcanpress = false;
				FlxG.camera.flash(FlxColor.WHITE, 1);
				FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
				coverscreen.alpha = 1;

				new FlxTimer().start(2, function(tmr:FlxTimer)
				{
					FlxG.autoPause = true;
					if (mustUpdate)
					{
						MusicBeatState.switchState(new OutdatedState());
					}
					else
					{
						MusicBeatState.switchStateSkip(new BackgroundState());
					}
					closedState = true;
				});
			}
			#if TITLE_SCREEN_EASTER_EGG
			else if (FlxG.keys.firstJustPressed() != FlxKey.NONE)
			{
				var keyPressed:FlxKey = FlxG.keys.firstJustPressed();
				var keyName:String = Std.string(keyPressed);
				if(allowedKeys.contains(keyName)) {
					easterEggKeysBuffer += keyName;
					if(easterEggKeysBuffer.length >= 32) easterEggKeysBuffer = easterEggKeysBuffer.substring(1);
					//trace('Test! Allowed Key pressed!!! Buffer: ' + easterEggKeysBuffer);

					for (wordRaw in easterEggKeys)
					{
						var word:String = wordRaw.toUpperCase(); //just for being sure you're doing it right
						if (easterEggKeysBuffer.contains(word))
						{
							//trace('YOOO! ' + word);
							if (FlxG.save.data.psychDevsEasterEgg == word)
								FlxG.save.data.psychDevsEasterEgg = '';
							else
								FlxG.save.data.psychDevsEasterEgg = word;
							FlxG.save.flush();

							FlxG.sound.play(Paths.sound('ToggleJingle'));

							var black:FlxSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
							black.alpha = 0;
							add(black);

							FlxTween.tween(black, {alpha: 1}, 1, {onComplete:
								function(twn:FlxTween) {
									FlxTransitionableState.skipNextTransIn = true;
									FlxTransitionableState.skipNextTransOut = true;
									MusicBeatState.switchState(new TitleState());
								}
							});
							FlxG.sound.music.fadeOut();
							closedState = true;
							transitioning = true;
							playJingle = true;
							easterEggKeysBuffer = '';
							break;
						}
					}
				}
			}
			#end
		}

		if (initialized)
		{
			skipIntro();
		}

		super.update(elapsed);
	}

	function createCoolText(textArray:Array<String>, ?offset:Float = 0)
	{
		for (i in 0...textArray.length)
		{
			var money:Alphabet = new Alphabet(0, 0, textArray[i], true, false);
			money.screenCenter(X);
			money.y += (i * 60) + 200 + offset;
			if(credGroup != null && textGroup != null) {
				credGroup.add(money);
				textGroup.add(money);
			}
		}
	}

	function addMoreText(text:String, ?offset:Float = 0)
	{
		if(textGroup != null && credGroup != null) {
			var coolText:Alphabet = new Alphabet(0, 0, text, true, false);
			coolText.screenCenter(X);
			coolText.y += (textGroup.length * 60) + 200 + offset;
			credGroup.add(coolText);
			textGroup.add(coolText);
		}
	}

	function deleteCoolText()
	{
		while (textGroup.members.length > 0)
		{
			credGroup.remove(textGroup.members[0], true);
			textGroup.remove(textGroup.members[0], true);
		}
	}

	private var sickBeats:Int = 0; //Basically curBeat but won't be skipped if you hold the tab or resize the screen
	public static var closedState:Bool = false;
	override function beatHit()
	{
		super.beatHit();

		if(logo != null) 
			logo.animation.play('bump', true);
			
		if(titleGuy != null)
			titleGuy.animation.play('bounce', true);
	}

	var skippedIntro:Bool = false;
	var increaseVolume:Bool = false;
	function skipIntro():Void
	{
		if (!skippedIntro)
		{
			if (playJingle) //Ignore deez
			{
				var easteregg:String = FlxG.save.data.psychDevsEasterEgg;
				if (easteregg == null) easteregg = '';
				easteregg = easteregg.toUpperCase();

				var sound:FlxSound = null;
				switch(easteregg)
				{
					case 'RIVER':
						sound = FlxG.sound.play(Paths.sound('JingleRiver'));
					case 'SHUBS':
						sound = FlxG.sound.play(Paths.sound('JingleShubs'));
					case 'SHADOW':
						FlxG.sound.play(Paths.sound('JingleShadow'));
					case 'BBPANZU':
						sound = FlxG.sound.play(Paths.sound('JingleBB'));
					
					default: //Go back to normal ugly ass boring GF
						remove(ngSpr);
						remove(credGroup);
						FlxG.camera.flash(FlxColor.WHITE, 2);
						skippedIntro = true;
						playJingle = false;
						return;
				}

				transitioning = true;
				if(easteregg == 'SHADOW')
				{
					new FlxTimer().start(3.2, function(tmr:FlxTimer)
					{
						remove(ngSpr);
						remove(credGroup);
						FlxG.camera.flash(FlxColor.WHITE, 0.6);
						transitioning = false;
					});
				}
				else
				{
					remove(ngSpr);
					remove(credGroup);
					FlxG.camera.flash(FlxColor.WHITE, 3);
					sound.onComplete = function() {
						transitioning = false;
					};
				}
				playJingle = false;
			}
			else //Default! Edit this one!!
			{
				//startup state animations
				onSplashScreen = true;
				FlxTween.tween(coverscreen, {alpha: 0}, 1, {ease: FlxEase.quadInOut,
				onComplete: function(twn:FlxTween)
					{
						new FlxTimer().start(2, function(tmr:FlxTimer)
						{
							if(onSplashScreen == true)
							{
								onSplashScreen = false;
								FlxTween.tween(coverscreen, {alpha: 1}, 1, {ease: FlxEase.quadInOut,
								onComplete: function(twn:FlxTween)
									{
										splash.alpha = 0;

										new FlxTimer().start(0.5, function(tmr:FlxTimer)
										{
											FlxTween.tween(coverscreen, {alpha: 0}, 0.5, {ease: FlxEase.quadInOut});

											new FlxTimer().start(0.5, function(tmr:FlxTimer)
											{
												logo.alpha = 1;
												logo.animation.play('start');
												new FlxTimer().start(0.2, function(tmr:FlxTimer)
												{
													if (phantomArcaded == true)
													{
														FlxG.sound.play(Paths.sound('phantom_arcade_is_a_fall_guy'), 0.5);
													}
													FlxG.sound.play(Paths.sound('logoPop'), 0.5);
												});
												youcanpress = true;
											});
										});
									}
								});
							}
						});
					}
				});
				remove(ngSpr);
				remove(credGroup);

				var easteregg:String = FlxG.save.data.psychDevsEasterEgg;
				if (easteregg == null) easteregg = '';
				easteregg = easteregg.toUpperCase();
				#if TITLE_SCREEN_EASTER_EGG
				if(easteregg == 'SHADOW')
				{
					FlxG.sound.music.fadeOut();
				}
				#end
			}
			skippedIntro = true;
		}
	}
}
