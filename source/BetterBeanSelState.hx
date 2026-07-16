package;

#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.addons.display.FlxBackdrop;
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
import editors.MasterEditorMenu;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxTimer;
import flixel.util.FlxGradient;

using StringTools;

class BetterBeanSelState extends MusicBeatState
{
	var curSelected:Int = 0;
	
	var transitioning:Bool = true;

	var backBoard:FlxSprite;
	var coverscreen:FlxSprite;

	var fallGuy:FlxSprite;
	var crewmate:FlxSprite;

	var chooseText:FlxText;
	var enterText:FlxText;

	var menuItems:FlxTypedGroup<FlxSprite>;
	private var camGame:FlxCamera;
	private var camAchievement:FlxCamera;

	var camFollow:FlxObject;
	var camFollowPos:FlxObject;

	override function create()
	{
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end
		
		camGame = new FlxCamera();
		camAchievement = new FlxCamera();
		camAchievement.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camAchievement);
		FlxCamera.defaultCameras = [camGame];

		persistentUpdate = persistentDraw = true;

		BackgroundState.transitionFromNonMenu = true;
		
		FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
		
		backBoard = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		backBoard.alpha = 1;
		add(backBoard);

		fallGuy = new FlxSprite(13, 0);
		fallGuy.scrollFactor.set();
		fallGuy.frames = Paths.getSparrowAtlas('fallmen/UI/Menu/Better Bean/fallguy');
		fallGuy.animation.addByPrefix('idle', "fgIdle", 24, true);
		fallGuy.animation.addByPrefix('selected', "fgSelected", 24, false);
		fallGuy.animation.play('idle');
		fallGuy.antialiasing = ClientPrefs.globalAntialiasing;
		add(fallGuy);

		crewmate = new FlxSprite(612, 4);
		crewmate.scrollFactor.set();
		crewmate.frames = Paths.getSparrowAtlas('fallmen/UI/Menu/Better Bean/crewmate');
		crewmate.animation.addByPrefix('idle', "susIdle", 24, true);
		crewmate.animation.addByPrefix('selected', "susSelected", 24, false);
		crewmate.animation.play('idle');
		crewmate.antialiasing = ClientPrefs.globalAntialiasing;
		add(crewmate);

		chooseText = new FlxText(0, 613, FlxG.width, "Choose the better bean.");
		chooseText.setFormat(Paths.font("vcr.ttf"), 40, FlxColor.WHITE, CENTER);
		chooseText.antialiasing = ClientPrefs.globalAntialiasing;
		chooseText.scrollFactor.set();
		chooseText.screenCenter(X);
		add(chooseText);

		enterText = new FlxText(0, 661, FlxG.width, "Press ENTER");
		enterText.setFormat(Paths.font("vcr.ttf"), 40, 0xFFFFFF9B, CENTER);
		enterText.antialiasing = ClientPrefs.globalAntialiasing;
		enterText.scrollFactor.set();
		enterText.screenCenter(X);
		enterText.alpha = 0;
		add(enterText);

		coverscreen = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		coverscreen.alpha = 1;
		add(coverscreen);
		
		FlxTween.tween(coverscreen, {alpha: 0}, 0.5, {startDelay: 1, ease: FlxEase.quadInOut,
		onComplete: function(twn:FlxTween)
			{
				transitioning = false;
			}
		});

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);

		addTouchPad("LEFT_RIGHT", "A_B");
		addTouchPadCamera();
		
		super.create();
	}

	override function update(elapsed:Float)
	{
		if (FlxG.keys.justPressed.F)
		{
			FlxG.fullscreen = !FlxG.fullscreen;
		}
		
		if (transitioning == false)
		{
			if (controls.UI_RIGHT_P && curSelected != 1)
			{
				FlxG.sound.play(Paths.sound('betterBeanScroll'));
				PlayState.theBetterBean = "crewmate";
				curSelected = 1;
				fallGuy.animation.play('idle');
				crewmate.animation.play('selected');
				enterText.alpha = 1;
			}
			
			if (controls.UI_LEFT_P && curSelected != 2)
			{
				FlxG.sound.play(Paths.sound('betterBeanScroll'));
				PlayState.theBetterBean = "fallguy";
				curSelected = 2;
				crewmate.animation.play('idle');
				fallGuy.animation.play('selected');
				enterText.alpha = 1;
			}

			if (controls.ACCEPT && curSelected != 0)
			{
				transitioning = true;
				coverscreen.alpha = 1;
				FlxG.sound.play(Paths.sound('Lights_Shut_off'));
				new FlxTimer().start(2, function(tmr:FlxTimer)
				{
					LoadingState.loadAndSwitchState(new PlayState());
				});
			}

			if (controls.BACK)
			{
				transitioning = true;
				coverscreen.alpha = 1;
				FlxG.sound.play(Paths.sound('Lights_Shut_off'));
				
				new FlxTimer().start(2, function(tmr:FlxTimer)
				{
					FlxG.sound.playMusic(Paths.music('freakyMenu'), 0.5);
					MusicBeatState.switchState(new BackgroundState());
				});
			}
		}

		super.update(elapsed);
	}
}
