package;

import flixel.graphics.FlxGraphic;
#if desktop
import Discord.DiscordClient;
#end
import Section.SwagSection;
import Song.SwagSong;
import WiggleEffect.WiggleEffectType;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.FlxTrailArea;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import haxe.Json;
import lime.utils.Assets;
import openfl.Lib;
import openfl.display.BlendMode;
import openfl.display.StageQuality;
import openfl.filters.BitmapFilter;
import openfl.utils.Assets as OpenFlAssets;
import editors.ChartingState;
import editors.CharacterEditorState;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import Note.EventNote;
import openfl.events.KeyboardEvent;
import flixel.util.FlxSave;
import Achievements;
import StageData;
import FunkinLua;
import DialogueBoxPsych;
#if sys
import sys.FileSystem;
#end

#if hxvlc
import hxvlc.flixel.*;
import hxvlc.util.*;
#end

import mobile.TouchButton;
import mobile.TouchPad;
import mobile.input.MobileInputID;

using StringTools;

class PlayState extends MusicBeatState
{
	public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;

	public static var ratingStuff:Array<Dynamic> = [
		['You Suck!', 0.2], //From 0% to 19%
		['Awful', 0.4], //From 20% to 39%
		['Bad', 0.5], //From 40% to 49%
		['Bruh', 0.6], //From 50% to 59%
		['Meh', 0.69], //From 60% to 68%
		['Nice', 0.7], //69%
		['Good', 0.8], //From 70% to 79%
		['Great', 0.9], //From 80% to 89%
		['Sick!', 1], //From 90% to 99%
		['Perfect!!', 1] //The value on this one isn't used actually, since Perfect is always "1"
	];
	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var modchartSprites:Map<String, ModchartSprite> = new Map<String, ModchartSprite>();
	public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	public var modchartTexts:Map<String, ModchartText> = new Map<String, ModchartText>();
	public var modchartSaves:Map<String, FlxSave> = new Map<String, FlxSave>();
	//event variables
	private var isCameraOnForcedPos:Bool = false;
	#if (haxe >= "4.0.0")
	public var boyfriendMap:Map<String, Boyfriend> = new Map();
	public var dadMap:Map<String, Character> = new Map();
	public var gfMap:Map<String, Character> = new Map();
	#else
	public var boyfriendMap:Map<String, Boyfriend> = new Map<String, Boyfriend>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();
	#end

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";
	public var noteKillOffset:Float = 350;
	
	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;
	public static var curStage:String = '';
	public static var isPixelStage:Bool = false;
	public static var useFunkinUI:Bool = false;
	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	public var vocals:FlxSound;
	public var vocalsP2:FlxSound;

	public var dad:Character = null;
	public var gf:Character = null;
	public var boyfriend:Boyfriend = null;

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<EventNote> = [];

	private var strumLine:FlxSprite;
	
	public var healthDrain:Float = 0.023;

	var oppHealthDrain:Bool = false;
	var playAsOpp:Bool = false;
	public static var theBetterBean:String;

	public var coverscreen:FlxSprite;
	public var coverscreenW:FlxSprite;
	var coolBarTop:FlxSprite;
	var coolBarBottom:FlxSprite;

	var shortCircutsBlue:FlxSprite;
	var shortCircutsRed:FlxSprite;

	//Handles the new epic mega sexy cam code that i've done
	private var camFollow:FlxPoint;
	private var camFollowPos:FlxObject;
	private static var prevCamFollow:FlxPoint;
	private static var prevCamFollowPos:FlxObject;

	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var opponentStrums:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;
	
	public static var whirlyLeftGood:Bool = false;
	public static var whirlyDownGood:Bool = false;
	public static var whirlyUpGood:Bool = false;
	public static var whirlyRightGood:Bool = false;

	public var camZooming:Bool = false;
	private var curSong:String = "";

	public var gfSpeed:Int = 1;
	public var health:Float = 1;
	public var combo:Int = 0;

	private var healthBarBG:AttachedSprite;
	private var fallhealth:AttachedSprite;
	public var healthBar:FlxBar;
	var songPercent:Float = 0;

	private var timeBarBG:AttachedSprite;
	public var timeBar:FlxBar;
	public var falltime:FlxSprite;
	
	public var isSustainNote:Bool = false;
	public var susNoteMissed:Bool = false;
	public var missHealth:Float = 0.05;

	public var sicks:Int = 0;
	public var goods:Int = 0;
	public var bads:Int = 0;
	public var shits:Int = 0;
	
	private var generatedMusic:Bool = false;
	public var endingSong:Bool = false;
	public var startingSong:Bool = false;
	private var updateTime:Bool = true;
	public static var changedDifficulty:Bool = false;
	public static var chartingMode:Bool = false;

	//Gameplay settings
	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;
	public var instakillOnMiss:Bool = false;
	public var cpuControlled:Bool = false;
	public var practiceMode:Bool = false;

	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	public var cameraSpeed:Float = 1;

	var dialogue:Array<String> = ['blah blah blah', 'coolswag'];
	var dialogueJson:DialogueFile = null;

	var halloweenBG:BGSprite;
	var halloweenWhite:BGSprite;

	var phillyCityLights:FlxTypedGroup<BGSprite>;
	var phillyTrain:BGSprite;
	var blammedLightsBlack:ModchartSprite;
	var blammedLightsBlackTween:FlxTween;
	var phillyCityLightsEvent:FlxTypedGroup<BGSprite>;
	var phillyCityLightsEventTween:FlxTween;
	var trainSound:FlxSound;

	var limoKillingState:Int = 0;
	var limo:BGSprite;
	var limoMetalPole:BGSprite;
	var limoLight:BGSprite;
	var limoCorpse:BGSprite;
	var limoCorpseTwo:BGSprite;
	var bgLimo:BGSprite;
	var grpLimoParticles:FlxTypedGroup<BGSprite>;
	var grpLimoDancers:FlxTypedGroup<BackgroundDancer>;
	var fastCar:BGSprite;

	var fallinBackdrop:BGSprite;
	var logicBoppers:BGSprite;

	var bopped:Bool = false;

	var bopperCount:Int = 0;

	var upperBoppers:BGSprite;
	var bottomBoppers:BGSprite;
	var santa:BGSprite;
	var heyTimer:Float;

	var BFplayNoteAnims:Bool = true;
	var oppPlayNoteAnims:Bool = true;

	var bgGirls:BackgroundGirls;
	var wiggleShit:WiggleEffect = new WiggleEffect();
	var bgGhouls:BGSprite;

	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
	public var scoreTxt:FlxText;
	public var scoreTxtback:FlxText;
	var timeTxt:FlxText;
	var scoreTxtTween:FlxTween;
	
	public var losingVin:FlxSprite;
	public var losingVinTween:FlxTween;

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	public var defaultCamZoom:Float = 1.05;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;
	private var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public var inCutscene:Bool = false;
	public var skipCountdown:Bool = false;
	var songLength:Float = 0;

	public var boyfriendCameraOffset:Array<Float> = null;
	public var opponentCameraOffset:Array<Float> = null;
	public var girlfriendCameraOffset:Array<Float> = null;

	var medalType:String = "N/A";

	#if desktop
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	//Achievement shit
	var keysPressed:Array<Bool> = [];
	var boyfriendIdleTime:Float = 0.0;
	var boyfriendIdled:Bool = false;

	// Lua shit
	public static var instance:PlayState;
	public var luaArray:Array<FunkinLua> = [];
	private var luaDebugGroup:FlxTypedGroup<DebugLuaText>;
	public var introSoundsSuffix:String = '';

	// Debug buttons
	private var debugKeysChart:Array<FlxKey>;
	private var debugKeysCharacter:Array<FlxKey>;
	
	// Less laggy controls
	private var keysArray:Array<Dynamic>;

	override public function create()
	{
		FlxG.mouse.visible = false;

		Paths.clearStoredMemory();

		// for lua
		instance = this;

		debugKeysChart = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));
		debugKeysCharacter = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_2'));
		PauseSubState.songName = null; //Reset to default

		keysArray = [
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_left')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_down')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_up')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_right'))
		];

		// For the "Just the Two of Us" achievement
		for (i in 0...keysArray.length)
		{
			keysPressed.push(false);
		}

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain', 1);
		healthLoss = ClientPrefs.getGameplaySetting('healthloss', 1);
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill', false);
		practiceMode = ClientPrefs.getGameplaySetting('practice', false);
		cpuControlled = ClientPrefs.getGameplaySetting('botplay', false);

		// var gameCam:FlxCamera = FlxG.camera;
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camOther = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD);
		FlxG.cameras.add(camOther);
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();

		FlxCamera.defaultCameras = [camGame];
		CustomFadeTransition.nextCamera = camOther;
		//FlxG.cameras.setDefaultDrawTarget(camGame, true);

		persistentUpdate = true;
		persistentDraw = true;

		if (SONG == null)
			SONG = Song.loadFromJson('tutorial');

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		#if desktop
		storyDifficultyText = CoolUtil.difficulties[storyDifficulty];

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode)
		{
			detailsText = "Story Mode: " + WeekData.getCurrentWeek().weekName;
		}
		else
		{
			detailsText = "Freeplay";
		}

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		#end

		GameOverSubstate.resetVariables();
		var songName:String = Paths.formatToSongPath(SONG.song);

		curStage = PlayState.SONG.stage;
		trace('stage is: ' + curStage);
		if(PlayState.SONG.stage == null || PlayState.SONG.stage.length < 1) {
			switch (songName)
			{
				case 'spookeez' | 'south' | 'monster':
					curStage = 'spooky';
				case 'pico' | 'blammed' | 'philly' | 'philly-nice':
					curStage = 'philly';
				case 'milf' | 'satin-panties' | 'high':
					curStage = 'limo';
				case 'cocoa' | 'eggnog':
					curStage = 'mall';
				case 'winter-horrorland':
					curStage = 'mallEvil';
				case 'senpai' | 'roses':
					curStage = 'school';
				case 'thorns':
					curStage = 'schoolEvil';
				default:
					curStage = 'stage';
			}
		}

		var stageData:StageFile = StageData.getStageFile(curStage);
		if(stageData == null) { //Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = {
				directory: "",
				defaultZoom: 0.9,
				isPixelStage: false,
			
				boyfriend: [770, 100],
				girlfriend: [400, 130],
				opponent: [100, 100],
				hide_girlfriend: false,
			
				camera_boyfriend: [0, 0],
				camera_opponent: [0, 0],
				camera_girlfriend: [0, 0],
				camera_speed: 1
			};
		}

		defaultCamZoom = stageData.defaultZoom;
		isPixelStage = stageData.isPixelStage;
		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];

		if(stageData.camera_speed != null)
			cameraSpeed = stageData.camera_speed;

		boyfriendCameraOffset = stageData.camera_boyfriend;
		if(boyfriendCameraOffset == null) //Fucks sake should have done it since the start :rolling_eyes:
			boyfriendCameraOffset = [0, 0];

		opponentCameraOffset = stageData.camera_opponent;
		if(opponentCameraOffset == null)
			opponentCameraOffset = [0, 0];
		
		girlfriendCameraOffset = stageData.camera_girlfriend;
		if(girlfriendCameraOffset == null)
			girlfriendCameraOffset = [0, 0];

		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);

		switch (curStage)
		{
			case 'whirlygig':
				cameraSpeed = 0;
				defaultCamZoom = 0.6;
				isPixelStage = false;
				stageData.hide_girlfriend = false;

				boyfriendCameraOffset = [0, 0];
				girlfriendCameraOffset = [0, 0];
				opponentCameraOffset = [0, 0];

				fallinBackdrop = new BGSprite('fallmen/Stages/whirlygig', -1580, -810, 1, 1);
				fallinBackdrop.updateHitbox();
				fallinBackdrop.antialiasing = ClientPrefs.globalAntialiasing;
				add(fallinBackdrop);

			case 'slimeclimb':
				cameraSpeed = 0.7;
				defaultCamZoom = 0.5;
				isPixelStage = false;
				stageData.hide_girlfriend = false;

				boyfriendCameraOffset = [0, 0];
				girlfriendCameraOffset = [0, 0];
				opponentCameraOffset = [0, 0];

				fallinBackdrop = new BGSprite('fallmen/Stages/slimeclimb', -2400, -790, 1, 1);
				fallinBackdrop.updateHitbox();
				fallinBackdrop.antialiasing = ClientPrefs.globalAntialiasing;
				add(fallinBackdrop);

			case 'fallmountain':
				cameraSpeed = 0.6;
				defaultCamZoom = 0.3;
				isPixelStage = false;
				stageData.hide_girlfriend = false;

				boyfriendCameraOffset = [-400, 0];
				girlfriendCameraOffset = [0, 0];
				opponentCameraOffset = [0, 0];
				
				fallinBackdrop = new BGSprite('fallmen/Stages/fallmountain', -3300, -1530, 1, 1);
				fallinBackdrop.updateHitbox();
				fallinBackdrop.antialiasing = ClientPrefs.globalAntialiasing;
				add(fallinBackdrop);

				var fallCrown:BGSprite = new BGSprite('fallmen/Stages/fallmountain crown', -3300 + 3090, -1530 + 1590);
				fallCrown.setGraphicSize(Std.int(fallCrown.width * 1.5));
				fallCrown.antialiasing = ClientPrefs.globalAntialiasing;
				add(fallCrown);
				
				FlxTween.tween(fallCrown, {y: fallCrown.y - 400}, 4, {ease: FlxEase.quadInOut, type: PINGPONG});

			case 'spikyslopes':
				cameraSpeed = 1;
				defaultCamZoom = 0.6;
				isPixelStage = false;
				stageData.hide_girlfriend = false;

				boyfriendCameraOffset = [0, 0];
				girlfriendCameraOffset = [0, 0];
				opponentCameraOffset = [0, 0];
				
				fallinBackdrop = new BGSprite('fallmen/Stages/spikyslopes', -2520, -1520, 1, 1);
				fallinBackdrop.updateHitbox();
				fallinBackdrop.antialiasing = ClientPrefs.globalAntialiasing;
				add(fallinBackdrop);

			case 'blastball':
				cameraSpeed = 1;
				defaultCamZoom = 0.5;
				isPixelStage = false;
				stageData.hide_girlfriend = false;

				boyfriendCameraOffset = [0, 0];
				girlfriendCameraOffset = [0, 0];
				opponentCameraOffset = [0, 0];
				
				fallinBackdrop = new BGSprite('fallmen/Stages/blastball', -1840, -1150, 1, 1);
				fallinBackdrop.updateHitbox();
				fallinBackdrop.antialiasing = ClientPrefs.globalAntialiasing;
				add(fallinBackdrop);

				logicBoppers = new BGSprite('fallmen/Stages/blastballBoppers', -923, 74, 1, 1, ['logicBopping']);
				logicBoppers.updateHitbox();
				logicBoppers.antialiasing = ClientPrefs.globalAntialiasing;
				add(logicBoppers);

			case 'betterbean':
				cameraSpeed = 1/0;
				defaultCamZoom = 0.8;
				isPixelStage = false;
				stageData.hide_girlfriend = false;

				boyfriendCameraOffset = [0, 0];
				girlfriendCameraOffset = [0, 0];
				opponentCameraOffset = [0, 0];
				
				fallinBackdrop = new BGSprite('fallmen/Stages/betterbean', -295, 0, 1, 1);
				fallinBackdrop.updateHitbox();
				fallinBackdrop.antialiasing = ClientPrefs.globalAntialiasing;
				add(fallinBackdrop);

			case 'shortcircut':
				cameraSpeed = 1/0;
				defaultCamZoom = 0.5;
				isPixelStage = false;
				stageData.hide_girlfriend = false;
				boyfriendCameraOffset = [0, 0];
				girlfriendCameraOffset = [0, 0];
				opponentCameraOffset = [0, 0];
				
				fallinBackdrop = new BGSprite('fallmen/Stages/shortcircut', -870, -440, 1, 1);
				fallinBackdrop.updateHitbox();
				fallinBackdrop.antialiasing = ClientPrefs.globalAntialiasing;
				add(fallinBackdrop);

			case 'stage': //Week 1
				var bg:BGSprite = new BGSprite('stageback', -600, -200, 0.9, 0.9);
				add(bg);

				var stageFront:BGSprite = new BGSprite('stagefront', -650, 600, 0.9, 0.9);
				stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
				stageFront.updateHitbox();
				add(stageFront);
				if(!ClientPrefs.lowQuality) {
					var stageLight:BGSprite = new BGSprite('stage_light', -125, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					add(stageLight);
					var stageLight:BGSprite = new BGSprite('stage_light', 1225, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					stageLight.flipX = true;
					add(stageLight);

					var stageCurtains:BGSprite = new BGSprite('stagecurtains', -500, -300, 1.3, 1.3);
					stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
					stageCurtains.updateHitbox();
					add(stageCurtains);
				}

			case 'spooky': //Week 2
				if(!ClientPrefs.lowQuality) {
					halloweenBG = new BGSprite('halloween_bg', -200, -100, ['halloweem bg0', 'halloweem bg lightning strike']);
				} else {
					halloweenBG = new BGSprite('halloween_bg_low', -200, -100);
				}
				add(halloweenBG);

				halloweenWhite = new BGSprite(null, -FlxG.width, -FlxG.height, 0, 0);
				halloweenWhite.makeGraphic(Std.int(FlxG.width * 3), Std.int(FlxG.height * 3), FlxColor.WHITE);
				halloweenWhite.alpha = 0;
				halloweenWhite.blend = ADD;

				//PRECACHE SOUNDS
				CoolUtil.precacheSound('thunder_1');
				CoolUtil.precacheSound('thunder_2');

			case 'philly': //Week 3
				if(!ClientPrefs.lowQuality) {
					var bg:BGSprite = new BGSprite('philly/sky', -100, 0, 0.1, 0.1);
					add(bg);
				}
				
				var city:BGSprite = new BGSprite('philly/city', -10, 0, 0.3, 0.3);
				city.setGraphicSize(Std.int(city.width * 0.85));
				city.updateHitbox();
				add(city);

				phillyCityLights = new FlxTypedGroup<BGSprite>();
				add(phillyCityLights);

				for (i in 0...5)
				{
					var light:BGSprite = new BGSprite('philly/win' + i, city.x, city.y, 0.3, 0.3);
					light.visible = false;
					light.setGraphicSize(Std.int(light.width * 0.85));
					light.updateHitbox();
					phillyCityLights.add(light);
				}

				if(!ClientPrefs.lowQuality) {
					var streetBehind:BGSprite = new BGSprite('philly/behindTrain', -40, 50);
					add(streetBehind);
				}

				phillyTrain = new BGSprite('philly/train', 2000, 360);
				add(phillyTrain);

				trainSound = new FlxSound().loadEmbedded(Paths.sound('train_passes'));
				CoolUtil.precacheSound('train_passes');
				FlxG.sound.list.add(trainSound);

				var street:BGSprite = new BGSprite('philly/street', -40, 50);
				add(street);

			case 'limo': //Week 4
				var skyBG:BGSprite = new BGSprite('limo/limoSunset', -120, -50, 0.1, 0.1);
				add(skyBG);

				if(!ClientPrefs.lowQuality) {
					limoMetalPole = new BGSprite('gore/metalPole', -500, 220, 0.4, 0.4);
					add(limoMetalPole);

					bgLimo = new BGSprite('limo/bgLimo', -150, 480, 0.4, 0.4, ['background limo pink'], true);
					add(bgLimo);

					limoCorpse = new BGSprite('gore/noooooo', -500, limoMetalPole.y - 130, 0.4, 0.4, ['Henchmen on rail'], true);
					add(limoCorpse);

					limoCorpseTwo = new BGSprite('gore/noooooo', -500, limoMetalPole.y, 0.4, 0.4, ['henchmen death'], true);
					add(limoCorpseTwo);

					grpLimoDancers = new FlxTypedGroup<BackgroundDancer>();
					add(grpLimoDancers);

					for (i in 0...5)
					{
						var dancer:BackgroundDancer = new BackgroundDancer((370 * i) + 130, bgLimo.y - 400);
						dancer.scrollFactor.set(0.4, 0.4);
						grpLimoDancers.add(dancer);
					}

					limoLight = new BGSprite('gore/coldHeartKiller', limoMetalPole.x - 180, limoMetalPole.y - 80, 0.4, 0.4);
					add(limoLight);

					grpLimoParticles = new FlxTypedGroup<BGSprite>();
					add(grpLimoParticles);

					//PRECACHE BLOOD
					var particle:BGSprite = new BGSprite('gore/stupidBlood', -400, -400, 0.4, 0.4, ['blood'], false);
					particle.alpha = 0.01;
					grpLimoParticles.add(particle);
					resetLimoKill();

					//PRECACHE SOUND
					CoolUtil.precacheSound('dancerdeath');
				}

				limo = new BGSprite('limo/limoDrive', -120, 550, 1, 1, ['Limo stage'], true);

				fastCar = new BGSprite('limo/fastCarLol', -300, 160);
				fastCar.active = true;
				limoKillingState = 0;

			case 'mall': //Week 5 - Cocoa, Eggnog
				var bg:BGSprite = new BGSprite('christmas/bgWalls', -1000, -500, 0.2, 0.2);
				bg.setGraphicSize(Std.int(bg.width * 0.8));
				bg.updateHitbox();
				add(bg);

				if(!ClientPrefs.lowQuality) {
					upperBoppers = new BGSprite('christmas/upperBop', -240, -90, 0.33, 0.33, ['Upper Crowd Bob']);
					upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
					upperBoppers.updateHitbox();
					add(upperBoppers);

					var bgEscalator:BGSprite = new BGSprite('christmas/bgEscalator', -1100, -600, 0.3, 0.3);
					bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
					bgEscalator.updateHitbox();
					add(bgEscalator);
				}

				var tree:BGSprite = new BGSprite('christmas/christmasTree', 370, -250, 0.40, 0.40);
				add(tree);

				bottomBoppers = new BGSprite('christmas/bottomBop', -300, 140, 0.9, 0.9, ['Bottom Level Boppers Idle']);
				bottomBoppers.animation.addByPrefix('hey', 'Bottom Level Boppers HEY', 24, false);
				bottomBoppers.setGraphicSize(Std.int(bottomBoppers.width * 1));
				bottomBoppers.updateHitbox();
				add(bottomBoppers);

				var fgSnow:BGSprite = new BGSprite('christmas/fgSnow', -600, 700);
				add(fgSnow);

				santa = new BGSprite('christmas/santa', -840, 150, 1, 1, ['santa idle in fear']);
				add(santa);
				CoolUtil.precacheSound('Lights_Shut_off');

			case 'mallEvil': //Week 5 - Winter Horrorland
				var bg:BGSprite = new BGSprite('christmas/evilBG', -400, -500, 0.2, 0.2);
				bg.setGraphicSize(Std.int(bg.width * 0.8));
				bg.updateHitbox();
				add(bg);

				var evilTree:BGSprite = new BGSprite('christmas/evilTree', 300, -300, 0.2, 0.2);
				add(evilTree);

				var evilSnow:BGSprite = new BGSprite('christmas/evilSnow', -200, 700);
				add(evilSnow);

			case 'school': //Week 6 - Senpai, Roses
				var bgSky:BGSprite = new BGSprite('weeb/weebSky', 0, 0, 0.1, 0.1);
				add(bgSky);
				bgSky.antialiasing = false;

				var repositionShit = -200;

				var bgSchool:BGSprite = new BGSprite('weeb/weebSchool', repositionShit, 0, 0.6, 0.90);
				add(bgSchool);
				bgSchool.antialiasing = false;

				var bgStreet:BGSprite = new BGSprite('weeb/weebStreet', repositionShit, 0, 0.95, 0.95);
				add(bgStreet);
				bgStreet.antialiasing = false;

				var widShit = Std.int(bgSky.width * 6);
				if(!ClientPrefs.lowQuality) {
					var fgTrees:BGSprite = new BGSprite('weeb/weebTreesBack', repositionShit + 170, 130, 0.9, 0.9);
					fgTrees.setGraphicSize(Std.int(widShit * 0.8));
					fgTrees.updateHitbox();
					add(fgTrees);
					fgTrees.antialiasing = false;
				}

				var bgTrees:FlxSprite = new FlxSprite(repositionShit - 380, -800);
				bgTrees.frames = Paths.getPackerAtlas('weeb/weebTrees');
				bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
				bgTrees.animation.play('treeLoop');
				bgTrees.scrollFactor.set(0.85, 0.85);
				add(bgTrees);
				bgTrees.antialiasing = false;

				if(!ClientPrefs.lowQuality) {
					var treeLeaves:BGSprite = new BGSprite('weeb/petals', repositionShit, -40, 0.85, 0.85, ['PETALS ALL'], true);
					treeLeaves.setGraphicSize(widShit);
					treeLeaves.updateHitbox();
					add(treeLeaves);
					treeLeaves.antialiasing = false;
				}

				bgSky.setGraphicSize(widShit);
				bgSchool.setGraphicSize(widShit);
				bgStreet.setGraphicSize(widShit);
				bgTrees.setGraphicSize(Std.int(widShit * 1.4));

				bgSky.updateHitbox();
				bgSchool.updateHitbox();
				bgStreet.updateHitbox();
				bgTrees.updateHitbox();

				if(!ClientPrefs.lowQuality) {
					bgGirls = new BackgroundGirls(-100, 190);
					bgGirls.scrollFactor.set(0.9, 0.9);

					bgGirls.setGraphicSize(Std.int(bgGirls.width * daPixelZoom));
					bgGirls.updateHitbox();
					add(bgGirls);
				}

			case 'schoolEvil': //Week 6 - Thorns
				/*if(!ClientPrefs.lowQuality) { //Does this even do something?
					var waveEffectBG = new FlxWaveEffect(FlxWaveMode.ALL, 2, -1, 3, 2);
					var waveEffectFG = new FlxWaveEffect(FlxWaveMode.ALL, 2, -1, 5, 2);
				}*/
				var posX = 400;
				var posY = 200;
				if(!ClientPrefs.lowQuality) {
					var bg:BGSprite = new BGSprite('weeb/animatedEvilSchool', posX, posY, 0.8, 0.9, ['background 2'], true);
					bg.scale.set(6, 6);
					bg.antialiasing = false;
					add(bg);

					bgGhouls = new BGSprite('weeb/bgGhouls', -100, 190, 0.9, 0.9, ['BG freaks glitch instance'], false);
					bgGhouls.setGraphicSize(Std.int(bgGhouls.width * daPixelZoom));
					bgGhouls.updateHitbox();
					bgGhouls.visible = false;
					bgGhouls.antialiasing = false;
					add(bgGhouls);
				} else {
					var bg:BGSprite = new BGSprite('weeb/animatedEvilSchool_low', posX, posY, 0.8, 0.9);
					bg.scale.set(6, 6);
					bg.antialiasing = false;
					add(bg);
				}
		}

		// Shitty layering but whatev it works LOL
		if (curStage == 'limo')
			add(limo);
		
		if(curStage == 'spooky') {
			add(halloweenWhite);
		}

		#if LUA_ALLOWED
		luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
		luaDebugGroup.cameras = [camOther];
		add(luaDebugGroup);
		#end

		if(curStage == 'philly') {
			phillyCityLightsEvent = new FlxTypedGroup<BGSprite>();
			for (i in 0...5)
			{
				var light:BGSprite = new BGSprite('philly/win' + i, -10, 0, 0.3, 0.3);
				light.visible = false;
				light.setGraphicSize(Std.int(light.width * 0.85));
				light.updateHitbox();
				phillyCityLightsEvent.add(light);
			}
		}


		// "GLOBAL" SCRIPTS
		#if LUA_ALLOWED
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('scripts/')];

		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('scripts/'));
		if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/scripts/'));
		#end

		for (folder in foldersToCheck)
		{
			if(FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if(file.endsWith('.lua') && !filesPushed.contains(file))
					{
						luaArray.push(new FunkinLua(folder + file));
						filesPushed.push(file);
					}
				}
			}
		}
		#end
		

		// STAGE SCRIPTS
		#if (MODS_ALLOWED && LUA_ALLOWED)
		var doPush:Bool = false;
		var luaFile:String = 'stages/' + curStage + '.lua';
		if(FileSystem.exists(Paths.modFolders(luaFile))) {
			luaFile = Paths.modFolders(luaFile);
			doPush = true;
		} else {
			luaFile = Paths.getPreloadPath(luaFile);
			if(FileSystem.exists(luaFile)) {
				doPush = true;
			}
		}

		if(doPush) 
			luaArray.push(new FunkinLua(luaFile));
		#end

		if(!modchartSprites.exists('blammedLightsBlack')) { //Creates blammed light black fade in case you didn't make your own
			blammedLightsBlack = new ModchartSprite(FlxG.width * -0.5, FlxG.height * -0.5);
			blammedLightsBlack.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
			var position:Int = members.indexOf(gfGroup);
			if(members.indexOf(boyfriendGroup) < position) {
				position = members.indexOf(boyfriendGroup);
			} else if(members.indexOf(dadGroup) < position) {
				position = members.indexOf(dadGroup);
			}
			insert(position, blammedLightsBlack);

			blammedLightsBlack.wasAdded = true;
			modchartSprites.set('blammedLightsBlack', blammedLightsBlack);
		}
		if(curStage == 'philly') insert(members.indexOf(blammedLightsBlack) + 1, phillyCityLightsEvent);
		blammedLightsBlack = modchartSprites.get('blammedLightsBlack');
		blammedLightsBlack.alpha = 0.0;

		var gfVersion:String = SONG.gfVersion;
		if(gfVersion == null || gfVersion.length < 1) {
			switch (curStage)
			{
				case 'limo':
					gfVersion = 'gf-car';
				case 'mall' | 'mallEvil':
					gfVersion = 'gf-christmas';
				case 'school' | 'schoolEvil':
					gfVersion = 'gf-pixel';
				default:
					gfVersion = 'gf';
			}
			SONG.gfVersion = gfVersion; //Fix for the Chart Editor
		}

		switch(curStage)
		{
			case 'limo':
				resetFastCar();
				insert(members.indexOf(gfGroup) - 1, fastCar);
			
			case 'schoolEvil':
				var evilTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069); //nice
				insert(members.indexOf(dadGroup) - 1, evilTrail);
		}

		var file:String = Paths.json(songName + '/dialogue'); //Checks for json/Psych Engine dialogue
		if (OpenFlAssets.exists(file)) {
			dialogueJson = DialogueBoxPsych.parseDialogue(file);
		}

		var file:String = Paths.txt(songName + '/' + songName + 'Dialogue'); //Checks for vanilla/Senpai dialogue
		if (OpenFlAssets.exists(file)) {
			dialogue = CoolUtil.coolTextFile(file);
		}
		var doof:DialogueBox = new DialogueBox(false, dialogue);
		// doof.x += 70;
		// doof.y = FlxG.height * 0.5;
		doof.scrollFactor.set();
		doof.finishThing = startCountdown;
		doof.nextDialogueThing = startNextDialogue;
		doof.skipDialogueThing = skipDialogue;

		Conductor.songPosition = -5000;

		strumLine = new FlxSprite(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, 50).makeGraphic(FlxG.width, 10);
		if(ClientPrefs.downScroll) strumLine.y = FlxG.height - 150;
		strumLine.scrollFactor.set();

		var showTime:Bool = (ClientPrefs.timeBarType != 'Disabled');
		timeTxt = new FlxText(STRUM_X + (FlxG.width / 2) - 247 - 1, 19, 400, "", 32);
		timeTxt.scrollFactor.set();
		timeTxt.visible = showTime;
		timeTxt.antialiasing = ClientPrefs.globalAntialiasing;
		updateTime = showTime;
		
		if (curStage == 'shortcircut')
		{
			coolBarTop = new FlxSprite(0, 0).makeGraphic(1280, 170, FlxColor.BLACK);
			coolBarTop.cameras = [camHUD];
			add(coolBarTop);
			coolBarBottom = new FlxSprite(0, 550).makeGraphic(1280, 170, FlxColor.BLACK);
			coolBarBottom.cameras = [camHUD];
			add(coolBarBottom);
			
			shortCircutsBlue = new FlxSprite(44.9, 0);
			shortCircutsBlue.frames = Paths.getSparrowAtlas('fallmen/UI/circutsBlue');
			shortCircutsBlue.animation.addByPrefix('circutsBlue', 'circutsBlue', 24, false);
			shortCircutsBlue.alpha = 0;
			shortCircutsBlue.antialiasing = ClientPrefs.globalAntialiasing;
			shortCircutsBlue.cameras = [camHUD];
			shortCircutsBlue.updateHitbox();
			add(shortCircutsBlue);
			
			shortCircutsRed = new FlxSprite(44.9, 0);
			shortCircutsRed.frames = Paths.getSparrowAtlas('fallmen/UI/circutsRed');
			shortCircutsRed.animation.addByPrefix('circutsRed', 'circutsRed', 24, false);
			shortCircutsRed.alpha = 0;
			shortCircutsRed.antialiasing = ClientPrefs.globalAntialiasing;
			shortCircutsRed.cameras = [camHUD];
			shortCircutsRed.updateHitbox();
			add(shortCircutsRed);
		}

		falltime = new FlxSprite(1148, 8);
		falltime.frames = Paths.getSparrowAtlas('fallmen/UI/TimeBox');
		falltime.scale.set(0.666666667, 0.666666667);
		falltime.alpha = 0;
		falltime.visible = showTime;
		falltime.antialiasing = ClientPrefs.globalAntialiasing;
		falltime.animation.addByPrefix('nothing', 'nothing', 24, false);
		falltime.animation.play('nothing');
		falltime.updateHitbox();
		add(falltime);

		timeBarBG = new AttachedSprite('timeBar');
		timeBarBG.x = timeTxt.x;
		timeBarBG.y = timeTxt.y - 3 + (timeTxt.height / 4);
		timeBarBG.scrollFactor.set();
		timeBarBG.alpha = 0;
		timeBarBG.color = FlxColor.BLACK;
		timeBarBG.antialiasing = ClientPrefs.globalAntialiasing;
		timeBarBG.xAdd = -4;
		timeBarBG.yAdd = -4;
		add(timeBarBG);

		timeBar = new FlxBar(timeBarBG.x + 4, timeBarBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this,
			'songPercent', 0, 1);
		timeBar.scrollFactor.set();
		timeBar.createFilledBar(0xFF000000, 0xFFFFFFFF);
		timeBar.numDivisions = 800; //How much lag this causes?? Should i tone it down to idk, 400 or 200?
		timeBar.alpha = 0;
		timeBar.visible = showTime;
		timeBar.antialiasing = ClientPrefs.globalAntialiasing;
		timeBarBG.sprTracker = timeBar;
		add(timeBar);

		add(timeTxt);

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		add(strumLineNotes);
		add(grpNoteSplashes);

		if (!gfVersion.startsWith('bf'))
		{
			add(gfGroup);
		}

		if (!stageData.hide_girlfriend)
		{
			if (gfVersion.startsWith('bf'))
			{
				gf = new Character(0, 0, gfVersion, true);
			}
			else
			{
				gf = new Character(0, 0, gfVersion);
			}
			startCharacterPos(gf);
			gfGroup.add(gf);
			startCharacterLua(gf.curCharacter);
			//trace("my girlfriend: " + gf.curCharacter);
			if (gf.curCharacter.startsWith('bf'))
			{
				gfGroup.x = gfGroup.x + 336;
				gfGroup.y = gfGroup.y - 27;
			}
		}

		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);
		dadGroup.add(dad);
		startCharacterLua(dad.curCharacter);
		//trace("my father: " + dad.curCharacter);
		
		boyfriend = new Boyfriend(0, 0, SONG.player1);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);
		startCharacterLua(boyfriend.curCharacter);
		//trace("me: " + boyfriend.curCharacter);
		if (boyfriend.curCharacter.startsWith('gf'))
		{
			boyfriendGroup.x = boyfriendGroup.x - 336;
			boyfriendGroup.y = boyfriendGroup.y + 27;
		}
		
		var camPos:FlxPoint = new FlxPoint(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
		if(gf != null)
		{
			camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
			camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
		}

		if(dad.curCharacter.startsWith('gf')) {
			dad.setPosition(GF_X, GF_Y);
			if(gf != null)
				gf.visible = false;
		}

		var splash:NoteSplash = new NoteSplash(100, 100, 0);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.0;

		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();

		// startCountdown();

		#if !android
		addTouchPad("NONE", "P");
		addTouchPadCamera();
		touchPad.visible = true;
		#end
		addMobileControls();
		if (!ClientPrefs.controllerMode)
		{
		    mobileControls.onButtonDown.add(onButtonPress);
		    mobileControls.onButtonUp.add(onButtonRelease);
		}
		
		generateSong(SONG.song);
		#if LUA_ALLOWED
		for (notetype in noteTypeMap.keys())
		{
			var luaToLoad:String = Paths.modFolders('custom_notetypes/' + notetype + '.lua');
			if(FileSystem.exists(luaToLoad))
			{
				luaArray.push(new FunkinLua(luaToLoad));
			}
			else
			{
				luaToLoad = Paths.getPreloadPath('custom_notetypes/' + notetype + '.lua');
				if(FileSystem.exists(luaToLoad))
				{
					luaArray.push(new FunkinLua(luaToLoad));
				}
			}
		}
		for (event in eventPushedMap.keys())
		{
			var luaToLoad:String = Paths.modFolders('custom_events/' + event + '.lua');
			if(FileSystem.exists(luaToLoad))
			{
				luaArray.push(new FunkinLua(luaToLoad));
			}
			else
			{
				luaToLoad = Paths.getPreloadPath('custom_events/' + event + '.lua');
				if(FileSystem.exists(luaToLoad))
				{
					luaArray.push(new FunkinLua(luaToLoad));
				}
			}
		}
		#end
		noteTypeMap.clear();
		noteTypeMap = null;
		eventPushedMap.clear();
		eventPushedMap = null;

		// After all characters being loaded, it makes then invisible 0.01s later so that the player won't freeze when you change characters
		// add(strumLine);

		camFollow = new FlxPoint();
		camFollowPos = new FlxObject(0, 0, 1, 1);

		snapCamFollowToPos(camPos.x, camPos.y);
		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		if (prevCamFollowPos != null)
		{
			camFollowPos = prevCamFollowPos;
			prevCamFollowPos = null;
		}
		add(camFollowPos);

		trace('song is: ' + curSong);
		trace('difficulty is: ' + storyDifficulty);

		//ALL SPECIAL UI STUFF GOES DOWN HERE, SUPER MESSY BUT IT WORKS SO I DON'T CARE

		if (isPixelStage)
		{
			introSoundsSuffix = '-pixel';
		}

		if (useFunkinUI == false)
		{
			introSoundsSuffix = '-fall';
		}
		
		if(ClientPrefs.downScroll) FlxG.height * 0.9 + 45;

		if (useFunkinUI == false)
		{
			timeTxt.setFormat(Paths.font("fall.ttf"), 32, FlxColor.WHITE, LEFT);
			timeTxt.x = 1180;
			timeTxt.y = 17;
			timeTxt.size = 27;

			timeBarBG.visible = false;

			falltime.visible = showTime;
			timeBar.visible = false;
		}
		else
		{
			timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			if(ClientPrefs.downScroll) timeTxt.y = FlxG.height - 44;
			timeTxt.alpha = 0;
			timeTxt.borderSize = 2;
			
			timeBarBG.visible = showTime;
			falltime.visible = false;
		}

		if(ClientPrefs.timeBarType == 'Song Name' && useFunkinUI == true)
		{
			timeTxt.text = SONG.song;
		}

		if(ClientPrefs.timeBarType == 'Song Name' && useFunkinUI == true)
		{
			timeTxt.size = 24;
			timeTxt.y += 3;
		}
		updateTime = showTime;

		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow);

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;
		moveCameraSection(0);
		
		add(boyfriendGroup);
		if (gfVersion.startsWith('bf'))
		{
			add(gfGroup);
		}
		add(dadGroup);

		if (FlxG.save.data.GFskin == 'fallguy' && curStage == 'fallmountain')
		{
			boyfriendGroup.x = boyfriendGroup.x + 200;
			gfGroup.x = gfGroup.x + 200;
			boyfriendCameraOffset = [-600, 0];
		}

		if (curSong == "Short Circut")
		{
			boyfriendGroup.color = 0xFF989CB7;
			gfGroup.color = 0xFF989CB7;
		}

		fallhealth = new AttachedSprite('fallmen/UI/fallHealth');
		fallhealth.y = 637;
		fallhealth.screenCenter(X);
		fallhealth.scrollFactor.set();
		fallhealth.visible = !ClientPrefs.hideHud;
		fallhealth.alpha = 0;
		if(ClientPrefs.downScroll) fallhealth.y = 76;

		healthBarBG = new AttachedSprite('healthBar');
		healthBarBG.y = FlxG.height * 0.89;
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		if (useFunkinUI == false)
		{
			healthBarBG.visible = false;
		}
		else
		{
			healthBarBG.visible = !ClientPrefs.hideHud;
		}
		healthBarBG.xAdd = -4;
		healthBarBG.yAdd = -4;
		healthBarBG.alpha = 0;
		add(healthBarBG);
		if(ClientPrefs.downScroll) healthBarBG.y = 0.11 * FlxG.height;

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'health', 0, 2);
		healthBar.scrollFactor.set();
		// healthBar
		healthBar.visible = !ClientPrefs.hideHud;
		healthBar.alpha = 0;

		add(healthBar);
		healthBarBG.sprTracker = healthBar;
		
		if (useFunkinUI == false)
		{
			add(fallhealth);
		}

		iconP1 = new HealthIcon(boyfriend.healthIcon, true);
		iconP1.y = healthBar.y - 75;
		iconP1.visible = !ClientPrefs.hideHud;
		iconP1.alpha = 0;
		add(iconP1);

		iconP2 = new HealthIcon(dad.healthIcon, false);
		iconP2.y = healthBar.y - 75;
		iconP2.visible = !ClientPrefs.hideHud;
		iconP2.alpha = 0;
		add(iconP2);
		reloadHealthBarColors();
		
		scoreTxtback = new FlxText(3, fallhealth.y + 44, FlxG.width, "", 20);
		scoreTxtback.setFormat(Paths.font("fall.ttf"), 20, 0xFF1E1D22, CENTER, FlxTextBorderStyle.OUTLINE, 0xFF1E1D22);
		scoreTxtback.borderSize = 1.2;
		scoreTxtback.scrollFactor.set();
		scoreTxtback.antialiasing = ClientPrefs.globalAntialiasing;
		scoreTxtback.alpha = 0;
		add(scoreTxtback);

		if (useFunkinUI == false)
		{
			scoreTxtback.visible = !ClientPrefs.hideHud;

			scoreTxt = new FlxText(0, fallhealth.y + 42, FlxG.width, "", 20);
			scoreTxt.setFormat(Paths.font("fall.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, 0xFF8A2EDB);
			scoreTxt.borderSize = 1.2;
		}
		else
		{
			scoreTxtback.visible = false;

			scoreTxt = new FlxText(0, healthBarBG.y + 36, FlxG.width, "", 20);
			scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			scoreTxt.borderSize = 1.25;
		}
		scoreTxt.scrollFactor.set();
		scoreTxt.visible = !ClientPrefs.hideHud;
		scoreTxt.antialiasing = ClientPrefs.globalAntialiasing;
		scoreTxt.alpha = 0;
		add(scoreTxt);

		botplayTxt = new FlxText(400, timeBarBG.y + 55, FlxG.width - 800, "BOTPLAY", 32);
		botplayTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = cpuControlled;
		botplayTxt.alpha = 1;
		botplayTxt.antialiasing = ClientPrefs.globalAntialiasing;
		add(botplayTxt);
		if(ClientPrefs.downScroll) {
			botplayTxt.y = timeBarBG.y - 78;
		}

		notes = new FlxTypedGroup<Note>();
		add(notes);

		losingVin = new FlxSprite().loadGraphic(Paths.image('fallmen/UI/losing'));
		losingVin.alpha = 0;
		losingVin.antialiasing = ClientPrefs.globalAntialiasing;
		losingVin.updateHitbox();
		add(losingVin);

		coverscreen = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		coverscreen.alpha = 0;
		add(coverscreen);

		coverscreenW = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.WHITE);
		coverscreenW.alpha = 0;
		add(coverscreenW);

		strumLineNotes.cameras = [camHUD];
		grpNoteSplashes.cameras = [camHUD];
		notes.cameras = [camHUD];
		healthBar.cameras = [camHUD];
		healthBarBG.cameras = [camHUD];
		fallhealth.cameras = [camHUD];
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		scoreTxt.cameras = [camHUD];
		scoreTxtback.cameras = [camHUD];
		botplayTxt.cameras = [camHUD];
		timeBar.cameras = [camHUD];
		timeBarBG.cameras = [camHUD];
		timeTxt.cameras = [camHUD];
		coverscreen.cameras = [camHUD];
		coverscreenW.cameras = [camHUD];
		doof.cameras = [camHUD];
		falltime.cameras = [camHUD];
		losingVin.cameras = [camHUD];

		// if (SONG.song == 'South')
		// FlxG.camera.alpha = 0.7;
		// UI_camera.zoom = 1;

		// cameras = [FlxG.cameras.list[1]];
		startingSong = true;

		BackgroundState.transitionFromNonMenu = true;

		// SONG SPECIFIC SCRIPTS
		#if LUA_ALLOWED
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('data/' + Paths.formatToSongPath(SONG.song) + '/')];

		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('data/' + Paths.formatToSongPath(SONG.song) + '/'));
		if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/data/' + Paths.formatToSongPath(SONG.song) + '/'));
		#end

		for (folder in foldersToCheck)
		{
			if(FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if(file.endsWith('.lua') && !filesPushed.contains(file))
					{
						luaArray.push(new FunkinLua(folder + file));
						filesPushed.push(file);
					}
				}
			}
		}
		#end
		
		//START OF SONG ACTIONS

		if (curSong == "Better Bean" || curSong == "Splash Zone" || curSong == "Logic Funkin Collab")
		{
			oppHealthDrain = true;

			if (curSong == "Splash Zone" || curSong == "Logic Funkin Collab")
			{
				healthDrain = 0.01;
			}
			else
			{
				healthDrain = 0.023;
			}
		}

		if (playAsOpp == true)
		{
			healthBar.flipX = true;
			reloadHealthBarColors();
		}

		if (curSong == 'Better Bean')
		{
			coverscreen.alpha = 1;
		}
		if (curSong == 'Short Circut')
		{
			coverscreen.alpha = 1;
		}
		
		if (curSong == 'Free Falling')
		{
			FlxG.save.data.freefalling = true;
		}
		if (curSong == 'Splash Zone')
		{
			FlxG.save.data.splashzone = true;
		}
		if (curSong == 'Royal Rumble')
		{
			FlxG.save.data.royalrumble = true;
		}
		if (curSong == 'Stringbean')
		{
			FlxG.save.data.stringbean = true;
		}
		if (curSong == 'Logic Funkin Collab')
		{
			FlxG.save.data.logicfunkincollab = true;
		}
		if (curSong == 'Better Bean')
		{
			FlxG.save.data.betterbean = true;
		}
		if (curSong == 'Short Circut')
		{
			FlxG.save.data.shortcircut = true;
		}

		var daSong:String = Paths.formatToSongPath(curSong);
		if (isStoryMode && !seenCutscene)
		{
			switch (daSong)
			{
				case "monster":
					var whiteScreen:FlxSprite = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.WHITE);
					add(whiteScreen);
					whiteScreen.scrollFactor.set();
					whiteScreen.blend = ADD;
					camHUD.visible = false;
					snapCamFollowToPos(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
					inCutscene = true;

					FlxTween.tween(whiteScreen, {alpha: 0}, 1, {
						startDelay: 0.1,
						ease: FlxEase.linear,
						onComplete: function(twn:FlxTween)
						{
							camHUD.visible = true;
							remove(whiteScreen);
							startCountdown();
						}
					});
					FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
					if(gf != null) gf.playAnim('scared', true);
					boyfriend.playAnim('scared', true);

				case "winter-horrorland":
					var blackScreen:FlxSprite = new FlxSprite().makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
					add(blackScreen);
					blackScreen.scrollFactor.set();
					camHUD.visible = false;
					inCutscene = true;

					FlxTween.tween(blackScreen, {alpha: 0}, 0.7, {
						ease: FlxEase.linear,
						onComplete: function(twn:FlxTween) {
							remove(blackScreen);
						}
					});
					FlxG.sound.play(Paths.sound('Lights_Turn_On'));
					snapCamFollowToPos(400, -2050);
					FlxG.camera.focusOn(camFollow);
					FlxG.camera.zoom = 1.5;

					new FlxTimer().start(0.8, function(tmr:FlxTimer)
					{
						camHUD.visible = true;
						remove(blackScreen);
						FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 2.5, {
							ease: FlxEase.quadInOut,
							onComplete: function(twn:FlxTween)
							{
								startCountdown();
							}
						});
					});
				case 'senpai' | 'roses' | 'thorns':
					if(daSong == 'roses') FlxG.sound.play(Paths.sound('ANGRY'));
					schoolIntro(doof);

				default:
					startCountdown();
			}
			seenCutscene = true;
		}
		else if (!seenCutscene)
		{
			switch (daSong)
			{
				default:
					startCountdown();
			}
			seenCutscene = true;
		}
		else
		{
			startCountdown();
		}
		RecalculateRating();

		//PRECACHING MISS SOUNDS BECAUSE I THINK THEY CAN LAG PEOPLE AND FUCK THEM UP IDK HOW HAXE WORKS
		if(ClientPrefs.hitsoundVolume > 0) CoolUtil.precacheSound('hitsound');
		CoolUtil.precacheSound('missnote1');
		CoolUtil.precacheSound('missnote2');
		CoolUtil.precacheSound('missnote3');

		if (PauseSubState.songName != null) {
			CoolUtil.precacheMusic(PauseSubState.songName);
		} else if(ClientPrefs.pauseMusic != 'None') {
			CoolUtil.precacheMusic(Paths.formatToSongPath(ClientPrefs.pauseMusic));
		}

		#if desktop
		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end

		if(!ClientPrefs.controllerMode)
		{
			FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}

		Conductor.safeZoneOffset = (ClientPrefs.safeFrames / 60) * 1000;
		callOnLuas('onCreatePost', []);

		super.create();

		Paths.clearUnusedMemory();
		CustomFadeTransition.nextCamera = camOther;
	}

	function set_songSpeed(value:Float):Float
	{
		if(generatedMusic)
		{
			var ratio:Float = value / songSpeed; //funny word huh
			for (note in notes)
			{
				if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end'))
				{
					note.scale.y *= ratio;
					note.updateHitbox();
				}
			}
			for (note in unspawnNotes)
			{
				if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end'))
				{
					note.scale.y *= ratio;
					note.updateHitbox();
				}
			}
		}
		songSpeed = value;
		noteKillOffset = 350 / songSpeed;
		return value;
	}

	public function addTextToDebug(text:String) {
		#if LUA_ALLOWED
		luaDebugGroup.forEachAlive(function(spr:DebugLuaText) {
			spr.y += 20;
		});

		if(luaDebugGroup.members.length > 34) {
			var blah = luaDebugGroup.members[34];
			blah.destroy();
			luaDebugGroup.remove(blah);
		}
		luaDebugGroup.insert(0, new DebugLuaText(text, luaDebugGroup));
		#end
	}

	public function reloadHealthBarColors()
	{
		if (playAsOpp == true)
		{
			healthBar.createFilledBar(FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]),
			FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]));
		}
		else
		{
			healthBar.createFilledBar(FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]),
			FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]));
		}
			
		healthBar.updateBar();
	}

	public function addCharacterToList(newCharacter:String, type:Int) {
		switch(type) {
			case 0:
				if(!boyfriendMap.exists(newCharacter)) {
					var newBoyfriend:Boyfriend = new Boyfriend(0, 0, newCharacter);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					startCharacterLua(newBoyfriend.curCharacter);
				}

			case 1:
				if(!dadMap.exists(newCharacter)) {
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha = 0.00001;
					startCharacterLua(newDad.curCharacter);
				}

			case 2:
				if(gf != null && !gfMap.exists(newCharacter)) {
					var newGf:Character = new Character(0, 0, newCharacter);
					newGf.scrollFactor.set(0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.alpha = 0.00001;
					startCharacterLua(newGf.curCharacter);
				}
		}
	}

	function startCharacterLua(name:String)
	{
		#if LUA_ALLOWED
		var doPush:Bool = false;
		var luaFile:String = 'characters/' + name + '.lua';
		if(FileSystem.exists(Paths.modFolders(luaFile))) {
			luaFile = Paths.modFolders(luaFile);
			doPush = true;
		} else {
			luaFile = Paths.getPreloadPath(luaFile);
			if(FileSystem.exists(luaFile)) {
				doPush = true;
			}
		}
		
		if(doPush)
		{
			for (lua in luaArray)
			{
				if(lua.scriptName == luaFile) return;
			}
			luaArray.push(new FunkinLua(luaFile));
		}
		#end
	}
	
	function startCharacterPos(char:Character, ?gfCheck:Bool = false) {
		if(gfCheck && char.curCharacter.startsWith('gf')) { //IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
			char.danceEveryNumBeats = 2;
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}



	private function popUpScore(note:Note = null):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.ratingOffset);
		//trace(noteDiff, ' ' + Math.abs(note.strumTime - Conductor.songPosition));

		// boyfriend.playAnim('hey');
		vocals.volume = 1;
		vocalsP2.volume = 1;

		var placement:String = Std.string(combo);

		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.35;
		//

		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		//tryna do MS based judgment due to popular demand
		var daRating:String = Conductor.judgeNote(note, noteDiff);

		switch (daRating)
		{
			case "shit": // shit
				totalNotesHit += 0;
				note.ratingMod = 0;
				score = 50;
				if(!note.ratingDisabled) shits++;
			case "bad": // bad
				totalNotesHit += 0.5;
				note.ratingMod = 0.5;
				score = 100;
				if(!note.ratingDisabled) bads++;
			case "good": // good
				totalNotesHit += 0.75;
				note.ratingMod = 0.75;
				score = 200;
				if(!note.ratingDisabled) goods++;
			case "sick": // sick
				totalNotesHit += 1;
				note.ratingMod = 1;
				if(!note.ratingDisabled) sicks++;
		}
		note.rating = daRating;

		if(daRating == 'sick' && !note.noteSplashDisabled)
		{
			spawnNoteSplashOnNote(note);
		}

		if(!practiceMode && !cpuControlled) {
			songScore += score;
			if(!note.ratingDisabled)
			{
				songHits++;
				totalPlayed++;
				RecalculateRating();
			}

			if(ClientPrefs.scoreZoom && useFunkinUI == true)
			{
				if(scoreTxtTween != null) {
					scoreTxtTween.cancel();
				}
				scoreTxt.scale.x = 1.075;
				scoreTxt.scale.y = 1.075;
				scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2, {
					onComplete: function(twn:FlxTween) {
						scoreTxtTween = null;
					}
				});
			}
		}

		/* if (combo > 60)
				daRating = 'sick';
			else if (combo > 12)
				daRating = 'good'
			else if (combo > 4)
				daRating = 'bad';
		 */

		var pixelShitPart1:String = "";
		var pixelShitPart2:String = '';
		var pixelShitPart3:String = '';

		if (isPixelStage)
		{
			pixelShitPart1 = 'pixelUI/';
			pixelShitPart2 = '-pixel';
			pixelShitPart3 = 'pixelUI/';
		}

		if (useFunkinUI == false)
		{
			pixelShitPart1 = 'fallmen/UI/';
			pixelShitPart2 = '';
			pixelShitPart3 = 'fallmen/UI/';
		}

		rating.loadGraphic(Paths.image(pixelShitPart1 + daRating + pixelShitPart2));
		rating.screenCenter();
		rating.x = coolText.x - 40;
		rating.y -= 60;
		rating.acceleration.y = 550;
		rating.setGraphicSize(Std.int(rating.width * 2.5));
		rating.velocity.y -= FlxG.random.int(140, 175);
		rating.velocity.x -= FlxG.random.int(0, 10);
		if (curStage == 'theRing')
		{
			rating.visible = false;
		}
		else
		{
			rating.visible = (!ClientPrefs.hideHud && showRating);
		}
		rating.x += 800 + ClientPrefs.comboOffset[0];
		rating.y -= -30 + ClientPrefs.comboOffset[1];

		var comboSpr:FlxSprite = new FlxSprite();
		comboSpr.screenCenter();
		comboSpr.x = coolText.x;
		comboSpr.acceleration.y = 600;
		comboSpr.setGraphicSize(Std.int(comboSpr.width * 2.5));
		comboSpr.velocity.y -= 150;
		if (curStage == 'theRing')
		{
			comboSpr.visible = false;
		}
		else
		{
			comboSpr.visible = (!ClientPrefs.hideHud && showCombo);
		}
		comboSpr.x += 800 + ClientPrefs.comboOffset[0];
		comboSpr.y -= -30 + ClientPrefs.comboOffset[1];


		comboSpr.velocity.x += FlxG.random.int(1, 10);
		insert(members.indexOf(strumLineNotes), rating);

		if (!PlayState.isPixelStage)
		{
			rating.setGraphicSize(Std.int(rating.width * 0.7));
			rating.antialiasing = ClientPrefs.globalAntialiasing;
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
			comboSpr.antialiasing = ClientPrefs.globalAntialiasing;
		}
		else
		{
			rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.85));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.85));
		}

		comboSpr.updateHitbox();
		rating.updateHitbox();

		var seperatedScore:Array<Int> = [];

		if(combo >= 1000) {
			seperatedScore.push(Math.floor(combo / 1000) % 10);
		}
		seperatedScore.push(Math.floor(combo / 100) % 10);
		seperatedScore.push(Math.floor(combo / 10) % 10);
		seperatedScore.push(combo % 10);

		var daLoop:Int = 0;
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart3 + 'num' + Std.int(i) + pixelShitPart2));
			numScore.screenCenter();
			numScore.x = coolText.x + (43 * daLoop) - 90;
			numScore.y += 80;
			numScore.setGraphicSize(Std.int(numScore.width * 2.5));

			numScore.x += 800 + ClientPrefs.comboOffset[2];
			numScore.y -= -30 + ClientPrefs.comboOffset[3];

			if (!PlayState.isPixelStage)
			{
				numScore.antialiasing = ClientPrefs.globalAntialiasing;
				numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			}
			else
			{
				numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
			}
			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300);
			numScore.velocity.y -= FlxG.random.int(140, 160);
			numScore.velocity.x = FlxG.random.float(-5, 5);
			if (curStage == 'theRing')
			{
				numScore.visible = false;
			}
			else
			{
				numScore.visible = !ClientPrefs.hideHud;
			}

			//if (combo >= 10 || combo == 0)
				insert(members.indexOf(strumLineNotes), numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: 222 * 0.002
			});

			daLoop++;
		}
		/* 
			trace(combo);
			trace(seperatedScore);
		 */

		coolText.text = Std.string(seperatedScore);
		// add(coolText);

		FlxTween.tween(rating, {alpha: 0}, 0.2, {
			startDelay: 222 * 0.001
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2, {
			onComplete: function(tween:FlxTween)
			{
				coolText.destroy();
				comboSpr.destroy();

				rating.destroy();
			},
			startDelay: 222 * 0.001
		});
	}

	public function startVideo(name:String)
	{
		#if VIDEOS_ALLOWED
		inCutscene = true;

		var filepath:String = Paths.video(name);
		#if sys
		if(!FileSystem.exists(filepath))
		#else
		if(!OpenFlAssets.exists(filepath))
		#end
		{
			FlxG.log.warn('Couldnt find video file: ' + name);
			startAndEnd();
			return;
		}

		var video:FlxVideo = new FlxVideo();
		video.load(filepath);
		video.play();
		FlxG.addChildBelowMouse(video);
		video.onEndReached.add(function()
		{
			FlxG.removeChild(video);
			video.dispose();
			startAndEnd();
			return;
		}, true);

		#else
		FlxG.log.warn('Platform not supported!');
		startAndEnd();
		return;
		#end
	}

	function startAndEnd()
	{
		if(endingSong)
			endSong();
		else
			startCountdown();
	}

	var dialogueCount:Int = 0;
	public var psychDialogue:DialogueBoxPsych;
	//You don't have to add a song, just saying. You can just do "startDialogue(dialogueJson);" and it should work
	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void
	{
		// TO DO: Make this more flexible, maybe?
		if(psychDialogue != null) return;

		if(dialogueFile.dialogue.length > 0) {
			inCutscene = true;
			CoolUtil.precacheSound('dialogue');
			CoolUtil.precacheSound('dialogueClose');
			psychDialogue = new DialogueBoxPsych(dialogueFile, song);
			psychDialogue.scrollFactor.set();
			if(endingSong) {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					endSong();
				}
			} else {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					startCountdown();
				}
			}
			psychDialogue.nextDialogueThing = startNextDialogue;
			psychDialogue.skipDialogueThing = skipDialogue;
			psychDialogue.cameras = [camHUD];
			add(psychDialogue);
		} else {
			FlxG.log.warn('Your dialogue file is badly formatted!');
			if(endingSong) {
				endSong();
			} else {
				startCountdown();
			}
		}
	}

	function schoolIntro(?dialogueBox:DialogueBox):Void
	{
		inCutscene = true;
		var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black.scrollFactor.set();
		add(black);

		var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
		red.scrollFactor.set();

		var senpaiEvil:FlxSprite = new FlxSprite();
		senpaiEvil.frames = Paths.getSparrowAtlas('weeb/senpaiCrazy');
		senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
		senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
		senpaiEvil.scrollFactor.set();
		senpaiEvil.updateHitbox();
		senpaiEvil.screenCenter();
		senpaiEvil.x += 300;

		var songName:String = Paths.formatToSongPath(SONG.song);
		if (songName == 'roses' || songName == 'thorns')
		{
			remove(black);

			if (songName == 'thorns')
			{
				add(red);
				camHUD.visible = false;
			}
		}

		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			black.alpha -= 0.15;

			if (black.alpha > 0)
			{
				tmr.reset(0.3);
			}
			else
			{
				if (dialogueBox != null)
				{
					if (Paths.formatToSongPath(SONG.song) == 'thorns')
					{
						add(senpaiEvil);
						senpaiEvil.alpha = 0;
						new FlxTimer().start(0.3, function(swagTimer:FlxTimer)
						{
							senpaiEvil.alpha += 0.15;
							if (senpaiEvil.alpha < 1)
							{
								swagTimer.reset();
							}
							else
							{
								senpaiEvil.animation.play('idle');
								FlxG.sound.play(Paths.sound('Senpai_Dies'), 1, false, null, true, function()
								{
									remove(senpaiEvil);
									remove(red);
									FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function()
									{
										add(dialogueBox);
										camHUD.visible = true;
									}, true);
								});
								new FlxTimer().start(3.2, function(deadTime:FlxTimer)
								{
									FlxG.camera.fade(FlxColor.WHITE, 1.6, false);
								});
							}
						});
					}
					else
					{
						add(dialogueBox);
					}
				}
				else
					startCountdown();

				remove(black);
			}
		});
	}

	var startTimer:FlxTimer;
	var finishTimer:FlxTimer = null;

	// For being able to mess with the sprites on Lua
	public var countdownStarting:FlxSprite;
	public var countdownReady:FlxSprite;
	public var countdownSet:FlxSprite;
	public var countdownGo:FlxSprite;
	public static var startOnTime:Float = 0;

	public function startCountdown():Void
	{
		if (curSong == 'Better Bean') 
		{
			skipCountdown = true;
		}
		else if (curSong == 'Short Circut') 
		{
			skipCountdown = true;
		}
		else
		{
			skipCountdown = false;
		}

		if(startedCountdown) {
			callOnLuas('onStartCountdown', []);
			return;
		}

		inCutscene = false;
		var ret:Dynamic = callOnLuas('onStartCountdown', []);
		if(ret != FunkinLua.Function_Stop) {
			if (skipCountdown || startOnTime > 0) skipArrowStartTween = true;

			generateStaticArrows(0);
			generateStaticArrows(1);
			for (i in 0...playerStrums.length) {
				setOnLuas('defaultPlayerStrumX' + i, playerStrums.members[i].x);
				setOnLuas('defaultPlayerStrumY' + i, playerStrums.members[i].y);
			}
			for (i in 0...opponentStrums.length) {
				setOnLuas('defaultOpponentStrumX' + i, opponentStrums.members[i].x);
				setOnLuas('defaultOpponentStrumY' + i, opponentStrums.members[i].y);
				//if(ClientPrefs.middleScroll) opponentStrums.members[i].visible = false;
			}

			if (playAsOpp == true && !ClientPrefs.middleScroll)
			{
				var oppX:Float;
				
				for (i in 0...opponentStrums.length)
				{
					oppX = opponentStrums.members[i].x;
					opponentStrums.members[i].x = playerStrums.members[i].x;
					playerStrums.members[i].x = oppX;
				}
			}

			var CountdownSpeed:Int = 600; //bpm = 100 (https://calculator.academy/bpm-to-ms-calculator/)

			startedCountdown = mobileControls.instance.visible = true;
			Conductor.songPosition = 0;
			Conductor.songPosition -= CountdownSpeed * 5;
			setOnLuas('startedCountdown', true);
			callOnLuas('onCountdownStarted', []);

			var swagCounter:Int = 0;

			if (skipCountdown || startOnTime > 0) {
				clearNotesBefore(startOnTime);
				setSongTime(startOnTime - 500);
				return;
			}

			startTimer = new FlxTimer().start(CountdownSpeed / 1000, function(tmr:FlxTimer)
			{
				if (gf != null && tmr.loopsLeft % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && !gf.stunned && gf.animation.curAnim.name != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned)
				{
					gf.dance();
				}
				if (tmr.loopsLeft % boyfriend.danceEveryNumBeats == 0 && boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.stunned)
				{
					boyfriend.dance();
				}
				if (tmr.loopsLeft % dad.danceEveryNumBeats == 0 && dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned)
				{
					dad.dance();
				}

				var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
				introAssets.set('default', ['starting', 'ready', 'set', 'go']);
				introAssets.set('fall', ['fallmen/UI/starting', 'fallmen/UI/ready', 'fallmen/UI/set', 'fallmen/UI/go']);
				introAssets.set('pixel', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);

				var introAlts:Array<String> = introAssets.get('default');
				var antialias:Bool = ClientPrefs.globalAntialiasing;
				if(isPixelStage) {
					introAlts = introAssets.get('pixel');
					antialias = false;
				}

				if (useFunkinUI == false)
				{
					introAlts = introAssets.get('fall');
				}

				if(curStage == 'blastball')
				{
					if (bopped == false)
					{
						logicBoppers.dance(true);
						bopped = true;
					}
					else
					{
						bopped = false;
					}
				}

				// head bopping for bg characters on Mall
				if(curStage == 'mall') {
					if(!ClientPrefs.lowQuality)
						upperBoppers.dance(true);
	
					bottomBoppers.dance(true);
					santa.dance(true);
				}

				switch (swagCounter)
				{
					case 0:
						countdownStarting = new FlxSprite().loadGraphic(Paths.image(introAlts[0]));
						countdownStarting.scrollFactor.set();
						countdownStarting.cameras = [camHUD];
						countdownStarting.updateHitbox();

						if (PlayState.isPixelStage)
							countdownStarting.setGraphicSize(Std.int(countdownStarting.width * daPixelZoom));
						else
							countdownStarting.setGraphicSize(Std.int(countdownStarting.width * 0.6));

						countdownStarting.screenCenter();
						countdownStarting.antialiasing = ClientPrefs.globalAntialiasing;
						add(countdownStarting);
						FlxTween.tween(countdownStarting, {/*y: countdownStarting.y + 100,*/ alpha: 0}, CountdownSpeed / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownStarting);
								countdownStarting.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('intro3' + introSoundsSuffix), 0.6);
					case 1:
						countdownReady = new FlxSprite().loadGraphic(Paths.image(introAlts[1]));
						countdownReady.scrollFactor.set();
						countdownReady.cameras = [camHUD];
						countdownReady.updateHitbox();

						if (PlayState.isPixelStage)
							countdownReady.setGraphicSize(Std.int(countdownReady.width * daPixelZoom));
						else
							countdownReady.setGraphicSize(Std.int(countdownStarting.width * 0.6));

						countdownReady.screenCenter();
						countdownReady.antialiasing = ClientPrefs.globalAntialiasing;
						add(countdownReady);
						FlxTween.tween(countdownReady, {/*y: countdownReady.y + 100,*/ alpha: 0}, CountdownSpeed / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownReady);
								countdownReady.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('intro2' + introSoundsSuffix), 0.6);
					case 2:
						countdownSet = new FlxSprite().loadGraphic(Paths.image(introAlts[2]));
						countdownSet.cameras = [camHUD];
						countdownSet.scrollFactor.set();

						if (PlayState.isPixelStage)
							countdownSet.setGraphicSize(Std.int(countdownSet.width * daPixelZoom));
						else
							countdownSet.setGraphicSize(Std.int(countdownStarting.width * 0.6));

						countdownSet.screenCenter();
						countdownSet.antialiasing = ClientPrefs.globalAntialiasing;
						add(countdownSet);
						FlxTween.tween(countdownSet, {/*y: countdownSet.y + 100,*/ alpha: 0}, CountdownSpeed / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownSet);
								countdownSet.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('intro1' + introSoundsSuffix), 0.6);
					case 3:
						countdownGo = new FlxSprite().loadGraphic(Paths.image(introAlts[3]));
						countdownGo.cameras = [camHUD];
						countdownGo.scrollFactor.set();

						if (PlayState.isPixelStage)
							countdownGo.setGraphicSize(Std.int(countdownGo.width * daPixelZoom));
						else
							countdownGo.setGraphicSize(Std.int(countdownStarting.width * 0.6));

						countdownGo.updateHitbox();

						countdownGo.screenCenter();
						countdownGo.antialiasing = ClientPrefs.globalAntialiasing;
						add(countdownGo);
						FlxTween.tween(countdownGo, {/*y: countdownGo.y + 100,*/ alpha: 0}, CountdownSpeed / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownGo);
								countdownGo.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('introGo' + introSoundsSuffix), 0.6);
					case 4:
				}

				notes.forEachAlive(function(note:Note) {
					note.copyAlpha = false;
					note.alpha = note.multAlpha;
					if(ClientPrefs.middleScroll && !note.mustPress) {
						note.alpha *= 0.5;
					}
				});
				callOnLuas('onCountdownTick', [swagCounter]);

				swagCounter += 1;
				// generateSong('fresh');
			}, 5);
		}
	}

	public function clearNotesBefore(time:Float)
	{
		var i:Int = unspawnNotes.length - 1;
		while (i >= 0) {
			var daNote:Note = unspawnNotes[i];
			if(daNote.strumTime - 500 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				daNote.kill();
				unspawnNotes.remove(daNote);
				daNote.destroy();
			}
			--i;
		}

		i = notes.length - 1;
		while (i >= 0) {
			var daNote:Note = notes.members[i];
			if(daNote.strumTime - 500 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				daNote.kill();
				notes.remove(daNote, true);
				daNote.destroy();
			}
			--i;
		}
	}

	public function setSongTime(time:Float)
	{
		if(time < 0) time = 0;

		FlxG.sound.music.pause();
		vocals.pause();
		vocalsP2.pause();

		FlxG.sound.music.time = time;
		FlxG.sound.music.play();

		vocals.time = time;
		vocals.play();
		vocalsP2.time = time;
		vocalsP2.play();
		Conductor.songPosition = time;
	}

	function startNextDialogue() {
		dialogueCount++;
		callOnLuas('onNextDialogue', [dialogueCount]);
	}

	function skipDialogue() {
		callOnLuas('onSkipDialogue', [dialogueCount]);
	}

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	function startSong():Void
	{
		startingSong = false;

		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 1, false);
		FlxG.sound.music.onComplete = onSongComplete;
		vocals.play();
		vocalsP2.play();

		if(startOnTime > 0)
		{
			setSongTime(startOnTime - 500);
		}
		startOnTime = 0;

		if(paused) {
			//trace('Oopsie doopsie! Paused sound');
			FlxG.sound.music.pause();
			vocals.pause();
			vocalsP2.pause();
		}

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
		FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		FlxTween.tween(falltime, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		
		#if desktop
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength);
		#end
		setOnLuas('songLength', songLength);
		callOnLuas('onSongStart', []);
	}

	var debugNum:Int = 0;
	private var noteTypeMap:Map<String, Bool> = new Map<String, Bool>();
	private var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();
	private function generateSong(dataPath:String):Void
	{
		// FlxG.log.add(ChartParser.parse());
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype','multiplicative');

		switch(songSpeedType)
		{
			case "multiplicative":
				songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1);
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed', 1);
		}
		
		var songData = SONG;
		Conductor.changeBPM(songData.bpm);
		
		curSong = songData.song;
		
		if (theBetterBean != "fallguy" && theBetterBean != "crewmate")
		{
			theBetterBean = "fallguy";
		}

		if (theBetterBean == "fallguy" && curSong == "Better Bean")
		{
			playAsOpp = true;
		}
		else
		{
			playAsOpp = false;
		}

		trace("playing as opp: " + playAsOpp);

		if (SONG.needsVoices)
		{
			if (playAsOpp == true)
			{
				vocals = new FlxSound().loadEmbedded(Paths.voicesP2(PlayState.SONG.song));
				vocalsP2 = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
			}
			else
			{
				vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
				vocalsP2 = new FlxSound().loadEmbedded(Paths.voicesP2(PlayState.SONG.song));
			}
		}
		else
		{
			vocals = new FlxSound();
			vocalsP2 = new FlxSound();
		}

		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(vocalsP2);
		FlxG.sound.list.add(new FlxSound().loadEmbedded(Paths.inst(PlayState.SONG.song)));

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var playerCounter:Int = 0;

		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped

		var songName:String = Paths.formatToSongPath(SONG.song);
		var file:String = Paths.json(songName + '/events');
		#if sys
		if (FileSystem.exists(Paths.modsJson(songName + '/events')) || FileSystem.exists(file)) {
		#else
		if (OpenFlAssets.exists(file)) {
		#end
			var eventsData:Array<Dynamic> = Song.loadFromJson('events', songName).events;
			for (event in eventsData) //Event Notes
			{
				for (i in 0...event[1].length)
				{
					var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
					var subEvent:EventNote = {
						strumTime: newEventNote[0] + ClientPrefs.noteOffset,
						event: newEventNote[1],
						value1: newEventNote[2],
						value2: newEventNote[3]
					};
					subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
					eventNotes.push(subEvent);
					eventPushed(subEvent);
				}
			}
		}

		//LOL FIND NOTE SWAP STUFF HERE AVACADO
		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % 4);

				if (playAsOpp == true)
				{
					for (i in 0...3)
					{
						if (songNotes[i] <= 3)
						{
							songNotes[i] = songNotes[i] + 4;
						}
						else if (songNotes[i] > 3)
						{
							songNotes[i] = songNotes[i] - 4;
						}

					}
				}

				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] > 3)
				{
					gottaHitNote = !section.mustHitSection;
				}

				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;

				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);
				swagNote.mustPress = gottaHitNote;
				swagNote.sustainLength = songNotes[2];
				swagNote.gfNote = (section.gfSection && (songNotes[1]<4));
				swagNote.noteType = songNotes[3];
				if(!Std.isOfType(songNotes[3], String)) swagNote.noteType = editors.ChartingState.noteTypeList[songNotes[3]]; //Backward compatibility + compatibility with Week 7 charts
				
				swagNote.scrollFactor.set();

				var susLength:Float = swagNote.sustainLength;

				susLength = susLength / Conductor.stepCrochet;
				unspawnNotes.push(swagNote);

				var floorSus:Int = Math.floor(susLength);
				if(floorSus > 0) {
					for (susNote in 0...floorSus+1)
					{
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

						var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + (Conductor.stepCrochet / FlxMath.roundDecimal(songSpeed, 2)), daNoteData, oldNote, true);
						sustainNote.mustPress = gottaHitNote;
						sustainNote.gfNote = (section.gfSection && (songNotes[1]<4));
						sustainNote.noteType = swagNote.noteType;
						sustainNote.scrollFactor.set();
						unspawnNotes.push(sustainNote);

						if (sustainNote.mustPress)
						{
							sustainNote.x += FlxG.width / 2; // general offset
						}
						else if(ClientPrefs.middleScroll)
						{
							sustainNote.x += 310;
							if(daNoteData > 1) //Up and Right
							{
								sustainNote.x += FlxG.width / 2 + 25;
							}
						}
					}
				}

				if (swagNote.mustPress)
				{
					swagNote.x += FlxG.width / 2; // general offset
				}
				else if(ClientPrefs.middleScroll)
				{
					swagNote.x += 310;
					if(daNoteData > 1) //Up and Right
					{
						swagNote.x += FlxG.width / 2 + 25;
					}
				}

				if(!noteTypeMap.exists(swagNote.noteType)) {
					noteTypeMap.set(swagNote.noteType, true);
				}
			}
			daBeats += 1;
		}
		for (event in songData.events) //Event Notes
		{
			for (i in 0...event[1].length)
			{
				var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
				var subEvent:EventNote = {
					strumTime: newEventNote[0] + ClientPrefs.noteOffset,
					event: newEventNote[1],
					value1: newEventNote[2],
					value2: newEventNote[3]
				};
				subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
				eventNotes.push(subEvent);
				eventPushed(subEvent);
			}
		}

		// trace(unspawnNotes.length);
		// playerCounter += 1;

		unspawnNotes.sort(sortByShit);
		if(eventNotes.length > 1) { //No need to sort if there's a single one or none at all
			eventNotes.sort(sortByTime);
		}
		checkEventNote();
		generatedMusic = true;
	}

	function eventPushed(event:EventNote) {
		switch(event.event) {
			case 'Change Character':
				var charType:Int = 0;
				switch(event.value1.toLowerCase()) {
					case 'gf' | 'girlfriend' | '1':
						charType = 2;
					case 'dad' | 'opponent' | '0':
						charType = 1;
					default:
						charType = Std.parseInt(event.value1);
						if(Math.isNaN(charType)) charType = 0;
				}

				var newCharacter:String = event.value2;
				addCharacterToList(newCharacter, charType);
		}

		if(!eventPushedMap.exists(event.event)) {
			eventPushedMap.set(event.event, true);
		}
	}

	function eventNoteEarlyTrigger(event:EventNote):Float {
		var returnedValue:Float = callOnLuas('eventEarlyTrigger', [event.event]);
		if(returnedValue != 0) {
			return returnedValue;
		}

		switch(event.event) {
			case 'Kill Henchmen': //Better timing so that the kill sound matches the beat intended
				return 280; //Plays 280ms before the actual position
		}
		return 0;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	function sortByTime(Obj1:EventNote, Obj2:EventNote):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	public var skipArrowStartTween:Bool = false; //for lua
	private function generateStaticArrows(player:Int):Void
	{
		for (i in 0...4)
		{
			// FlxG.log.add(i);
			var targetAlpha:Float = 1;
			if (player < 1 && ClientPrefs.middleScroll) targetAlpha = 0.35;

			var babyArrow:StrumNote = new StrumNote(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, strumLine.y, i, player);
			babyArrow.downScroll = ClientPrefs.downScroll;
			if (!skipArrowStartTween)
			{
				whirlyLeftGood = false;
				whirlyDownGood = false;
				whirlyUpGood = false;
				whirlyRightGood = false;
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {/*y: babyArrow.y + 10,*/ alpha: targetAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
				FlxTween.tween(healthBarBG, {alpha: ClientPrefs.healthBarAlpha}, 0.5, {ease: FlxEase.circOut});
				FlxTween.tween(fallhealth, {alpha: ClientPrefs.healthBarAlpha}, 0.5, {ease: FlxEase.circOut});
				FlxTween.tween(healthBar, {alpha: ClientPrefs.healthBarAlpha}, 0.5, {ease: FlxEase.circOut});
				FlxTween.tween(iconP1, {alpha: ClientPrefs.healthBarAlpha}, 0.5, {ease: FlxEase.circOut});
				FlxTween.tween(iconP2, {alpha: ClientPrefs.healthBarAlpha}, 0.5, {ease: FlxEase.circOut});
				FlxTween.tween(scoreTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
				FlxTween.tween(scoreTxtback, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
				FlxTween.tween(botplayTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
			}
			else
			{
				whirlyLeftGood = false;
				whirlyDownGood = false;
				whirlyUpGood = false;
				whirlyRightGood = false;
				babyArrow.alpha = targetAlpha;
				FlxTween.tween(healthBarBG, {alpha: ClientPrefs.healthBarAlpha}, 0.5, {ease: FlxEase.circOut});
				FlxTween.tween(fallhealth, {alpha: ClientPrefs.healthBarAlpha}, 0.5, {ease: FlxEase.circOut});
				FlxTween.tween(healthBar, {alpha: ClientPrefs.healthBarAlpha}, 0.5, {ease: FlxEase.circOut});
				FlxTween.tween(iconP1, {alpha: ClientPrefs.healthBarAlpha}, 0.5, {ease: FlxEase.circOut});
				FlxTween.tween(iconP2, {alpha: ClientPrefs.healthBarAlpha}, 0.5, {ease: FlxEase.circOut});
				FlxTween.tween(scoreTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
				FlxTween.tween(scoreTxtback, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
				FlxTween.tween(botplayTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
			}

			if (player == 1)
			{
				playerStrums.add(babyArrow);
			}
			else
			{
				if(ClientPrefs.middleScroll)
				{
					babyArrow.x += 310;
					if(i > 1) { //Up and Right
						babyArrow.x += FlxG.width / 2 + 25;
					}
				}
				opponentStrums.add(babyArrow);
			}

			strumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();
		}
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
				vocalsP2.pause();
			}

			if (startTimer != null && !startTimer.finished)
				startTimer.active = false;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = false;
			if (songSpeedTween != null)
				songSpeedTween.active = false;

			if(blammedLightsBlackTween != null)
				blammedLightsBlackTween.active = false;
			if(phillyCityLightsEventTween != null)
				phillyCityLightsEventTween.active = false;

			if(carTimer != null) carTimer.active = false;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (char in chars) {
				if(char != null && char.colorTween != null) {
					char.colorTween.active = false;
				}
			}

			for (tween in modchartTweens) {
				tween.active = false;
			}
			for (timer in modchartTimers) {
				timer.active = false;
			}
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong)
			{
				resyncVocals();
			}

			if (startTimer != null && !startTimer.finished)
				startTimer.active = true;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = true;
			if (songSpeedTween != null)
				songSpeedTween.active = true;

			if(blammedLightsBlackTween != null)
				blammedLightsBlackTween.active = true;
			if(phillyCityLightsEventTween != null)
				phillyCityLightsEventTween.active = true;
			
			if(carTimer != null) carTimer.active = true;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (char in chars) {
				if(char != null && char.colorTween != null) {
					char.colorTween.active = true;
				}
			}
			
			for (tween in modchartTweens) {
				tween.active = true;
			}
			for (timer in modchartTimers) {
				timer.active = true;
			}
			paused = false;
			callOnLuas('onResume', []);

			#if desktop
			if (startTimer != null && startTimer.finished)
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
			}
			#end
		}

		super.closeSubState();
	}

	override public function onFocus():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			if (Conductor.songPosition > 0.0)
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
			}
		}
		#end

		super.onFocus();
	}
	
	override public function onFocusLost():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		}
		#end

		super.onFocusLost();
	}

	function resyncVocals():Void
	{
		if(finishTimer != null) return;

		vocals.pause();
		vocalsP2.pause();

		FlxG.sound.music.play();
		Conductor.songPosition = FlxG.sound.music.time;
		vocals.time = Conductor.songPosition;
		vocals.play();
		vocalsP2.time = Conductor.songPosition;
		vocalsP2.play();
	}

	public var paused:Bool = false;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;
	var limoSpeed:Float = 0;

	override public function update(elapsed:Float)
	{
		callOnLuas('onUpdate', [elapsed]);

		switch (curStage)
		{
			case 'schoolEvil':
				if(!ClientPrefs.lowQuality && bgGhouls.animation.curAnim.finished) {
					bgGhouls.visible = false;
				}
			case 'philly':
				if (trainMoving)
				{
					trainFrameTiming += elapsed;

					if (trainFrameTiming >= 1 / 24)
					{
						updateTrainPos();
						trainFrameTiming = 0;
					}
				}
				phillyCityLights.members[curLight].alpha -= (Conductor.crochet / 1000) * FlxG.elapsed * 1.5;
			case 'limo':
				if(!ClientPrefs.lowQuality) {
					grpLimoParticles.forEach(function(spr:BGSprite) {
						if(spr.animation.curAnim.finished) {
							spr.kill();
							grpLimoParticles.remove(spr, true);
							spr.destroy();
						}
					});

					switch(limoKillingState) {
						case 1:
							limoMetalPole.x += 5000 * elapsed;
							limoLight.x = limoMetalPole.x - 180;
							limoCorpse.x = limoLight.x - 50;
							limoCorpseTwo.x = limoLight.x + 35;

							var dancers:Array<BackgroundDancer> = grpLimoDancers.members;
							for (i in 0...dancers.length) {
								if(dancers[i].x < FlxG.width * 1.5 && limoLight.x > (370 * i) + 130) {
									switch(i) {
										case 0 | 3:
											if(i == 0) FlxG.sound.play(Paths.sound('dancerdeath'), 0.5);

											var diffStr:String = i == 3 ? ' 2 ' : ' ';
											var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x + 200, dancers[i].y, 0.4, 0.4, ['hench leg spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);
											var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x + 160, dancers[i].y + 200, 0.4, 0.4, ['hench arm spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);
											var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x, dancers[i].y + 50, 0.4, 0.4, ['hench head spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);

											var particle:BGSprite = new BGSprite('gore/stupidBlood', dancers[i].x - 110, dancers[i].y + 20, 0.4, 0.4, ['blood'], false);
											particle.flipX = true;
											particle.angle = -57.5;
											grpLimoParticles.add(particle);
										case 1:
											limoCorpse.visible = true;
										case 2:
											limoCorpseTwo.visible = true;
									} //Note: Nobody cares about the fifth dancer because he is mostly hidden offscreen :(
									dancers[i].x += FlxG.width * 2;
								}
							}

							if(limoMetalPole.x > FlxG.width * 2) {
								resetLimoKill();
								limoSpeed = 800;
								limoKillingState = 2;
							}

						case 2:
							limoSpeed -= 4000 * elapsed;
							bgLimo.x -= limoSpeed * elapsed;
							if(bgLimo.x > FlxG.width * 1.5) {
								limoSpeed = 3000;
								limoKillingState = 3;
							}

						case 3:
							limoSpeed -= 2000 * elapsed;
							if(limoSpeed < 1000) limoSpeed = 1000;

							bgLimo.x -= limoSpeed * elapsed;
							if(bgLimo.x < -275) {
								limoKillingState = 4;
								limoSpeed = 800;
							}

						case 4:
							bgLimo.x = FlxMath.lerp(bgLimo.x, -150, CoolUtil.boundTo(elapsed * 9, 0, 1));
							if(Math.round(bgLimo.x) == -150) {
								bgLimo.x = -150;
								limoKillingState = 0;
							}
					}

					if(limoKillingState > 2) {
						var dancers:Array<BackgroundDancer> = grpLimoDancers.members;
						for (i in 0...dancers.length) {
							dancers[i].x = (370 * i) + bgLimo.x + 280;
						}
					}
				}
			case 'mall':
				if(heyTimer > 0) {
					heyTimer -= elapsed;
					if(heyTimer <= 0) {
						bottomBoppers.dance(true);
						heyTimer = 0;
					}
				}
		}

		if(!inCutscene) {
			var lerpVal:Float = CoolUtil.boundTo(elapsed * 2.4 * cameraSpeed, 0, 1);
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
			if(!startingSong && !endingSong && boyfriend.animation.curAnim.name.startsWith('idle')) {
				boyfriendIdleTime += elapsed;
				if(boyfriendIdleTime >= 0.15) { // Kind of a mercy thing for making the achievement easier to get as it's apparently frustrating to some playerss
					boyfriendIdled = true;
				}
			} else {
				boyfriendIdleTime = 0;
			}
		}

		super.update(elapsed);

		if(ratingName == '?')
		{
			scoreTxt.text = 'Score: ' + songScore + ' | Misses: ' + songMisses + ' | Rating: ' + ratingName;
			scoreTxtback.text = 'Score: ' + songScore + ' | Misses: ' + songMisses + ' | Rating: ' + ratingName;
		}
		else
		{
			scoreTxt.text = 'Score: ' + songScore + ' | Misses: ' + songMisses + ' | Rating: ' + medalType + ' (' + Highscore.floorDecimal(ratingPercent * 100, 2) + '%)' + ' - ' + ratingFC;//peeps wanted no integer rating
			scoreTxtback.text = 'Score: ' + songScore + ' | Misses: ' + songMisses + ' | Rating: ' + medalType + ' (' + Highscore.floorDecimal(ratingPercent * 100, 2) + '%)' + ' - ' + ratingFC;//peeps wanted no integer rating
		}

		if(botplayTxt.visible) {
			botplaySine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		}

		if ((#if android FlxG.android.justReleased.BACK #else touchPad.buttonP.justPressed #end || controls.PAUSE) && startedCountdown && canPause)
		{
			var ret:Dynamic = callOnLuas('onPause', []);
			if(ret != FunkinLua.Function_Stop) {
				persistentUpdate = false;
				persistentDraw = true;
				paused = true;

				if(FlxG.sound.music != null) {
					FlxG.sound.music.pause();
					vocals.pause();
					vocalsP2.pause();
				}
				openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
				//}
		
				#if desktop
				DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
				#end
			}
		}

		/*
		if (FlxG.keys.justPressed.SEVEN && !endingSong && !inCutscene)
		{
			openChartEditor();
		}
		*/

		var mult:Float = FlxMath.lerp(1, iconP1.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
		iconP1.scale.set(mult, mult);
		iconP1.updateHitbox();

		var mult:Float = FlxMath.lerp(1, iconP2.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
		iconP2.scale.set(mult, mult);
		iconP2.updateHitbox();

		var iconOffset:Int = 26;
		
		if (playAsOpp == true)
		{
			iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange((healthBar.percent - 100) * -1, 0, 100, 100, 0) * 0.01)) + (200 * iconP1.scale.x - 200) / 2 - iconOffset - 25;
			iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange((healthBar.percent - 100) * -1, 0, 100, 100, 0) * 0.01)) - (200 * iconP2.scale.x) / 2 - iconOffset * 2;
		}
		else
		{
			iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) + (200 * iconP1.scale.x - 200) / 2 - iconOffset - 25;
			iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (200 * iconP2.scale.x) / 2 - iconOffset * 2;
		}

		if (health > 2)
			health = 2;
			
		if (playAsOpp == true)
		{
			if (healthBar.percent < 20)
			{
				iconP2.animation.curAnim.curFrame = 1;

				losingVin.alpha = (healthBar.percent * 5) / 100;
				losingVin.alpha = 1 - losingVin.alpha;
			}
			else
			{
				iconP2.animation.curAnim.curFrame = 0;
				losingVin.alpha = 0;
			}

			if (healthBar.percent > 80)
			{
				iconP1.animation.curAnim.curFrame = 1;
				//winning GF animation
			}
			else
			{
				iconP1.animation.curAnim.curFrame = 0;
			}
		}
		else
		{
			if (healthBar.percent < 20)
			{
				iconP1.animation.curAnim.curFrame = 1;

				losingVin.alpha = (healthBar.percent * 5) / 100;
				losingVin.alpha = 1 - losingVin.alpha;
			}
			else
			{
				iconP1.animation.curAnim.curFrame = 0;
				losingVin.alpha = 0;
			}

			if (healthBar.percent > 80)
			{
				iconP2.animation.curAnim.curFrame = 1;
				//winning GF animation
			}
			else
			{
				iconP2.animation.curAnim.curFrame = 0;
			}
		}

		/*
		if (FlxG.keys.justPressed.EIGHT && !endingSong && !inCutscene) {
			persistentUpdate = false;
			paused = true;
			cancelMusicFadeTween();
			MusicBeatState.switchState(new CharacterEditorState(SONG.player2));
		}
		*/

		if (startingSong)
		{
			if (startedCountdown)
			{
				Conductor.songPosition += FlxG.elapsed * 1000;
				if (Conductor.songPosition >= 0)
					startSong();
			}
		}
		else
		{
			Conductor.songPosition += FlxG.elapsed * 1000;

			if (!paused)
			{
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;

				// Interpolation type beat
				if (Conductor.lastSongPos != Conductor.songPosition)
				{
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
					// Conductor.songPosition += FlxG.elapsed * 1000;
					// trace('MISSED FRAME');
				}

				if(updateTime)
				{
					var curTime:Float = Conductor.songPosition - ClientPrefs.noteOffset;
					if(curTime < 0) curTime = 0;
					songPercent = (curTime / songLength);

					var songCalc:Float = (songLength - curTime);
					if(ClientPrefs.timeBarType == 'Time Elapsed') songCalc = curTime;

					var secondsTotal:Int = Math.floor(songCalc / 1000);
					if(secondsTotal < 0) secondsTotal = 0;

					if (ClientPrefs.timeBarType != 'Song Name')
					{
						if (useFunkinUI == false)
						{
							timeTxt.text = "0" + FlxStringUtil.formatTime(secondsTotal, false);
						}
						else
						{
							timeTxt.text = FlxStringUtil.formatTime(secondsTotal, false);
						}
					}
					else if (ClientPrefs.timeBarType == 'Song Name' && useFunkinUI == false)
					{
						{
							timeTxt.text = "0" + FlxStringUtil.formatTime(secondsTotal, false);
						}
					}
				}
			}

			// Conductor.lastSongPos = FlxG.sound.music.time;
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125), 0, 1));
		}

		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		// RESET = Quick Game Over Screen
		if (!ClientPrefs.noReset && controls.RESET && !inCutscene && !endingSong)
		{
			health = 0;
			trace("RESET = True");
		}
		doDeathCheck();

		if (unspawnNotes[0] != null)
		{
			var time:Float = 3000;//shit be werid on 4:3
			if(songSpeed < 1) time /= songSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.insert(0, dunceNote);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (generatedMusic)
		{
			if (!inCutscene) {
				if(!cpuControlled) {
					keyShit();
				} else if(boyfriend.holdTimer > Conductor.stepCrochet * 0.001 * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss')) {
					boyfriend.dance();
					//boyfriend.animation.curAnim.finish();
				}
			}

			var fakeCrochet:Float = (60 / SONG.bpm) * 1000;
			notes.forEachAlive(function(daNote:Note)
			{
				var strumGroup:FlxTypedGroup<StrumNote> = playerStrums;
				if(!daNote.mustPress) strumGroup = opponentStrums;

				var strumX:Float = strumGroup.members[daNote.noteData].x;
				var strumY:Float = strumGroup.members[daNote.noteData].y;
				var strumAngle:Float = strumGroup.members[daNote.noteData].angle;
				var strumDirection:Float = strumGroup.members[daNote.noteData].direction;
				var strumAlpha:Float = strumGroup.members[daNote.noteData].alpha;
				var strumScroll:Bool = strumGroup.members[daNote.noteData].downScroll;

				strumX += daNote.offsetX;
				strumY += daNote.offsetY;
				strumAngle += daNote.offsetAngle;
				strumAlpha *= daNote.multAlpha;

				if (strumScroll) //Downscroll
				{
					//daNote.y = (strumY + 0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed);
					daNote.distance = (0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed);
				}
				else //Upscroll
				{
					//daNote.y = (strumY - 0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed);
					daNote.distance = (-0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed);
				}

				var angleDir = strumDirection * Math.PI / 180;
				if (daNote.copyAngle)
					daNote.angle = strumDirection - 90 + strumAngle;

				if(daNote.copyAlpha)
					daNote.alpha = strumAlpha;
				
				if(daNote.copyX)
					daNote.x = strumX + Math.cos(angleDir) * daNote.distance;

				if(daNote.copyY)
				{
					daNote.y = strumY + Math.sin(angleDir) * daNote.distance;

					//Jesus fuck this took me so much mother fucking time AAAAAAAAAA
					if(strumScroll && daNote.isSustainNote)
					{
						if (daNote.animation.curAnim.name.endsWith('end')) {
							daNote.y += 10.5 * (fakeCrochet / 400) * 1.5 * songSpeed + (46 * (songSpeed - 1));
							daNote.y -= 46 * (1 - (fakeCrochet / 600)) * songSpeed;
							if(PlayState.isPixelStage) {
								daNote.y += 8 + (6 - daNote.originalHeightForCalcs) * PlayState.daPixelZoom;
							} else {
								daNote.y -= 19;
							}
						} 
						daNote.y += (Note.swagWidth / 2) - (60.5 * (songSpeed - 1));
						daNote.y += 27.5 * ((SONG.bpm / 100) - 1) * (songSpeed - 1);
					}
				}

				if (!daNote.mustPress && daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote)
				{
					opponentNoteHit(daNote);
				}

				/* REFERENCE THIS
				['You Suck!'],	//From 0% to 19% - Purple = 0		- Pink (other)
				['Awful'],		//From 20% to 39%					- Pink
				['Bad'],		//From 40% to 49%					- Pink
				['Bruh'],		//From 50% to 59%					- Pink
				['Meh'],		//From 60% to 68%					- Pink
				['Nice',		//69%								- Pink
				['Good'],		//From 70% to 79%					- Bronze
				['Great'],		//From 80% to 89%					- Bronze
				['Sick!'],		//From 90% to 99%					- Silver
				['Perfect!!']	//100%								- Gold
				*/

				//HUGE MESS BUT ITS FOR THE SCORE BORDER COLOR CHANGING STUFF AND IVE BEEN TRYING TO FIND OTHER WAYS FOR HOURS

				if ((ratingFC != "SFC" || ratingFC != "GFC" || ratingFC != "FC") && daNote.wasGoodHit && useFunkinUI == false && ratingPercent * 100 >= 0 || !daNote.wasGoodHit && useFunkinUI == false && ratingPercent * 100 >= 0)
				{
					scoreTxt.borderColor = 0xFF8A2EDB;
				}
				if ((ratingFC != "SFC" || ratingFC != "GFC" || ratingFC != "FC") && daNote.wasGoodHit && useFunkinUI == false && ratingPercent * 100 >= 1 || !daNote.wasGoodHit && useFunkinUI == false && ratingPercent * 100 >= 1)
				{
					scoreTxt.borderColor = 0xFFDD0088;
				}
				if ((ratingFC != "SFC" || ratingFC != "GFC" || ratingFC != "FC") && daNote.wasGoodHit && useFunkinUI == false && ratingPercent * 100 >= 70 || !daNote.wasGoodHit && useFunkinUI == false && ratingPercent * 100 >= 70)
				{
					scoreTxt.borderColor = 0xFFA8642F;
				}
				if (storyDifficulty >= 1 && ((ratingFC != "SFC" || ratingFC != "GFC" || ratingFC != "FC") && daNote.wasGoodHit && useFunkinUI == false && ratingPercent * 100 >= 90 || !daNote.wasGoodHit && useFunkinUI == false && ratingPercent * 100 >= 90))
				{
					scoreTxt.borderColor = 0xFF2AA9AF;
				}
				if (storyDifficulty == 2 && ((ratingFC == "SFC" || ratingFC == "GFC" || ratingFC == "FC") || (daNote.wasGoodHit && useFunkinUI == false && ratingPercent * 100 >= 100 || !daNote.wasGoodHit && useFunkinUI == false && ratingPercent * 100 >= 100)))
				{
					scoreTxt.borderColor = 0xFFE8933C;
				}

				if ((ratingFC != "SFC" || ratingFC != "GFC" || ratingFC != "FC") && daNote.wasGoodHit && ratingPercent * 100 >= 0 || !daNote.wasGoodHit && ratingPercent * 100 >= 0)
				{
					medalType = 'Failing';
				}
				if ((ratingFC != "SFC" || ratingFC != "GFC" || ratingFC != "FC") && daNote.wasGoodHit && ratingPercent * 100 >= 1 || !daNote.wasGoodHit && ratingPercent * 100 >= 1)
				{
					medalType = 'Slimey';
				}
				if ((ratingFC != "SFC" || ratingFC != "GFC" || ratingFC != "FC") && daNote.wasGoodHit && ratingPercent * 100 >= 70 || !daNote.wasGoodHit && ratingPercent * 100 >= 70)
				{
					medalType = 'Bronze';
				}
				if (storyDifficulty >= 1 && ((ratingFC != "SFC" || ratingFC != "GFC" || ratingFC != "FC") && daNote.wasGoodHit && ratingPercent * 100 >= 90 || !daNote.wasGoodHit && ratingPercent * 100 >= 90))
				{
					medalType = 'Silver';
				}
				if (storyDifficulty == 2 && ((ratingFC == "SFC" || ratingFC == "GFC" || ratingFC == "FC") || (daNote.wasGoodHit && useFunkinUI == false && ratingPercent * 100 >= 100 || !daNote.wasGoodHit && useFunkinUI == false && ratingPercent * 100 >= 100)))
				{
					medalType = 'Golden!';
				}

				if(daNote.mustPress && cpuControlled) {
					if(daNote.isSustainNote) {
						if(daNote.canBeHit) {
							goodNoteHit(daNote);
						}
					} else if(daNote.strumTime <= Conductor.songPosition || (daNote.isSustainNote && daNote.canBeHit && daNote.mustPress)) {
						goodNoteHit(daNote);
					}
				}
				
				var center:Float = strumY + Note.swagWidth / 2;
				if(strumGroup.members[daNote.noteData].sustainReduce && daNote.isSustainNote && (daNote.mustPress || !daNote.ignoreNote) &&
					(!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
				{
					if (strumScroll)
					{
						if(daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= center)
						{
							var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
							swagRect.height = (center - daNote.y) / daNote.scale.y;
							swagRect.y = daNote.frameHeight - swagRect.height;

							daNote.clipRect = swagRect;
						}
					}
					else
					{
						if (daNote.y + daNote.offset.y * daNote.scale.y <= center)
						{
							var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
							swagRect.y = (center - daNote.y) / daNote.scale.y;
							swagRect.height -= swagRect.y;

							daNote.clipRect = swagRect;
						}
					}
				}

				// Kill extremely late notes and cause misses
				if (Conductor.songPosition > noteKillOffset + daNote.strumTime)
				{
					if (daNote.mustPress && !cpuControlled &&!daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit)) {
						noteMiss(daNote);
					}

					daNote.active = false;
					daNote.visible = false;

					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}
			});
		}

		checkEventNote();
		
		#if debug
		if(!endingSong && !startingSong) {
			if (FlxG.keys.justPressed.ONE) {
				KillNotes();
				FlxG.sound.music.onComplete();
			}
			if(FlxG.keys.justPressed.TWO) { //Go 10 seconds into the future :O
				setSongTime(Conductor.songPosition + 10000);
				clearNotesBefore(Conductor.songPosition);
			}
		}
		#end

		setOnLuas('cameraX', camFollowPos.x);
		setOnLuas('cameraY', camFollowPos.y);
		setOnLuas('botPlay', cpuControlled);
		callOnLuas('onUpdatePost', [elapsed]);
	}


	function openChartEditor()
	{
		whirlyLeftGood = false;
		whirlyDownGood = false;
		whirlyUpGood = false;
		whirlyRightGood = false;
		persistentUpdate = false;
		paused = true;
		cancelMusicFadeTween();
		//PlayState.SONG = Song.loadFromJson(FreeplayState.universalPoop, FreeplayState.freeplaySongName.toLowerCase());
		//PlayState.storyDifficulty = FreeplayState.curDifficulty;
		MusicBeatState.switchState(new ChartingState());
		chartingMode = true;

		#if desktop
		DiscordClient.changePresence("Chart Editor", null, null, true);
		#end
	}

	public var isDead:Bool = false; //Don't mess with this on Lua!!!
	function doDeathCheck(?skipHealthCheck:Bool = false) {
		if (((skipHealthCheck && instakillOnMiss) || health <= 0) && !practiceMode && !isDead)
		{
			var ret:Dynamic = callOnLuas('onGameOver', []);
			if(ret != FunkinLua.Function_Stop) {
				boyfriend.stunned = true;
				deathCounter++;

				paused = true;

				vocals.stop();
				vocalsP2.stop();
				FlxG.sound.music.stop();
				FlxG.sound.music.volume = 1;

				whirlyLeftGood = false;
				whirlyDownGood = false;
				whirlyUpGood = false;
				whirlyRightGood = false;

				persistentUpdate = false;
				persistentDraw = false;
				for (tween in modchartTweens) {
					tween.active = true;
				}
				for (timer in modchartTimers) {
					timer.active = true;
				}
				openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x - boyfriend.positionArray[0], boyfriend.getScreenPosition().y - boyfriend.positionArray[1], camFollowPos.x, camFollowPos.y));

				// MusicBeatState.switchState(new GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
				
				#if desktop
				// Game Over doesn't get his own variable because it's only used here
				DiscordClient.changePresence("Game Over - " + detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
				#end
				isDead = true;
				return true;
			}
		}
		return false;
	}

	public function checkEventNote() {
		while(eventNotes.length > 0) {
			var leStrumTime:Float = eventNotes[0].strumTime;
			if(Conductor.songPosition < leStrumTime) {
				break;
			}

			var value1:String = '';
			if(eventNotes[0].value1 != null)
				value1 = eventNotes[0].value1;

			var value2:String = '';
			if(eventNotes[0].value2 != null)
				value2 = eventNotes[0].value2;

			triggerEventNote(eventNotes[0].event, value1, value2);
			eventNotes.shift();
		}
	}

	public function getControl(key:String) {
		var pressed:Bool = Reflect.getProperty(controls, key);
		//trace('Control result: ' + pressed);
		return pressed;
	}
	
	//List of mid-song EVENTS Events events

	public function triggerEventNote(eventName:String, value1:String, value2:String) {
		switch(eventName) {
			case 'Hey!':
				var value:Int = 2;
				switch(value1.toLowerCase().trim()) {
					case 'bf' | 'boyfriend' | '0':
						value = 0;
					case 'gf' | 'girlfriend' | '1':
						value = 1;
				}

				var time:Float = Std.parseFloat(value2);
				if(Math.isNaN(time) || time <= 0) time = 0.6;

				if(value != 0) {
					if(dad.curCharacter.startsWith('gf')) { //Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
						dad.playAnim('cheer', true);
						dad.specialAnim = true;
						dad.heyTimer = time;
					} else if (gf != null) {
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = time;
					}

					if(curStage == 'mall') {
						bottomBoppers.animation.play('hey', true);
						heyTimer = time;
					}
				}
				if(value != 1) {
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = time;
				}

			case 'Set GF Speed':
				var value:Int = Std.parseInt(value1);
				if(Math.isNaN(value) || value < 1) value = 1;
				gfSpeed = value;

			case 'Blammed Lights':
				var lightId:Int = Std.parseInt(value1);
				if(Math.isNaN(lightId)) lightId = 0;

				var chars:Array<Character> = [boyfriend, gf, dad];
				if(lightId > 0 && curLightEvent != lightId) {
					if(lightId > 5) lightId = FlxG.random.int(1, 5, [curLightEvent]);

					var color:Int = 0xffffffff;
					switch(lightId) {
						case 1: //Blue
							color = 0xff31a2fd;
						case 2: //Green
							color = 0xff31fd8c;
						case 3: //Pink
							color = 0xfff794f7;
						case 4: //Red
							color = 0xfff96d63;
						case 5: //Orange
							color = 0xfffba633;
					}
					curLightEvent = lightId;

					if(blammedLightsBlack.alpha == 0) {
						if(blammedLightsBlackTween != null) {
							blammedLightsBlackTween.cancel();
						}
						blammedLightsBlackTween = FlxTween.tween(blammedLightsBlack, {alpha: 1}, 1, {ease: FlxEase.quadInOut,
							onComplete: function(twn:FlxTween) {
								blammedLightsBlackTween = null;
							}
						});

						for (char in chars) {
							if(char.colorTween != null) {
								char.colorTween.cancel();
							}
							char.colorTween = FlxTween.color(char, 1, FlxColor.WHITE, color, {onComplete: function(twn:FlxTween) {
								char.colorTween = null;
							}, ease: FlxEase.quadInOut});
						}
					} else {
						if(blammedLightsBlackTween != null) {
							blammedLightsBlackTween.cancel();
						}
						blammedLightsBlackTween = null;
						blammedLightsBlack.alpha = 1;

						for (char in chars) {
							if(char.colorTween != null) {
								char.colorTween.cancel();
							}
							char.colorTween = null;
						}
						dad.color = color;
						boyfriend.color = color;
						if (gf != null)
							gf.color = color;
					}
					
					if(curStage == 'philly') {
						if(phillyCityLightsEvent != null) {
							phillyCityLightsEvent.forEach(function(spr:BGSprite) {
								spr.visible = false;
							});
							phillyCityLightsEvent.members[lightId - 1].visible = true;
							phillyCityLightsEvent.members[lightId - 1].alpha = 1;
						}
					}
				} else {
					if(blammedLightsBlack.alpha != 0) {
						if(blammedLightsBlackTween != null) {
							blammedLightsBlackTween.cancel();
						}
						blammedLightsBlackTween = FlxTween.tween(blammedLightsBlack, {alpha: 0}, 1, {ease: FlxEase.quadInOut,
							onComplete: function(twn:FlxTween) {
								blammedLightsBlackTween = null;
							}
						});
					}

					if(curStage == 'philly') {
						phillyCityLights.forEach(function(spr:BGSprite) {
							spr.visible = false;
						});
						phillyCityLightsEvent.forEach(function(spr:BGSprite) {
							spr.visible = false;
						});

						var memb:FlxSprite = phillyCityLightsEvent.members[curLightEvent - 1];
						if(memb != null) {
							memb.visible = true;
							memb.alpha = 1;
							if(phillyCityLightsEventTween != null)
								phillyCityLightsEventTween.cancel();

							phillyCityLightsEventTween = FlxTween.tween(memb, {alpha: 0}, 1, {onComplete: function(twn:FlxTween) {
								phillyCityLightsEventTween = null;
							}, ease: FlxEase.quadInOut});
						}
					}

					for (char in chars) {
						if(char.colorTween != null) {
							char.colorTween.cancel();
						}
						char.colorTween = FlxTween.color(char, 1, char.color, FlxColor.WHITE, {onComplete: function(twn:FlxTween) {
							char.colorTween = null;
						}, ease: FlxEase.quadInOut});
					}

					curLight = 0;
					curLightEvent = 0;
				}

			case 'Kill Henchmen':
				killHenchmen();

			case 'Add Camera Zoom':
				if (curSong == 'Short Circut')
				{
					shortCircutsBlue.animation.reset();
					shortCircutsBlue.animation.play('circutsBlue', false);
					shortCircutsRed.animation.reset();
					shortCircutsRed.animation.play('circutsRed', false);
				}

				if(ClientPrefs.camZooms && FlxG.camera.zoom < 1.35) {
					var camZoom:Float = Std.parseFloat(value1);
					var hudZoom:Float = Std.parseFloat(value2);
					if(Math.isNaN(camZoom)) camZoom = 0.015;
					if(Math.isNaN(hudZoom)) hudZoom = 0.03;

					FlxG.camera.zoom += camZoom;
					camHUD.zoom += hudZoom;
				}

			case 'Trigger BG Ghouls':
				if(curStage == 'schoolEvil' && !ClientPrefs.lowQuality) {
					bgGhouls.dance(true);
					bgGhouls.visible = true;
				}

			case 'Play Animation':
				//trace('Anim to play: ' + value1);
				var char:Character = dad;
				switch(value2.toLowerCase().trim())
				{
					case 'bf' | 'boyfriend':
						char = boyfriend;
					case 'gf' | 'girlfriend':
						char = gf;
					default:
						var val2:Int = Std.parseInt(value2);
						if(Math.isNaN(val2)) val2 = 0;
		
						switch(val2)
						{
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null)
				{
					if ((value2 == 'bf' || value2 == 'boyfriend') && FlxG.save.data.BFskin != 'og' && value1 == 'hey')
					{
						value1 = 'singUP';
					}

					if ((value2 == 'gf' || value2 == 'girlfriend') && FlxG.save.data.GFskin != 'og' && FlxG.save.data.GFskin != 'og-small' && value1 == 'cheer')
					{
						value1 = 'singRIGHT';
					}

					if (FlxG.save.data.FGskin != '' && value1 == 'hey0')
					{
						value1 = 'singDOWN';
					}
					if (value2 == 'dad' && FlxG.save.data.FGskin != '' && value1 == 'hey')
					{
						value1 = 'singUP';
					}
					if (FlxG.save.data.FGskin != '' && value1 == 'laugh')
					{
						value1 = 'singDOWN';
					}

					char.playAnim(value1, true);
					char.specialAnim = true;
				}

			case 'Play BF Animations':
				if (value1 == "true") //THIS IS STUPID. WHY IS IT LIKE THIS???
					{
						BFplayNoteAnims = true;
					}
				else if (value1 == "false")
					{
						BFplayNoteAnims = false;
						boyfriend.playAnim('idle', true);
					}
					else
					{
					}

			case 'Play Opponent Animations':
				if (value1 == "true")
					{
						oppPlayNoteAnims = true;
					}
				else if (value1 == "false")
					{
						oppPlayNoteAnims = false;
						dad.playAnim('idle', true);
					}
					else
					{
					}

			case 'Fall Guy Run':
				oppPlayNoteAnims = false;
				var charType:Int = 1;
					switch(value1)
					{
						case 'dad' | 'opponent':
							charType = 1;
						default:
							charType = 1;
					}

					switch(charType) {
						case 1:
							if(dad.curCharacter != "fg-run")
							{
								if(!dadMap.exists("fg-run"))
								{
									addCharacterToList("fg-run", charType);
								}

								var lastAlpha:Float = dad.alpha;
								dad.alpha = 0.00001;
								dad = dadMap.get("fg-run");
								dad.alpha = lastAlpha;
								iconP2.changeIcon(dad.healthIcon);
							}
							setOnLuas('dadName', dad.curCharacter);
					}
				reloadHealthBarColors();
				
				FlxTween.tween(dadGroup, {x: dadGroup.y + 1500}, 10, {type: ONESHOT,
				onComplete: function (twn:FlxTween)
					{
						var charType:Int = 1;
							switch(value1)
							{
								case 'dad' | 'opponent':
									charType = 1;
								default:
									charType = 1;
							}

							switch(charType) {
								case 1:
									if(dad.curCharacter != "fall-guy")
									{
										if(!dadMap.exists("fall-guy"))
										{
											addCharacterToList("fall-guy", charType);
										}

										var lastAlpha:Float = dad.alpha;
										dad.alpha = 0.00001;
										dad = dadMap.get("fall-guy");
										dad.alpha = lastAlpha;
										iconP2.changeIcon(dad.healthIcon);
									}
									setOnLuas('dadName', dad.curCharacter);
							}
						reloadHealthBarColors();
						oppPlayNoteAnims = true;
					}
				});

			case 'Camera Follow Pos':
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if(Math.isNaN(val1)) val1 = 0;
				if(Math.isNaN(val2)) val2 = 0;

				isCameraOnForcedPos = false;
				if(!Math.isNaN(Std.parseFloat(value1)) || !Math.isNaN(Std.parseFloat(value2))) {
					camFollow.x = val1;
					camFollow.y = val2;
					isCameraOnForcedPos = true;
				}

			case 'Alt Idle Animation':
				var char:Character = dad;
				switch(value1.toLowerCase()) {
					case 'gf' | 'girlfriend':
						char = gf;
					case 'boyfriend' | 'bf':
						char = boyfriend;
					default:
						var val:Int = Std.parseInt(value1);
						if(Math.isNaN(val)) val = 0;

						switch(val) {
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null)
				{
					char.idleSuffix = value2;
					char.recalculateDanceIdle();
				}

			case 'Screen Shake':
				var valuesArray:Array<String> = [value1, value2];
				var targetsArray:Array<FlxCamera> = [camGame, camHUD];
				for (i in 0...targetsArray.length) {
					var split:Array<String> = valuesArray[i].split(',');
					var duration:Float = 0;
					var intensity:Float = 0;
					if(split[0] != null) duration = Std.parseFloat(split[0].trim());
					if(split[1] != null) intensity = Std.parseFloat(split[1].trim());
					if(Math.isNaN(duration)) duration = 0;
					if(Math.isNaN(intensity)) intensity = 0;

					if(duration > 0 && intensity != 0) {
						targetsArray[i].shake(intensity, duration);
					}
				}


			case 'Change Character':
				var charType:Int = 0;
				switch(value1) {
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					default:
						charType = Std.parseInt(value1);
						if(Math.isNaN(charType)) charType = 0;
				}

				switch(charType) {
					case 0:
						if(boyfriend.curCharacter != value2) {
							if(!boyfriendMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var lastAlpha:Float = boyfriend.alpha;
							boyfriend.alpha = 0.00001;
							boyfriend = boyfriendMap.get(value2);
							boyfriend.alpha = lastAlpha;
							iconP1.changeIcon(boyfriend.healthIcon);
						}
						setOnLuas('boyfriendName', boyfriend.curCharacter);

					case 1:
						if(dad.curCharacter != value2) {
							if(!dadMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var wasGf:Bool = dad.curCharacter.startsWith('gf');
							var lastAlpha:Float = dad.alpha;
							dad.alpha = 0.00001;
							dad = dadMap.get(value2);
							if(!dad.curCharacter.startsWith('gf')) {
								if(wasGf && gf != null) {
									gf.visible = true;
								}
							} else if(gf != null) {
								gf.visible = false;
							}
							dad.alpha = lastAlpha;
							iconP2.changeIcon(dad.healthIcon);
						}
						setOnLuas('dadName', dad.curCharacter);

					case 2:
						if(gf != null)
						{
							if(gf.curCharacter != value2)
							{
								if(!gfMap.exists(value2))
								{
									addCharacterToList(value2, charType);
								}

								var lastAlpha:Float = gf.alpha;
								gf.alpha = 0.00001;
								gf = gfMap.get(value2);
								gf.alpha = lastAlpha;
							}
							setOnLuas('gfName', gf.curCharacter);
						}
				}
				reloadHealthBarColors();
			
			case 'BG Freaks Expression':
				if(bgGirls != null) bgGirls.swapDanceType();
			
			case 'Change Scroll Speed':
				if (songSpeedType == "constant")
					return;
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if(Math.isNaN(val1)) val1 = 1;
				if(Math.isNaN(val2)) val2 = 0;

				var newValue:Float = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * val1;

				if(val2 <= 0)
				{
					songSpeed = newValue;
				}
				else
				{
					songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, val2, {ease: FlxEase.linear, onComplete:
						function (twn:FlxTween)
						{
							songSpeedTween = null;
						}
					});
				}
		}
		callOnLuas('onEvent', [eventName, value1, value2]);
	}

	function moveCameraSection(?id:Int = 0):Void {
		if(SONG.notes[id] == null) return;

		if (gf != null && SONG.notes[id].gfSection)
		{
			camFollow.set(gf.getMidpoint().x, gf.getMidpoint().y);
			camFollow.x += gf.cameraPosition[0] + girlfriendCameraOffset[0];
			camFollow.y += gf.cameraPosition[1] + girlfriendCameraOffset[1];
			tweenCamIn();
			callOnLuas('onMoveCamera', ['gf']);
			return;
		}

		if (!SONG.notes[id].mustHitSection)
		{
			moveCamera(true);
			callOnLuas('onMoveCamera', ['dad']);

			if (curStage == 'slimeclimb')
			{
				defaultCamZoom = 0.5;
			}
			else if (curStage == 'fallmountain')
			{
				defaultCamZoom = 0.3;
			}
			else if (curStage == 'spikyslopes')
			{
				defaultCamZoom = 0.6;
			}
		}
		else
		{
			moveCamera(false);
			callOnLuas('onMoveCamera', ['boyfriend']);

			if (curStage == 'slimeclimb')
			{
				defaultCamZoom = 0.8;
			}
			else if (curStage == 'fallmountain')
			{
				defaultCamZoom = 0.4;
			}
			else if (curStage == 'spikyslopes')
			{
				defaultCamZoom = 0.7;
			}
		}
	}

	var cameraTwn:FlxTween;
	public function moveCamera(isDad:Bool)
	{
		if(isDad)
		{
			camFollow.set(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
			camFollow.x += dad.cameraPosition[0] + opponentCameraOffset[0];
			camFollow.y += dad.cameraPosition[1] + opponentCameraOffset[1];
			tweenCamIn();
		}
		else
		{
			camFollow.set(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
			camFollow.x -= boyfriend.cameraPosition[0] - boyfriendCameraOffset[0];
			camFollow.y += boyfriend.cameraPosition[1] + boyfriendCameraOffset[1];

			if (Paths.formatToSongPath(SONG.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1)
			{
				cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
					function (twn:FlxTween)
					{
						cameraTwn = null;
					}
				});
			}
		}
	}

	function tweenCamIn() {
		if (Paths.formatToSongPath(SONG.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1.3) {
			cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
				function (twn:FlxTween) {
					cameraTwn = null;
				}
			});
		}
	}

	function snapCamFollowToPos(x:Float, y:Float) {
		camFollow.set(x, y);
		camFollowPos.setPosition(x, y);
	}

	//Any way to do this without using a different function? kinda dumb
	private function onSongComplete()
	{
		finishSong(false);
	}
	public function finishSong(?ignoreNoteOffset:Bool = false):Void
	{
		var finishCallback:Void->Void = endSong; //In case you want to change it in a specific song.

		updateTime = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		vocals.pause();
		vocalsP2.volume = 0;
		vocalsP2.pause();
		if(ClientPrefs.noteOffset <= 0 || ignoreNoteOffset) {
			finishCallback();
		} else {
			finishTimer = new FlxTimer().start(ClientPrefs.noteOffset / 1000, function(tmr:FlxTimer) {
				finishCallback();
			});
		}
	}


	public var transitioning = false;
	public function endSong():Void
	{
		//Should kill you if you tried to cheat
		if(!startingSong) {
			notes.forEach(function(daNote:Note) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.05 * healthLoss;
				}
			});
			for (daNote in unspawnNotes) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.05 * healthLoss;
				}
			}

			if(doDeathCheck()) {
				return;
			}
		}

		timeBarBG.visible = false;
		timeBar.visible = false;
		falltime.visible = false;
		timeTxt.visible = false;
		canPause = false;
		endingSong = true;
		camZooming = false;
		inCutscene = false;
		updateTime = false;

		deathCounter = 0;
		seenCutscene = false;
		
		mobileControls.instance.visible = #if !android touchPad.visible = #end false;

		#if ACHIEVEMENTS_ALLOWED
		if(achievementObj != null) {
			return;
		} else {
			var achieve:String = checkForAchievement(['week1_nomiss', 'week2_nomiss', 'week3_nomiss', 'week4_nomiss',
				'week5_nomiss', 'week6_nomiss', 'week7_nomiss', 'ur_bad',
				'ur_good', 'hype', 'two_keys', 'toastie', 'debugger']);

			if(achieve != null) {
				startAchievement(achieve);
				return;
			}
		}
		#end
		
		#if LUA_ALLOWED
		var ret:Dynamic = callOnLuas('onEndSong', []);
		#else
		var ret:Dynamic = FunkinLua.Function_Continue;
		#end

		if(ret != FunkinLua.Function_Stop && !transitioning) {
			if (SONG.validScore)
			{
				#if !switch
				var percent:Float = ratingPercent;
				if(Math.isNaN(percent)) percent = 0;
				Highscore.saveScore(SONG.song, songScore, storyDifficulty, percent);
				#end
			}

			if (chartingMode)
			{
				openChartEditor();
				return;
			}

			if (isStoryMode)
			{
				campaignScore += songScore;
				campaignMisses += songMisses;

				storyPlaylist.remove(storyPlaylist[0]);

				if (storyPlaylist.length <= 0)
				{
					FlxG.sound.playMusic(Paths.music('freakyMenu'), 0.5);

					cancelMusicFadeTween();
					if(FlxTransitionableState.skipNextTransIn) {
						CustomFadeTransition.nextCamera = null;
					}
					MusicBeatState.switchState(new BackgroundState());

					// if ()
					if(!ClientPrefs.getGameplaySetting('practice', false) && !ClientPrefs.getGameplaySetting('botplay', false)) {
						StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);

						if (SONG.validScore)
						{
							Highscore.saveWeekScore(WeekData.getWeekFileName(), campaignScore, storyDifficulty);
						}

						FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
						FlxG.save.flush();
					}
					changedDifficulty = false;
				}
				else
				{
					var difficulty:String = CoolUtil.getDifficultyFilePath();

					trace('LOADING NEXT SONG');
					trace(Paths.formatToSongPath(PlayState.storyPlaylist[0]) + difficulty);

					var winterHorrorlandNext = (Paths.formatToSongPath(SONG.song) == "eggnog");
					if (winterHorrorlandNext)
					{
						var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
							-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
						blackShit.scrollFactor.set();
						add(blackShit);
						camHUD.visible = false;

						FlxG.sound.play(Paths.sound('Lights_Shut_off'));
					}

					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;

					prevCamFollow = camFollow;
					prevCamFollowPos = camFollowPos;

					PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0] + difficulty, PlayState.storyPlaylist[0]);
					FlxG.sound.music.stop();

					if(winterHorrorlandNext) {
						new FlxTimer().start(1.5, function(tmr:FlxTimer) {
							cancelMusicFadeTween();
							LoadingState.loadAndSwitchState(new PlayState());
						});
					} else {
						cancelMusicFadeTween();
						LoadingState.loadAndSwitchState(new PlayState());
					}
				}
			}
			else
			{
				trace('finished freeplay song');
				cancelMusicFadeTween();
				if(FlxTransitionableState.skipNextTransIn)
				{
					CustomFadeTransition.nextCamera = null;
				}
				MusicBeatState.switchState(new BackgroundState());
				FlxG.sound.playMusic(Paths.music('freakyMenu'), 0.5);
				changedDifficulty = false;
			}
			transitioning = true;
		}
	}

	#if ACHIEVEMENTS_ALLOWED
	var achievementObj:AchievementObject = null;
	function startAchievement(achieve:String) {
		achievementObj = new AchievementObject(achieve, camOther);
		achievementObj.onFinish = achievementEnd;
		add(achievementObj);
		trace('Giving achievement ' + achieve);
	}
	function achievementEnd():Void
	{
		achievementObj = null;
		if(endingSong && !inCutscene) {
			endSong();
		}
	}
	#end

	public function KillNotes() {
		while(notes.length > 0) {
			var daNote:Note = notes.members[0];
			daNote.active = false;
			daNote.visible = false;

			daNote.kill();
			notes.remove(daNote, true);
			daNote.destroy();
		}
		unspawnNotes = [];
		eventNotes = [];
	}

	public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0.0;

	public var showCombo:Bool = true;
	public var showRating:Bool = true;

	private function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		//trace('Pressed: ' + eventKey);

		if (!cpuControlled && !paused && key > -1 && (FlxG.keys.checkStatus(eventKey, JUST_PRESSED) || ClientPrefs.controllerMode))
		{
			if(!boyfriend.stunned && generatedMusic && !endingSong)
			{
				//more accurate hit time for the ratings?
				var lastTime:Float = Conductor.songPosition;
				Conductor.songPosition = FlxG.sound.music.time;

				var canMiss:Bool = !ClientPrefs.ghostTapping;

				// heavily based on my own code LOL if it aint broke dont fix it
				var pressNotes:Array<Note> = [];
				//var notesDatas:Array<Int> = [];
				var notesStopped:Bool = false;

				var sortedNotesList:Array<Note> = [];
				notes.forEachAlive(function(daNote:Note)
				{
					if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.isSustainNote)
					{
						if(daNote.noteData == key)
						{
							sortedNotesList.push(daNote);
							//notesDatas.push(daNote.noteData);
						}
						canMiss = true;
					}
				});
				sortedNotesList.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

				if (sortedNotesList.length > 0) {
					for (epicNote in sortedNotesList)
					{
						for (doubleNote in pressNotes) {
							if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 1) {
								doubleNote.kill();
								notes.remove(doubleNote, true);
								doubleNote.destroy();
							} else
								notesStopped = true;
						}
							
						// eee jack detection before was not super good
						if (!notesStopped) {
							goodNoteHit(epicNote);
							pressNotes.push(epicNote);
						}

					}
				}
				else if (canMiss) {
					noteMissPress(key);
					callOnLuas('noteMissPress', [key]);
				}

				// I dunno what you need this for but here you go
				//									- Shubs

				// Shubs, this is for the "Just the Two of Us" achievement lol
				//									- Shadow Mario
				keysPressed[key] = true;

				//more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
				Conductor.songPosition = lastTime;
			}

			var spr:StrumNote = playerStrums.members[key];
			if(spr != null && spr.animation.curAnim.name != 'confirm')
			{
				spr.playAnim('pressed');
				spr.resetAnim = 0;
			}
			callOnLuas('onKeyPress', [key]);
		}
		//trace('pressed: ' + controlArray);
	}
	
	private function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		if(!cpuControlled && !paused && key > -1)
		{
			var spr:StrumNote = playerStrums.members[key];
			if(spr != null)
			{
				spr.playAnim('static');
				spr.resetAnim = 0;
			}
			callOnLuas('onKeyRelease', [key]);
		}
		//trace('released: ' + controlArray);
	}

	private function getKeyFromEvent(key:FlxKey):Int
	{
		if(key != NONE)
		{
			for (i in 0...keysArray.length)
			{
				for (j in 0...keysArray[i].length)
				{
					if(key == keysArray[i][j])
					{
						return i;
					}
				}
			}
		}
		return -1;
	}

	private function onButtonPress(button:TouchButton):Void
	{
		if (button.IDs.filter(id -> id.toString().startsWith("EXTRA")).length > 0)
			return;

		var buttonCode:Int = (button.IDs[0].toString().startsWith('NOTE')) ? button.IDs[0] : button.IDs[1];

		if (!cpuControlled && startedCountdown && !paused && buttonCode > -1 && button.justPressed)
		{
		    if(!boyfriend.stunned && generatedMusic && !endingSong)
			{
				//more accurate hit time for the ratings?
				var lastTime:Float = Conductor.songPosition;
				Conductor.songPosition = FlxG.sound.music.time;

				var canMiss:Bool = !ClientPrefs.ghostTapping;

				// heavily based on my own code LOL if it aint broke dont fix it
				var pressNotes:Array<Note> = [];
				//var notesDatas:Array<Int> = [];
				var notesStopped:Bool = false;

				var sortedNotesList:Array<Note> = [];
				notes.forEachAlive(function(daNote:Note)
				{
					if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.isSustainNote)
					{
						if(daNote.noteData == buttonCode)
						{
							sortedNotesList.push(daNote);
							//notesDatas.push(daNote.noteData);
						}
						canMiss = true;
					}
				});
				sortedNotesList.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

				if (sortedNotesList.length > 0) {
					for (epicNote in sortedNotesList)
					{
						for (doubleNote in pressNotes) {
							if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 1) {
								doubleNote.kill();
								notes.remove(doubleNote, true);
								doubleNote.destroy();
							} else
								notesStopped = true;
						}
							
						// eee jack detection before was not super good
						if (!notesStopped) {
							goodNoteHit(epicNote);
							pressNotes.push(epicNote);
						}

					}
				}
				else if (canMiss) {
					noteMissPress(buttonCode);
					callOnLuas('noteMissPress', [buttonCode]);
				}

				// I dunno what you need this for but here you go
				//									- Shubs

				// Shubs, this is for the "Just the Two of Us" achievement lol
				//									- Shadow Mario
				keysPressed[buttonCode] = true;

				//more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
				Conductor.songPosition = lastTime;
			}

			var spr:StrumNote = playerStrums.members[buttonCode];
			if(spr != null && spr.animation.curAnim.name != 'confirm')
			{
				spr.playAnim('pressed');
				spr.resetAnim = 0;
			}
			callOnLuas('onKeyPress', [buttonCode]);
		}
	}

	private function onButtonRelease(button:TouchButton):Void
	{
		if (button.IDs.filter(id -> id.toString().startsWith("EXTRA")).length > 0)
			return;

		var buttonCode:Int = (button.IDs[0].toString().startsWith('NOTE')) ? button.IDs[0] : button.IDs[1];

		if (!cpuControlled && startedCountdown && !paused && buttonCode > -1)
		{
			var spr:StrumNote = playerStrums.members[buttonCode];
			if(spr != null)
			{
				spr.playAnim('static');
				spr.resetAnim = 0;
			}
			callOnLuas('onKeyRelease', [buttonCode]);
		}
	}
	
	// Hold notes
	private function keyShit():Void
	{
		// HOLDING
		var up = controls.NOTE_UP;
		var right = controls.NOTE_RIGHT;
		var down = controls.NOTE_DOWN;
		var left = controls.NOTE_LEFT;
		var controlHoldArray:Array<Bool> = [left, down, up, right];

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if(ClientPrefs.controllerMode)
		{
			var controlArray:Array<Bool> = [controls.NOTE_LEFT_P, controls.NOTE_DOWN_P, controls.NOTE_UP_P, controls.NOTE_RIGHT_P];
			if(controlArray.contains(true))
			{
				for (i in 0...controlArray.length)
				{
					if(controlArray[i])
						onKeyPress(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, -1, keysArray[i][0]));
				}
			}
		}

		// FlxG.watch.addQuick('asdfa', upP);
		if (!boyfriend.stunned && generatedMusic)
		{
			// rewritten inputs???
			notes.forEachAlive(function(daNote:Note)
			{
				// hold note functions
				if (daNote.isSustainNote && controlHoldArray[daNote.noteData] && daNote.canBeHit 
				&& daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit) {
					goodNoteHit(daNote);
				}
			});

			if (controlHoldArray.contains(true) && !endingSong) {
				#if ACHIEVEMENTS_ALLOWED
				var achieve:String = checkForAchievement(['oversinging']);
				if (achieve != null) {
					startAchievement(achieve);
				}
				#end
			}
			else if (boyfriend.holdTimer > Conductor.stepCrochet * 0.001 * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss'))
			{
				boyfriend.dance();
				//boyfriend.animation.curAnim.finish();
			}
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if(ClientPrefs.controllerMode)
		{
			var controlArray:Array<Bool> = [controls.NOTE_LEFT_R, controls.NOTE_DOWN_R, controls.NOTE_UP_R, controls.NOTE_RIGHT_R];
			if(controlArray.contains(true))
			{
				for (i in 0...controlArray.length)
				{
					if(controlArray[i])
						onKeyRelease(new KeyboardEvent(KeyboardEvent.KEY_UP, true, true, -1, keysArray[i][0]));
				}
			}
		}
	}

	function noteMiss(daNote:Note):Void { //You didn't hit the key and let it go offscreen, also used by Hurt Notes
		//Dupe note remove
		notes.forEachAlive(function(note:Note) {
			if (daNote != note && daNote.mustPress && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 1) {
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		});

		var char:Character = boyfriend;

		if (daNote.isSustainNote)
		{
			vocals.volume = 0;
			if (susNoteMissed == false)
			{
				susNoteMissed = true;
				
				health -= missHealth * 2;

				if(instakillOnMiss)
				{
					doDeathCheck(true);
				}
			}
		}
		else
		{
			susNoteMissed = false;

			if(daNote.noteType != 'Whirly Note')
			{
				combo = 0;
				
				if (daNote.noteType == 'Crown Note')
				{
					health -= missHealth * 4;

					camGame.shake(0.01, 0.5);

					if(boyfriend.animation.getByName('hurt') != null)
						{
							boyfriend.playAnim('hurt', true);
							boyfriend.specialAnim = true;
						}
					if(gf.animation.getByName('sad') != null)
						{
							gf.playAnim('sad', true);
							gf.specialAnim = true;
						}
				}
				else
				{
					health -= missHealth;
				}

				if(instakillOnMiss)
				{
					vocals.volume = 0;
					doDeathCheck(true);
				}

				songMisses++;
				vocals.volume = 0;
				if(!practiceMode) songScore -= 10;
		
				totalPlayed++;
				RecalculateRating();
			}

			var char:Character = boyfriend;
			if(daNote.gfNote)
			{
				char = gf;
			}
			
			if(daNote.noteType == 'Whirly Note')
			{
			}
			else if(daNote.noteType == 'Crown Note')
			{
				FlxG.sound.play(Paths.sound('goldmiss'), 0.5);
			}
			else if(daNote.noteType == 'Slime Note')
			{
			}
			else
			{
				FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), 0.2);
			}
		}

		if(char.hasMissAnimations && BFplayNoteAnims == true)
		{
			if(daNote.noteType == 'Whirly Note')
			{
			}
			else
			{
				var daAlt = '';
				if(daNote.noteType == 'Alt Animation') daAlt = '-alt';

				var animToPlay:String = singAnimations[Std.int(Math.abs(daNote.noteData))] + 'miss' + daAlt;
				char.playAnim(animToPlay, true);
			}
		}

		callOnLuas('noteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote]);
	}

	function noteMissPress(direction:Int = 1):Void //You pressed a key when there was no notes to press for this key
	{
		if (!boyfriend.stunned)
		{
			susNoteMissed = false;
			health -= 0.05 * healthLoss;
			if(instakillOnMiss)
			{
				vocals.volume = 0;
				doDeathCheck(true);
			}

			if(ClientPrefs.ghostTapping) return;

			if (combo > 5 && gf != null && gf.animOffsets.exists('sad'))
			{
				gf.playAnim('sad');
			}
			combo = 0;

			if(!practiceMode) songScore -= 10;
			if(!endingSong) {
				songMisses++;
			}
			totalPlayed++;
			RecalculateRating();

			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), 0.2);
			// FlxG.sound.play(Paths.sound('missnote1'), 1, false);
			// FlxG.log.add('played imss note');

			/*boyfriend.stunned = true;

			// get stunned for 1/60 of a second, makes you able to
			new FlxTimer().start(1 / 60, function(tmr:FlxTimer)
			{
				boyfriend.stunned = false;
			});*/

			if(boyfriend.hasMissAnimations && BFplayNoteAnims == true)
			{
				boyfriend.playAnim(singAnimations[Std.int(Math.abs(direction))] + 'miss', true);
			}
			vocals.volume = 0;
		}
	}

	function opponentNoteHit(note:Note):Void
	{
		if (Paths.formatToSongPath(SONG.song) != 'tutorial')
			camZooming = true;

		if (oppHealthDrain == true)
		{
			if (healthBar.percent >= 20)
			{
				if (note.isSustainNote)
				{
					health -= (healthDrain * healthGain) / 2.875;
				}
				else
				{
					health -= (healthDrain * healthGain);
				}
			}
		}

		if (playAsOpp == true)
		{
			if(!note.noAnimation)
			{
				var daAlt = '';
				if(note.noteType == 'Alt Animation') daAlt = '-alt';
	
				var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))];

				if(note.gfNote) 
				{
					if(gf != null)
					{
						gf.playAnim(animToPlay + daAlt, true);
						gf.holdTimer = 0;
					}
				}
				else
				{
					if (BFplayNoteAnims == true)
					{
						boyfriend.playAnim(animToPlay + daAlt, true);
						boyfriend.holdTimer = 0;
					}
				}

				if(note.noteType == 'Hey!') {
					if(boyfriend.animOffsets.exists('hey')) {
						boyfriend.playAnim('hey', true);
						boyfriend.specialAnim = true;
						boyfriend.heyTimer = 0.6;
					}
	
					if(gf != null && gf.animOffsets.exists('cheer')) {
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = 0.6;
					}
				}
			}
		}
		else
		{
			if(note.noteType == 'Hey!' && dad.animOffsets.exists('hey'))
			{
				dad.playAnim('hey', true);
				dad.specialAnim = true;
				dad.heyTimer = 0.6;
			}
			else if(!note.noAnimation)
			{
				var altAnim:String = "";

				var curSection:Int = Math.floor(curStep / 16);
				if (SONG.notes[curSection] != null)
				{
					if (SONG.notes[curSection].altAnim || note.noteType == 'Alt Animation') {
						altAnim = '-alt';
					}
				}

				var char:Character = dad;
				var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))] + altAnim;
				if(note.gfNote) {
					char = gf;
				}

				if(char != null && oppPlayNoteAnims == true)
				{
					char.playAnim(animToPlay, true);
					char.holdTimer = 0;
				}
			}
		}

		var time:Float = 0.15;
		if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end')) {
			time += 0.15;
		}
		StrumPlayAnim(true, Std.int(Math.abs(note.noteData)) % 4, time);
		note.hitByOpponent = true;

		callOnLuas('opponentNoteHit', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote]);

		if (!note.isSustainNote)
		{
			note.kill();
			notes.remove(note, true);
			note.destroy();
		}
	}

	function goodNoteHit(note:Note):Void
	{
		susNoteMissed = false;
		if (!note.wasGoodHit)
		{
			if (ClientPrefs.hitsoundVolume > 0 && !note.hitsoundDisabled)
			{
				FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.hitsoundVolume);
			}

			if(cpuControlled && (note.ignoreNote || note.hitCausesMiss)) return;
			
			//GOOD NOTES GO UNDER HERE

			if(note.noteType == 'Crown Note')
			{
				health += 0.2;

				if(gf.animation.getByName('cheer') != null)
				{
					gf.playAnim('cherr', true);
					gf.specialAnim = true;
				}
			}

			//BAD NOTES GO UNDER HERE

			if(note.hitCausesMiss)
			{
				noteMiss(note);
				if(!note.noteSplashDisabled && !note.isSustainNote)
				{
					spawnNoteSplashOnNote(note);
				}

				switch(note.noteType)
				{
					case 'Hurt Note': //Hurt note
						if(boyfriend.animation.getByName('hurt') != null) {
							boyfriend.playAnim('hurt', true);
							boyfriend.specialAnim = true;
						}
				}

				if(note.noteType == 'Slime Note')
				{
					health -= missHealth;
					FlxG.sound.play(Paths.sound('splat'));

					camGame.shake(0.01, 0.5);

					if(boyfriend.animation.getByName('hurt') != null)
						{
							boyfriend.playAnim('hurt', true);
							boyfriend.specialAnim = true;
						}
					if(gf.animation.getByName('sad') != null)
						{
							gf.playAnim('sad', true);
							gf.specialAnim = true;
						}
				}
				
				if(note.noteType == 'Whirly Note')
				{
					var char:Character = boyfriend;

					if (note.noteData == 0)
					{
						if (strumLineNotes.members[4].angle == 0)
						{
							FlxTween.tween(strumLineNotes.members[4], {angle: FlxG.random.float(75, 300)}, 0.5, {ease: FlxEase.bounceOut});
							whirlyLeftGood = true;

							combo = 0;

							if(instakillOnMiss)
							{
								doDeathCheck(true);
							}

							songMisses++;
							if(!practiceMode) songScore -= 10;
		
							totalPlayed++;
							RecalculateRating();

							FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), 0.2);
							
							if (gf.animation.getByName('sad') != null)
								{
									gf.playAnim('sad', true);
									gf.specialAnim = true;
								}
								
							var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))] + 'miss';
							char.playAnim(animToPlay, true);
						}
						else
						{
							FlxTween.tween(strumLineNotes.members[4], {angle: 0}, 0.5, {ease: FlxEase.bounceOut});
							FlxG.sound.play(Paths.sound('spin'), 0.5);
							vocals.volume = 1;
							whirlyLeftGood = false;
						}
					}
					if (note.noteData == 1)
					{
						if (strumLineNotes.members[5].angle == 0)
						{
							FlxTween.tween(strumLineNotes.members[5], {angle: FlxG.random.float(75, 300)}, 0.5, {ease: FlxEase.bounceOut});
							whirlyDownGood = true;
							
							combo = 0;

							if(instakillOnMiss)
							{
								doDeathCheck(true);
							}

							songMisses++;
							if(!practiceMode) songScore -= 10;
		
							totalPlayed++;
							RecalculateRating();

							FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), 0.2);
							
							if (gf.animation.getByName('sad') != null)
								{
									gf.playAnim('sad', true);
									gf.specialAnim = true;
								}

							var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))] + 'miss';
							char.playAnim(animToPlay, true);
						}
						else
						{
							FlxTween.tween(strumLineNotes.members[5], {angle: 0}, 0.5, {ease: FlxEase.bounceOut});
							FlxG.sound.play(Paths.sound('spin'), 0.5);
							vocals.volume = 1;
							whirlyDownGood = false;
						}
					}
					if (note.noteData == 2)
					{
						if (strumLineNotes.members[6].angle == 0)
						{
							FlxTween.tween(strumLineNotes.members[6], {angle: FlxG.random.float(75, 300)}, 0.5, {ease: FlxEase.bounceOut});
							whirlyUpGood = true;
							
							combo = 0;

							if(instakillOnMiss)
							{
								doDeathCheck(true);
							}

							songMisses++;
							if(!practiceMode) songScore -= 10;
		
							totalPlayed++;
							RecalculateRating();

							FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), 0.2);
							
							if (gf.animation.getByName('sad') != null)
								{
									gf.playAnim('sad', true);
									gf.specialAnim = true;
								}

							var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))] + 'miss';
							char.playAnim(animToPlay, true);
						}
						else
						{
							FlxTween.tween(strumLineNotes.members[6], {angle: 0}, 0.5, {ease: FlxEase.bounceOut});
							FlxG.sound.play(Paths.sound('spin'), 0.5);
							vocals.volume = 1;
							whirlyUpGood = false;
						}
					}
					if (note.noteData == 3)
					{
						if (strumLineNotes.members[7].angle == 0)
						{
							FlxTween.tween(strumLineNotes.members[7], {angle: FlxG.random.float(75, 300)}, 0.5, {ease: FlxEase.bounceOut});
							whirlyRightGood = true;
							
							combo = 0;

							if(instakillOnMiss)
							{
								doDeathCheck(true);
							}

							songMisses++;
							if(!practiceMode) songScore -= 10;
		
							totalPlayed++;
							RecalculateRating();

							FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), 0.2);
							
							if (gf.animation.getByName('sad') != null)
								{
									gf.playAnim('sad', true);
									gf.specialAnim = true;
								}

							var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))] + 'miss';
							char.playAnim(animToPlay, true);
						}
						else
						{
							FlxTween.tween(strumLineNotes.members[7], {angle: 0}, 0.5, {ease: FlxEase.bounceOut});
							FlxG.sound.play(Paths.sound('spin'), 0.5);
							vocals.volume = 1;
							whirlyRightGood = false;
						}
					}
				}
				
				note.wasGoodHit = true;
				if (!note.isSustainNote)
				{
					note.kill();
					notes.remove(note, true);
					note.destroy();
				}
				return;
			}

			if (!note.isSustainNote)
			{
				combo += 1;
				popUpScore(note);
				if(combo > 9999) combo = 9999;
			}
			if (note.isSustainNote)
			{
				health += (note.hitHealth * healthGain) / 2.875;
			}
			else
			{
				health += note.hitHealth * healthGain;
			}

			
			if (playAsOpp == true)
			{
				if(note.noteType == 'Hey!' && dad.animOffsets.exists('hey'))
				{
					dad.playAnim('hey', true);
					dad.specialAnim = true;
					dad.heyTimer = 0.6;
				}
				else if(!note.noAnimation)
				{
					var altAnim:String = "";

					var curSection:Int = Math.floor(curStep / 16);
					if (SONG.notes[curSection] != null)
					{
						if (SONG.notes[curSection].altAnim || note.noteType == 'Alt Animation') {
							altAnim = '-alt';
						}
					}

					var char:Character = dad;
					var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))] + altAnim;
					if(note.gfNote) {
						char = gf;
					}

					if(char != null && oppPlayNoteAnims == true)
					{
						char.playAnim(animToPlay, true);
						char.holdTimer = 0;
					}
				}
			}
			else
			{
				if(!note.noAnimation)
				{
					var daAlt = '';
					if(note.noteType == 'Alt Animation') daAlt = '-alt';
	
					var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))];

					if(note.gfNote) 
					{
						if(gf != null)
						{
							gf.playAnim(animToPlay + daAlt, true);
							gf.holdTimer = 0;
						}
					}
					else
					{
						if (BFplayNoteAnims == true)
						{
							if (curSong == 'Logic Funkin Collab' && FlxG.save.data.FGskin != "" && (animToPlay == 'singRIGHT' || animToPlay == 'singLEFT'))
							{
								if (animToPlay == 'singRIGHT')
								{
									boyfriend.playAnim('singLEFT', true);
									boyfriend.holdTimer = 0;
								}
								else if (animToPlay == 'singLEFT')
								{
									boyfriend.playAnim('singRIGHT', true);
									boyfriend.holdTimer = 0;
								}
							}
							else
							{
								boyfriend.playAnim(animToPlay + daAlt, true);
								boyfriend.holdTimer = 0;
							}
						}
					}

					if(note.noteType == 'Hey!') {
						if(boyfriend.animOffsets.exists('hey')) {
							boyfriend.playAnim('hey', true);
							boyfriend.specialAnim = true;
							boyfriend.heyTimer = 0.6;
						}
	
						if(gf != null && gf.animOffsets.exists('cheer')) {
							gf.playAnim('cheer', true);
							gf.specialAnim = true;
							gf.heyTimer = 0.6;
						}
					}
				}
			}

			if(cpuControlled) {
				var time:Float = 0.15;
				if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end')) {
					time += 0.15;
				}
				StrumPlayAnim(false, Std.int(Math.abs(note.noteData)) % 4, time);
			} else {
				playerStrums.forEach(function(spr:StrumNote)
				{
					if (Math.abs(note.noteData) == spr.ID)
					{
						spr.playAnim('confirm', true);
					}
				});
			}
			note.wasGoodHit = true;
			vocals.volume = 1;

			var isSus:Bool = note.isSustainNote; //GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
			var leData:Int = Math.round(Math.abs(note.noteData));
			var leType:String = note.noteType;
			callOnLuas('goodNoteHit', [notes.members.indexOf(note), leData, leType, isSus]);

			if (!note.isSustainNote)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		}
	}

	function spawnNoteSplashOnNote(note:Note) {
		if(ClientPrefs.noteSplashes && note != null) {
			var strum:StrumNote = playerStrums.members[note.noteData];
			if(strum != null) {
				spawnNoteSplash(strum.x, strum.y, note.noteData, note);
			}
		}
	}

	public function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null) {
		var skin:String = 'noteSplashes';
		if(PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) skin = PlayState.SONG.splashSkin;
		
		var hue:Float = ClientPrefs.arrowHSV[data % 4][0] / 360;
		var sat:Float = ClientPrefs.arrowHSV[data % 4][1] / 100;
		var brt:Float = ClientPrefs.arrowHSV[data % 4][2] / 100;
		if(note != null)
		{
			skin = note.noteSplashTexture;
			hue = note.noteSplashHue;
			sat = note.noteSplashSat;
			brt = note.noteSplashBrt;
		}

		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, data, skin, hue, sat, brt);
		grpNoteSplashes.add(splash);
	}

	var fastCarCanDrive:Bool = true;

	function resetFastCar():Void
	{
		fastCar.x = -12600;
		fastCar.y = FlxG.random.int(140, 250);
		fastCar.velocity.x = 0;
		fastCarCanDrive = true;
	}

	var carTimer:FlxTimer;
	function fastCarDrive()
	{
		//trace('Car drive');
		FlxG.sound.play(Paths.soundRandom('carPass', 0, 1), 0.7);

		fastCar.velocity.x = (FlxG.random.int(170, 220) / FlxG.elapsed) * 3;
		fastCarCanDrive = false;
		carTimer = new FlxTimer().start(2, function(tmr:FlxTimer)
		{
			resetFastCar();
			carTimer = null;
		});
	}

	var trainMoving:Bool = false;
	var trainFrameTiming:Float = 0;

	var trainCars:Int = 8;
	var trainFinishing:Bool = false;
	var trainCooldown:Int = 0;

	function trainStart():Void
	{
		trainMoving = true;
		if (!trainSound.playing)
			trainSound.play(true);
	}

	var startedMoving:Bool = false;

	function updateTrainPos():Void
	{
		if (trainSound.time >= 4700)
		{
			startedMoving = true;
			if (gf != null)
			{
				gf.playAnim('hairBlow');
				gf.specialAnim = true;
			}
		}

		if (startedMoving)
		{
			phillyTrain.x -= 400;

			if (phillyTrain.x < -2000 && !trainFinishing)
			{
				phillyTrain.x = -1150;
				trainCars -= 1;

				if (trainCars <= 0)
					trainFinishing = true;
			}

			if (phillyTrain.x < -4000 && trainFinishing)
				trainReset();
		}
	}

	function trainReset():Void
	{
		if(gf != null)
		{
			gf.danced = false; //Sets head to the correct position once the animation ends
			gf.playAnim('hairFall');
			gf.specialAnim = true;
		}
		phillyTrain.x = FlxG.width + 200;
		trainMoving = false;
		// trainSound.stop();
		// trainSound.time = 0;
		trainCars = 8;
		trainFinishing = false;
		startedMoving = false;
	}

	function lightningStrikeShit():Void
	{
		FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
		if(!ClientPrefs.lowQuality) halloweenBG.animation.play('halloweem bg lightning strike');

		lightningStrikeBeat = curBeat;
		lightningOffset = FlxG.random.int(8, 24);

		if(boyfriend.animOffsets.exists('scared')) {
			boyfriend.playAnim('scared', true);
		}

		if(gf != null && gf.animOffsets.exists('scared')) {
			gf.playAnim('scared', true);
		}

		if(ClientPrefs.camZooms) {
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;

			if(!camZooming) { //Just a way for preventing it to be permanently zoomed until Skid & Pump hits a note
				FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 0.5);
				FlxTween.tween(camHUD, {zoom: 1}, 0.5);
			}
		}

		if(ClientPrefs.flashing) {
			halloweenWhite.alpha = 0.4;
			FlxTween.tween(halloweenWhite, {alpha: 0.5}, 0.075);
			FlxTween.tween(halloweenWhite, {alpha: 0}, 0.25, {startDelay: 0.15});
		}
	}

	function killHenchmen():Void
	{
		if(!ClientPrefs.lowQuality && ClientPrefs.violence && curStage == 'limo') {
			if(limoKillingState < 1) {
				limoMetalPole.x = -400;
				limoMetalPole.visible = true;
				limoLight.visible = true;
				limoCorpse.visible = false;
				limoCorpseTwo.visible = false;
				limoKillingState = 1;

				#if ACHIEVEMENTS_ALLOWED
				Achievements.henchmenDeath++;
				FlxG.save.data.henchmenDeath = Achievements.henchmenDeath;
				var achieve:String = checkForAchievement(['roadkill_enthusiast']);
				if (achieve != null) {
					startAchievement(achieve);
				} else {
					FlxG.save.flush();
				}
				FlxG.log.add('Deaths: ' + Achievements.henchmenDeath);
				#end
			}
		}
	}

	function resetLimoKill():Void
	{
		if(curStage == 'limo') {
			limoMetalPole.x = -500;
			limoMetalPole.visible = false;
			limoLight.x = -500;
			limoLight.visible = false;
			limoCorpse.x = -500;
			limoCorpse.visible = false;
			limoCorpseTwo.x = -500;
			limoCorpseTwo.visible = false;
		}
	}

	private var preventLuaRemove:Bool = false;
	override function destroy() {
		preventLuaRemove = true;
		for (i in 0...luaArray.length) {
			luaArray[i].call('onDestroy', []);
			luaArray[i].stop();
		}
		luaArray = [];

		if(!ClientPrefs.controllerMode)
		{
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}
		super.destroy();
	}

	public static function cancelMusicFadeTween() {
		if(FlxG.sound.music.fadeTween != null) {
			FlxG.sound.music.fadeTween.cancel();
		}
		FlxG.sound.music.fadeTween = null;
	}

	public function removeLua(lua:FunkinLua) {
		if(luaArray != null && !preventLuaRemove) {
			luaArray.remove(lua);
		}
	}

	var lastStepHit:Int = -1;
	override function stepHit()
	{
		super.stepHit();
		if (Math.abs(FlxG.sound.music.time - (Conductor.songPosition - Conductor.offset)) > 20
			|| (SONG.needsVoices && Math.abs(vocals.time - (Conductor.songPosition - Conductor.offset)) > 20))
		{
			resyncVocals();
		}

		if(curStep == lastStepHit) {
			return;
		}

		lastStepHit = curStep;
		setOnLuas('curStep', curStep);
		callOnLuas('onStepHit', []);

		//PUT THE CODED IN MID-SONG EVENTS Events events DOWN HERE
		
		if (curSong == 'Free Falling')
		{
			switch (curStep)
			{
				case 32:
					cameraSpeed = 1;
					FlxTween.tween(FlxG.camera, {zoom: 0.9}, 1, {ease: FlxEase.quadInOut});
					defaultCamZoom = 0.9;
				case 64:
					defaultCamZoom = 0.7;
				case 384:
					defaultCamZoom = 0.8;
				case 432:
					defaultCamZoom = 0.9;
				case 440:
					defaultCamZoom = 1;
				case 452:
					defaultCamZoom = 0.5;
					isCameraOnForcedPos = false;
					camFollow.x = 400;
					camFollow.y = 400;
					isCameraOnForcedPos = true;
				case 570:
					isCameraOnForcedPos = false;
				case 576:
					defaultCamZoom = 1;
				case 592:
					defaultCamZoom = 0.6;
				case 608:
					defaultCamZoom = 1;
				case 624:
					defaultCamZoom = 0.6;
				case 640:
					defaultCamZoom = 0.5;
				case 688:
					defaultCamZoom = 0.6;
				case 704:
					defaultCamZoom = 0.8;
				case 736:
					defaultCamZoom = 0.7;
				case 768:
					defaultCamZoom = 0.8;
				case 800:
					defaultCamZoom = 0.9;
				case 816:
					defaultCamZoom = 1;

					var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
					introAssets.set('fall', ['fallmen/UI/starting', 'fallmen/UI/ready', 'fallmen/UI/set', 'fallmen/UI/go']);
					countdownStarting = new FlxSprite().loadGraphic(Paths.image(introAssets.get('fall')[0]));
					countdownStarting.scrollFactor.set();
					countdownStarting.cameras = [camHUD];
					countdownStarting.updateHitbox();

					countdownStarting.setGraphicSize(Std.int(countdownStarting.width * 0.6));

					countdownStarting.screenCenter();
					countdownStarting.antialiasing = ClientPrefs.globalAntialiasing;
					add(countdownStarting);
					FlxTween.tween(countdownStarting, {/*y: countdownStarting.y + 100,*/ alpha: 0}, 600 / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							remove(countdownStarting);
							countdownStarting.destroy();
						}
					});

				case 820:
						var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
						introAssets.set('fall', ['fallmen/UI/starting', 'fallmen/UI/ready', 'fallmen/UI/set', 'fallmen/UI/go']);
						countdownReady = new FlxSprite().loadGraphic(Paths.image(introAssets.get('fall')[1]));
						countdownReady.scrollFactor.set();
						countdownReady.cameras = [camHUD];
						countdownReady.updateHitbox();

						countdownReady.setGraphicSize(Std.int(countdownStarting.width * 0.6));

						countdownReady.screenCenter();
						countdownReady.antialiasing = ClientPrefs.globalAntialiasing;
						add(countdownReady);
						FlxTween.tween(countdownReady, {/*y: countdownReady.y + 100,*/ alpha: 0}, 600 / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownReady);
								countdownReady.destroy();
							}
						});

				case 824:
						var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
						introAssets.set('fall', ['fallmen/UI/starting', 'fallmen/UI/ready', 'fallmen/UI/set', 'fallmen/UI/go']);
						countdownSet = new FlxSprite().loadGraphic(Paths.image(introAssets.get('fall')[2]));
						countdownSet.cameras = [camHUD];
						countdownSet.scrollFactor.set();

						countdownSet.setGraphicSize(Std.int(countdownStarting.width * 0.6));

						countdownSet.screenCenter();
						countdownSet.antialiasing = ClientPrefs.globalAntialiasing;
						add(countdownSet);
						FlxTween.tween(countdownSet, {/*y: countdownSet.y + 100,*/ alpha: 0}, 600 / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownSet);
								countdownSet.destroy();
							}
						});

				case 828:
						FlxG.camera.flash(FlxColor.WHITE, 2);

						var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
						introAssets.set('fall', ['fallmen/UI/starting', 'fallmen/UI/ready', 'fallmen/UI/set', 'fallmen/UI/go']);
						countdownGo = new FlxSprite().loadGraphic(Paths.image(introAssets.get('fall')[3]));
						countdownGo.cameras = [camHUD];
						countdownGo.scrollFactor.set();

						countdownGo.setGraphicSize(Std.int(countdownStarting.width * 0.6));

						countdownGo.updateHitbox();

						countdownGo.screenCenter();
						countdownGo.antialiasing = ClientPrefs.globalAntialiasing;
						add(countdownGo);
						FlxTween.tween(countdownGo, {/*y: countdownGo.y + 100,*/ alpha: 0}, 600 / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownGo);
								countdownGo.destroy();
							}
						});

				case 832:
					defaultCamZoom = 0.7;
				case 960:
					defaultCamZoom = 0.6;
				case 1008:
					defaultCamZoom = 0.9;
				case 1024:
					defaultCamZoom = 0.7;
				case 1072:
					defaultCamZoom = 0.5;
				case 1092:
					isCameraOnForcedPos = false;
					camFollow.x = 400;
					camFollow.y = 400;
					isCameraOnForcedPos = true;
					defaultCamZoom = 0.45;
				case 1214:
					isCameraOnForcedPos = false;
				case 1216:
					cameraSpeed = 1/0;
					FlxTween.tween(FlxG.camera, {zoom: 0.9}, 0.001, {ease: FlxEase.quadInOut});
					defaultCamZoom = 0.9;
				case 1280:
					coverscreen.alpha = 1;
					canPause = false;
					inCutscene = true;
			}
		}

		if (curSong == 'Royal Rumble')
		{
			switch (curStep)
			{
				case 1200:
					FlxTween.tween(dadGroup, {angle: 360}, 0.1, {type: LOOPING});
					FlxTween.tween(dadGroup, {x: dadGroup.x + 2000}, 1);
					FlxTween.tween(dadGroup, {y: dadGroup.y + 3000}, 1);
			}
		}

		if (curSong == 'Better Bean')
		{
			switch (curStep)
			{
				case 1:
					isCameraOnForcedPos = false;
					camFollow.x = 650;
					camFollow.y = 600;
					isCameraOnForcedPos = true;

					FlxTween.tween(FlxG.camera, {zoom: 1}, 3, {ease: FlxEase.quadInOut});
					defaultCamZoom = 1;
					FlxTween.tween(coverscreen, {alpha: 0}, 3, {ease: FlxEase.quadInOut});
				case 287:
					isCameraOnForcedPos = false;
				case 575:
					isCameraOnForcedPos = false;
					camFollow.x = 650;
					camFollow.y = 600;
					isCameraOnForcedPos = true;
				case 607:
					isCameraOnForcedPos = false;
				case 672:
					FlxTween.tween(FlxG.camera, {zoom: 1.7}, 0.001, {ease: FlxEase.quadInOut});
					defaultCamZoom = 1.7;
				case 695:
					isCameraOnForcedPos = true;
					moveCamera(false);
					callOnLuas('onMoveCamera', ['boyfriend']);
				case 703:
					isCameraOnForcedPos = false;
				case 704:
					FlxTween.tween(FlxG.camera, {zoom: 1.7}, 0.001, {ease: FlxEase.quadInOut});
					defaultCamZoom = 1.7;
				case 735:
					isCameraOnForcedPos = false;
					camFollow.x = 650;
					camFollow.y = 600;
					isCameraOnForcedPos = true;
				case 736:
					FlxTween.tween(FlxG.camera, {zoom: 1}, 0.001, {ease: FlxEase.quadInOut});
					defaultCamZoom = 1;
				case 799:
					isCameraOnForcedPos = false;
				case 921:
					isCameraOnForcedPos = false;
					callOnLuas('onMoveCamera', ['boyfriend']);
					isCameraOnForcedPos = true;
				case 927:
					isCameraOnForcedPos = false;
				case 1055:
					isCameraOnForcedPos = false;
					camFollow.x = 650;
					camFollow.y = 600;
					isCameraOnForcedPos = true;
				case 1183:
					isCameraOnForcedPos = false;
				case 1503:
					isCameraOnForcedPos = false;
					camFollow.x = 650;
					camFollow.y = 600;
					isCameraOnForcedPos = true;
				case 1567:
					isCameraOnForcedPos = false;
				case 1664:
					isCameraOnForcedPos = false;
					camFollow.x = 650;
					camFollow.y = 600;
					isCameraOnForcedPos = true;
				case 1822:
					isCameraOnForcedPos = false;
				case 1983:
					isCameraOnForcedPos = false;
					camFollow.x = 650;
					camFollow.y = 600;
					isCameraOnForcedPos = true;
				case 2009:
					coverscreen.alpha = 1;
					coverscreenW.alpha = 1;
					FlxTween.tween(coverscreenW, {alpha: 0}, 1, {ease: FlxEase.quadInOut});
					canPause = false;
					inCutscene = true;
			}
		}

		if (curSong == 'Short Circut')
		{
			switch (curStep)
			{
				case 1:
					isCameraOnForcedPos = false;
					camFollow.x = 550;
					camFollow.y = 550;
					isCameraOnForcedPos = true;

					FlxTween.tween(FlxG.camera, {zoom: 0.6}, 1.7, {ease: FlxEase.quadInOut});
					defaultCamZoom = 0.6;
					FlxTween.tween(coverscreen, {alpha: 0}, 1.7, {ease: FlxEase.quadInOut});
				case 16:
					FlxG.camera.flash(FlxColor.WHITE, 1);
					shortCircutsBlue.alpha = 1;
				case 144:
					FlxG.camera.flash(FlxColor.WHITE, 1);
				case 276:
					FlxG.camera.flash(FlxColor.WHITE, 1);
				case 340:
					FlxG.camera.flash(FlxColor.WHITE, 1);
				case 400:
					FlxG.camera.flash(FlxColor.WHITE, 1);
				case 464:
					FlxG.camera.flash(FlxColor.WHITE, 1);
				case 528:
					FlxG.camera.flash(FlxColor.WHITE, 1);
				case 592:
					FlxG.camera.flash(FlxColor.WHITE, 1);
				case 656:
					FlxG.camera.flash(FlxColor.WHITE, 1);
				case 724:
					FlxG.camera.flash(FlxColor.WHITE, 1);
				case 852:
					FlxG.camera.flash(FlxColor.WHITE, 1);
				case 912:
					FlxG.camera.flash(FlxColor.WHITE, 1);
				case 1040:
					FlxG.camera.flash(FlxColor.WHITE, 1);
				case 1108:
					FlxG.camera.flash(FlxColor.WHITE, 1);
				case 1232:
					FlxG.camera.flash(FlxColor.WHITE, 1);
				case 1296:
					coverscreenW.color = FlxColor.RED;
					coverscreenW.alpha = 1;
					FlxTween.tween(coverscreenW, {alpha: 0}, 2, {ease: FlxEase.quadInOut});
					fallinBackdrop.loadGraphic(Paths.image('fallmen/Stages/shortcircut red'));
					shortCircutsBlue.alpha = 0;
					shortCircutsRed.alpha = 1;
					boyfriendGroup.color = 0xFF995757;
					dadGroup.color = 0xFFFF5E5E;
					gfGroup.color = 0xFF995757;
					oppHealthDrain = true;
				case 1424:
					FlxG.camera.flash(FlxColor.RED, 1);
				case 1552:
					FlxG.camera.flash(FlxColor.RED, 1);
				case 1620:
					FlxG.camera.flash(FlxColor.RED, 1);
				case 1680:
					FlxG.camera.flash(FlxColor.RED, 1);
				case 1748:
					FlxG.camera.flash(FlxColor.RED, 1);
				case 1804:
					FlxTween.tween(FlxG.camera, {zoom: 0.7}, 0.001, {ease: FlxEase.quadInOut});
					defaultCamZoom = 0.7;
				case 1805:
					FlxTween.tween(FlxG.camera, {zoom: 0.8}, 0.001, {ease: FlxEase.quadInOut});
					defaultCamZoom = 0.8;
				case 1806:
					FlxTween.tween(FlxG.camera, {zoom: 0.9}, 0.001, {ease: FlxEase.quadInOut});
					defaultCamZoom = 0.9;
				case 1807:
					FlxTween.tween(FlxG.camera, {zoom: 1}, 0.001, {ease: FlxEase.quadInOut});
					defaultCamZoom = 1;
				case 1808:
					coverscreenW.color = FlxColor.RED;
					coverscreen.alpha = 1;
					coverscreenW.alpha = 1;
					FlxTween.tween(coverscreenW, {alpha: 0}, 1, {ease: FlxEase.quadInOut});
					canPause = false;
				case 1809:
					inCutscene = true;
			}
		}
	}

	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;

	var lastBeatHit:Int = -1;
	
	override function beatHit()
	{
		super.beatHit();

		if(lastBeatHit >= curBeat) {
			//trace('BEAT HIT: ' + curBeat + ', LAST HIT: ' + lastBeatHit);
			return;
		}

		if (generatedMusic)
		{
			notes.sort(FlxSort.byY, ClientPrefs.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
		}

		if (SONG.notes[Math.floor(curStep / 16)] != null)
		{
			if (SONG.notes[Math.floor(curStep / 16)].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[Math.floor(curStep / 16)].bpm);
				//FlxG.log.add('CHANGED BPM!');
				setOnLuas('curBpm', Conductor.bpm);
				setOnLuas('crochet', Conductor.crochet);
				setOnLuas('stepCrochet', Conductor.stepCrochet);
			}
			setOnLuas('mustHitSection', SONG.notes[Math.floor(curStep / 16)].mustHitSection);
			setOnLuas('altAnim', SONG.notes[Math.floor(curStep / 16)].altAnim);
			setOnLuas('gfSection', SONG.notes[Math.floor(curStep / 16)].gfSection);
			// else
			// Conductor.changeBPM(SONG.bpm);
		}
		// FlxG.log.add('change bpm' + SONG.notes[Std.int(curStep / 16)].changeBPM);

		if (generatedMusic && PlayState.SONG.notes[Std.int(curStep / 16)] != null && !endingSong && !isCameraOnForcedPos)
		{
			moveCameraSection(Std.int(curStep / 16));
		}
		if (camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms && curBeat % 4 == 0)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;
		}

		//ICON BUMP ANIMATIONS

		iconP1.scale.set(1.2, 1.2);
		iconP2.scale.set(1.2, 1.2);

		iconP1.updateHitbox();
		iconP2.updateHitbox();
		
		if (gf != null && curBeat % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && !gf.stunned && gf.animation.curAnim.name != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned)
		{
			gf.dance();
		}
		if (curBeat % boyfriend.danceEveryNumBeats == 0 && boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.stunned)
		{
			boyfriend.dance();
		}
		if (curBeat % dad.danceEveryNumBeats == 0 && dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned)
		{
			dad.dance();
		}

		switch (curStage)
		{
			case 'blastball':
				if(!ClientPrefs.lowQuality)
				{
					if (bopped == false)
					{
						logicBoppers.dance(true);
						bopped = true;
					}
					else
					{
						bopped = false;
					}
				}

			case 'school':
				if(!ClientPrefs.lowQuality) {
					bgGirls.dance();
				}

			case 'mall':
				if(!ClientPrefs.lowQuality) {
					upperBoppers.dance(true);
				}

				if(heyTimer <= 0) bottomBoppers.dance(true);
				santa.dance(true);

			case 'limo':
				if(!ClientPrefs.lowQuality) {
					grpLimoDancers.forEach(function(dancer:BackgroundDancer)
					{
						dancer.dance();
					});
				}

				if (FlxG.random.bool(10) && fastCarCanDrive)
					fastCarDrive();
			case "philly":
				if (!trainMoving)
					trainCooldown += 1;

				if (curBeat % 4 == 0)
				{
					phillyCityLights.forEach(function(light:BGSprite)
					{
						light.visible = false;
					});

					curLight = FlxG.random.int(0, phillyCityLights.length - 1, [curLight]);

					phillyCityLights.members[curLight].visible = true;
					phillyCityLights.members[curLight].alpha = 1;
				}

				if (curBeat % 8 == 4 && FlxG.random.bool(30) && !trainMoving && trainCooldown > 8)
				{
					trainCooldown = FlxG.random.int(-4, 0);
					trainStart();
				}
		}

		if (curStage == 'spooky' && FlxG.random.bool(10) && curBeat > lightningStrikeBeat + lightningOffset)
		{
			lightningStrikeShit();
		}
		lastBeatHit = curBeat;

		setOnLuas('curBeat', curBeat); //DAWGG?????
		callOnLuas('onBeatHit', []);
	}

	public var closeLuas:Array<FunkinLua> = [];
	public function callOnLuas(event:String, args:Array<Dynamic>):Dynamic {
		var returnVal:Dynamic = FunkinLua.Function_Continue;
		#if LUA_ALLOWED
		for (i in 0...luaArray.length) {
			var ret:Dynamic = luaArray[i].call(event, args);
			if(ret != FunkinLua.Function_Continue) {
				returnVal = ret;
			}
		}

		for (i in 0...closeLuas.length) {
			luaArray.remove(closeLuas[i]);
			closeLuas[i].stop();
		}
		#end
		return returnVal;
	}

	public function setOnLuas(variable:String, arg:Dynamic) {
		#if LUA_ALLOWED
		for (i in 0...luaArray.length) {
			luaArray[i].set(variable, arg);
		}
		#end
	}

	function StrumPlayAnim(isDad:Bool, id:Int, time:Float) {
		var spr:StrumNote = null;
		if(isDad) {
			spr = strumLineNotes.members[id];
		} else {
			spr = playerStrums.members[id];
		}

		if(spr != null) {
			spr.playAnim('confirm', true);
			spr.resetAnim = time;
		}
	}

	public var ratingName:String = '?';
	public var ratingPercent:Float;
	public var ratingFC:String;
	public function RecalculateRating() {
		setOnLuas('score', songScore);
		setOnLuas('misses', songMisses);
		setOnLuas('hits', songHits);

		var ret:Dynamic = callOnLuas('onRecalculateRating', []);
		if(ret != FunkinLua.Function_Stop)
		{
			if(totalPlayed < 1) //Prevent divide by 0
				ratingName = '?';
			else
			{
				// Rating Percent
				ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));
				//trace((totalNotesHit / totalPlayed) + ', Total: ' + totalPlayed + ', notes hit: ' + totalNotesHit);

				// Rating Name
				if(ratingPercent >= 1)
				{
					ratingName = ratingStuff[ratingStuff.length-1][0]; //Uses last string
				}
				else
				{
					for (i in 0...ratingStuff.length-1)
					{
						if(ratingPercent < ratingStuff[i][1])
						{
							ratingName = ratingStuff[i][0];
							break;
						}
					}
				}
			}

			// Rating FC
			ratingFC = "";
			if (sicks > 0) ratingFC = "SFC";
			if (goods > 0) ratingFC = "GFC";
			if (bads > 0 || shits > 0) ratingFC = "FC";
			if (songMisses > 0 && songMisses < 10) ratingFC = "SDCB";
			else if (songMisses >= 10) ratingFC = "Clear";
		}
		setOnLuas('rating', ratingPercent);
		setOnLuas('ratingName', ratingName);
		setOnLuas('ratingFC', ratingFC);
	}

	#if ACHIEVEMENTS_ALLOWED
	private function checkForAchievement(achievesToCheck:Array<String> = null):String
	{
		if(chartingMode) return null;

		var usedPractice:Bool = (ClientPrefs.getGameplaySetting('practice', false) || ClientPrefs.getGameplaySetting('botplay', false));
		for (i in 0...achievesToCheck.length) {
			var achievementName:String = achievesToCheck[i];
			if(!Achievements.isAchievementUnlocked(achievementName) && !cpuControlled) {
				var unlock:Bool = false;
				switch(achievementName)
				{
					case 'week1_nomiss' | 'week2_nomiss' | 'week3_nomiss' | 'week4_nomiss' | 'week5_nomiss' | 'week6_nomiss' | 'week7_nomiss':
						if(isStoryMode && campaignMisses + songMisses < 1 && CoolUtil.difficultyString() == 'HARD' && storyPlaylist.length <= 1 && !changedDifficulty && !usedPractice)
						{
							var weekName:String = WeekData.getWeekFileName();
							switch(weekName) //I know this is a lot of duplicated code, but it's easier readable and you can add weeks with different names than the achievement tag
							{
								case 'week1':
									if(achievementName == 'week1_nomiss') unlock = true;
								case 'week2':
									if(achievementName == 'week2_nomiss') unlock = true;
								case 'week3':
									if(achievementName == 'week3_nomiss') unlock = true;
								case 'week4':
									if(achievementName == 'week4_nomiss') unlock = true;
								case 'week5':
									if(achievementName == 'week5_nomiss') unlock = true;
								case 'week6':
									if(achievementName == 'week6_nomiss') unlock = true;
								case 'week7':
									if(achievementName == 'week7_nomiss') unlock = true;
							}
						}
					case 'ur_bad':
						if(ratingPercent < 0.2 && !practiceMode) {
							unlock = true;
						}
					case 'ur_good':
						if(ratingPercent >= 1 && !usedPractice) {
							unlock = true;
						}
					case 'roadkill_enthusiast':
						if(Achievements.henchmenDeath >= 100) {
							unlock = true;
						}
					case 'oversinging':
						if(boyfriend.holdTimer >= 10 && !usedPractice) {
							unlock = true;
						}
					case 'hype':
						if(!boyfriendIdled && !usedPractice) {
							unlock = true;
						}
					case 'two_keys':
						if(!usedPractice) {
							var howManyPresses:Int = 0;
							for (j in 0...keysPressed.length) {
								if(keysPressed[j]) howManyPresses++;
							}

							if(howManyPresses <= 2) {
								unlock = true;
							}
						}
					case 'toastie':
						if(/*ClientPrefs.framerate <= 60 &&*/ ClientPrefs.lowQuality && !ClientPrefs.globalAntialiasing && !ClientPrefs.imagesPersist) {
							unlock = true;
						}
					case 'debugger':
						if(Paths.formatToSongPath(SONG.song) == 'test' && !usedPractice) {
							unlock = true;
						}
				}

				if(unlock) {
					Achievements.unlockAchievement(achievementName);
					return achievementName;
				}
			}
		}
		return null;
	}
	#end

	var curLight:Int = 0;
	var curLightEvent:Int = 0;
}
