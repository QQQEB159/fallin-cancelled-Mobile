package;

import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.FlxCamera;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.input.keyboard.FlxKeyboard;
import flixel.input.keyboard.FlxKey;
import lime.utils.Assets;
import openfl.utils.Assets as OpenFlAssets;
import flixel.util.FlxTimer;


#if windows
import Discord.DiscordClient;
#end

using StringTools;

class FreeplayState extends MusicBeatSubstate
{
	var songs:Array<SongMetadata> = [];

	public static var curSelected:Int = 0;

	public static var selectedSong:Int = -1;

	public static var kudoXslide:Bool;

	public static var universalPoop:String;
	public static var freeplaySongName:String;
	
	var selectedSomethin:Bool = false;

	var scoreBG:FlxSprite;
	public static var scoreMedal:FlxSprite;
	public static var curDifficulty:Int = 2;
	var weekbeaten:Int = 1;
	public static var scoreText:FlxText;
	public static var diffText:FlxText;
	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;
	public static var songNameText:FlxText;
	public static var shmoreText:FlxText;
	public static var creditText:FlxText;
	public static var logicText:FlxText;

	public static var leftArrow:FlxSprite;
	public static var rightArrow:FlxSprite;

	public static var kudoBack:FlxSprite;
	public static var kudoText:FlxText;
	public static var kudo:FlxSprite;

	public static var coverscreen:FlxSprite;

	var camFollow:FlxObject;
	var camFollowPos:FlxObject;
	
	private var curPlaying:Bool = false;
	private static var lastDifficultyName:String = '';
	private var camGame:FlxCamera;

	public static var menuItems:FlxTypedGroup<FlxSprite>;
	public static var menuItem:FlxSprite;

	override function create()
	{
		var Song1:String = 'Free Falling';
		var Song2:String = 'Splash Zone';
		var Song3:String = 'Royal Rumble';
		var Song4:String = 'Stringbean';
		var Song5:String = 'Logic Funkin Collab';
		var Song6:String = 'Better Bean';
		var Song7:String = 'Short Circut';

		var initSonglist:Array<String> = [Song1, Song2, Song3, Song4, Song5, Song6, Song7, ''];

		for (i in 0...initSonglist.length)
		{
			var data:Array<String> = initSonglist[i].split(':');
			songs.push(new SongMetadata(data[0], Std.parseInt(data[2]), data[1]));
		}
		
		camGame = new FlxCamera();

		FlxG.cameras.reset(camGame);
		FlxCamera.defaultCameras = [camGame];

		 #if windows
		 // Updating Discord Rich Presence
		 DiscordClient.changePresence("In the Freeplay Menu", null);
		 #end

		var isDebug:Bool = false;

		#if debug
		isDebug = true;
		#end

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		FlxG.mouse.visible = false;

		var scale:Float = 1;

		for (i in 0...initSonglist.length - 1)
		{
			var offset:Float = 108 - (Math.max(initSonglist.length, 4) - 4) * 80;
			menuItem = new FlxSprite(0, (i * 140) + offset);
			menuItem.scrollFactor.x = 1;
			menuItem.scrollFactor.y = 0;
			menuItem.scale.x = scale;
			menuItem.scale.y = scale;
			menuItem.frames = Paths.getSparrowAtlas('fallmen/UI/Menu/Freeplay/songButtons/' + initSonglist[i]);
			menuItem.animation.addByPrefix('idle', "idle", 24);
			menuItem.animation.addByPrefix('selected', "select", 24);
			menuItem.animation.addByPrefix('press', "press", 13, false);
			menuItem.animation.play('idle');
			menuItem.ID = i;
			menuItem.screenCenter(X);
			menuItems.add(menuItem);
			var scr:Float = (initSonglist.length - 4) * 0.135;
			menuItem.antialiasing = ClientPrefs.globalAntialiasing;
			FlxTween.tween(menuItem,{x: 379 + (i * 500)}, 0.000001, {ease: FlxEase.expoInOut});
			menuItem.updateHitbox();
		}

		menuItems.forEach(function(spr:FlxSprite)
		{
			if (selectedSong == -1)
			{
				if (spr.ID == curSelected)
				{
					spr.animation.play('idle');
					spr.updateHitbox();
					camFollow.setPosition(spr.getGraphicMidpoint().x, spr.getGraphicMidpoint().y);
					FlxG.camera.follow(spr, null, 1);
					camFollow.setPosition(spr.getGraphicMidpoint().x, spr.getGraphicMidpoint().y);
					spr.centerOffsets();
					spr.updateHitbox();
				}
				else
				{
					spr.animation.play('idle');
					spr.updateHitbox();
				}
			}
			else
			{
				curSelected = selectedSong;
				if (spr.ID == selectedSong)
				{
					spr.animation.play('selected');
					spr.updateHitbox();
					camFollow.setPosition(spr.getGraphicMidpoint().x, spr.getGraphicMidpoint().y);
					FlxG.camera.follow(spr, null, 1);
					camFollow.setPosition(spr.getGraphicMidpoint().x, spr.getGraphicMidpoint().y);
					spr.centerOffsets();
					spr.updateHitbox();
				}
				else
				{
					spr.animation.play('idle');
					spr.updateHitbox();
				}
			}
		});
		
		shmoreText = new FlxText(0, 0, FlxG.width, "", 12);
		shmoreText.scrollFactor.set();
		shmoreText.setFormat(Paths.font("fall.ttf"), 0, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE);
		shmoreText.antialiasing = ClientPrefs.globalAntialiasing;
		shmoreText.y = 500;
		shmoreText.borderSize = 3;
		shmoreText.borderColor = 0xFFFF00A4;
		shmoreText.size = 32;
		shmoreText.screenCenter(X);
		
		creditText = new FlxText(0, 0, FlxG.width, "", 12);
		creditText.scrollFactor.set();
		creditText.setFormat(Paths.font("fall.ttf"), 0, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE);
		creditText.antialiasing = ClientPrefs.globalAntialiasing;
		creditText.y = 460;
		creditText.borderSize = 3;
		creditText.borderColor = 0xFFFF00A4;
		creditText.size = 27;
		creditText.screenCenter(X);

		logicText = new FlxText(840, 550, 440, "", 12);
		logicText.scrollFactor.set();
		logicText.setFormat(Paths.font("fall.ttf"), 0, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE);
		logicText.antialiasing = ClientPrefs.globalAntialiasing;
		logicText.borderSize = 3;
		logicText.borderColor = 0xFF33C9EA;
		logicText.size = 23;

		//IGNORE scoreText THIS IT'S GLITCHED OUT FOR SOME REASON
		//USE shmoreText INSTEAD
		scoreText = new FlxText(FlxG.width * 0.7, 5, 1000, "", 25);
		scoreText.scrollFactor.set(0, 0);
		scoreText.setFormat(Paths.font("fall.ttf"), 25, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE);
		scoreText.antialiasing = ClientPrefs.globalAntialiasing;
		scoreText.y = 360 - 130 - 35;
		scoreText.borderSize = 2;
		scoreText.alpha = 0;

		scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 66, 0xFF000000);
		scoreBG.alpha = 0;
		add(scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "");
		diffText.scrollFactor.set(0, 0);
		diffText.setFormat(Paths.font("fall.ttf"), 45, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE);
		diffText.borderStyle = FlxTextBorderStyle.OUTLINE;
		diffText.y = shmoreText.y + 40;
		diffText.borderSize = 3;
		diffText.antialiasing = ClientPrefs.globalAntialiasing;
		add(diffText);

		add(scoreText);
		add(shmoreText);
		add(creditText);
		add(logicText);

		if(curSelected >= songs.length) curSelected = 0;
		
		changeSelection();
		changeDiff();

		// FlxG.sound.playMusic(Paths.music('title'), 0);
		// FlxG.sound.music.fadeIn(2, 0, 0.8);

		scoreMedal = new FlxSprite(476, 588);
		scoreMedal.loadGraphic(Paths.image('fallmen/UI/Menu/Freeplay/medalPurple'));
		scoreMedal.scrollFactor.set();
		scoreMedal.antialiasing = ClientPrefs.globalAntialiasing;
		add(scoreMedal);

		leftArrow = new FlxSprite(346, 181);
		leftArrow.scrollFactor.set();
		leftArrow.antialiasing = ClientPrefs.globalAntialiasing;
		leftArrow.frames = Paths.getSparrowAtlas('fallmen/UI/Menu/menu_arrows');
		leftArrow.animation.addByPrefix('idle', "left_arrow-idle", 24, true);
		leftArrow.animation.addByPrefix('press', "left_arrow-press", 24, true);
		leftArrow.animation.play('idle');
		add(leftArrow);

		rightArrow = new FlxSprite(863, 181);
		rightArrow.scrollFactor.set();
		rightArrow.antialiasing = ClientPrefs.globalAntialiasing;
		rightArrow.frames = Paths.getSparrowAtlas('fallmen/UI/Menu/menu_arrows');
		rightArrow.animation.addByPrefix('idle', "right_arrow-idle", 24, true);
		rightArrow.animation.addByPrefix('press', "right_arrow-press", 24, true);
		rightArrow.animation.play('idle');
		add(rightArrow);
		
		songNameText = new FlxText(0, 0, FlxG.width, "", 12);
		songNameText.scrollFactor.set();
		songNameText.setFormat(Paths.font("fall.ttf"), 0, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE);
		songNameText.antialiasing = ClientPrefs.globalAntialiasing;
		songNameText.screenCenter(X);
		songNameText.borderColor = 0xFFFF00A4;
		songNameText.borderSize = 4;
		songNameText.size = 70;
		add(songNameText);

		kudoBack = new FlxSprite(907 + 176, 21).loadGraphic(Paths.image('fallmen/UI/Menu/kudoback'));
		kudoBack.scrollFactor.set();
		kudoBack.updateHitbox();
		kudoBack.antialiasing = ClientPrefs.globalAntialiasing;
		add(kudoBack);

		kudoText = new FlxText(968 + 176, 25, 200, FlxG.save.data.kudosAHETSRYJDTUFKYGJLBVKJKGCYFILGKVJ);
		kudoText.scrollFactor.set();
		kudoText.setFormat(Paths.font("fall.ttf"), 22, FlxColor.WHITE, LEFT);
		kudoText.antialiasing = ClientPrefs.globalAntialiasing;
		add(kudoText);

		kudo = new FlxSprite(890 + 176, 7).loadGraphic(Paths.image('fallmen/UI/Menu/kudo'));
		kudo.scrollFactor.set();
		kudo.updateHitbox();
		kudo.antialiasing = ClientPrefs.globalAntialiasing;
		add(kudo);

		coverscreen = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		coverscreen.alpha = 0;
		coverscreen.scrollFactor.x = 0;
		coverscreen.scrollFactor.y = 0;
		add(coverscreen);

		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.screenCenter(Y);
			spr.y = spr.y - 100;
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
				scoreMedal.y = scoreMedal.y + 720;
				FlxTween.tween(scoreMedal, {y: scoreMedal.y - 720}, 1, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});
				
				scoreText.y = scoreText.y + 720;
				FlxTween.tween(scoreText, {y: scoreText.y - 720}, 1, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});

				diffText.y = diffText.y + 720;
				FlxTween.tween(diffText, {y: diffText.y - 720}, 1, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});

				shmoreText.y = shmoreText.y + 720;
				FlxTween.tween(shmoreText, {y: shmoreText.y - 720}, 1, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});

				creditText.y = creditText.y + 720;
				FlxTween.tween(creditText, {y: creditText.y - 720}, 1, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});

				logicText.y = logicText.y + 720;
				FlxTween.tween(logicText, {y: logicText.y - 720}, 1, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});
				
				songNameText.y = songNameText.y + 720;
				FlxTween.tween(songNameText, {y: songNameText.y - 720}, 1, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});

				leftArrow.y = leftArrow.y + 720;
				FlxTween.tween(leftArrow, {y: leftArrow.y - 720}, 1, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});

				rightArrow.y = rightArrow.y + 720;
				FlxTween.tween(rightArrow, {y: rightArrow.y - 720}, 1, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});

				menuItems.forEach(function(spr:FlxSprite)
				{
					spr.y = spr.y + 720;
					FlxTween.tween(spr, {y: spr.y - 720}, 1, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});
				});

				new FlxTimer().start(1.1, function(tmr:FlxTimer)
				{
					BackgroundState.transitioning = false;
				});
			}
			else
			{
				FlxTween.tween(scoreMedal, {y: scoreMedal.y - 720}, 1, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});
				
				FlxTween.tween(scoreText, {y: scoreText.y - 720}, 1, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});

				FlxTween.tween(diffText, {y: diffText.y - 720}, 1, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});

				FlxTween.tween(shmoreText, {y: shmoreText.y - 720}, 1, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});

				FlxTween.tween(creditText, {y: creditText.y - 720}, 1, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});

				FlxTween.tween(logicText, {y: logicText.y - 720}, 1, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});

				FlxTween.tween(leftArrow, {y: leftArrow.y - 720}, 1, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});

				FlxTween.tween(rightArrow, {y: rightArrow.y - 720}, 1, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});
				
				FlxTween.tween(songNameText, {y: songNameText.y - 720}, 1, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});
				
				menuItems.forEach(function(spr:FlxSprite)
				{
					FlxTween.tween(spr, {y: spr.y - 720}, 1, {ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});
				});
			}
		}
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String)
	{
		songs.push(new SongMetadata(songName, weekNum, songCharacter));
	}

	public function addWeek(songs:Array<String>, weekNum:Int, ?songCharacters:Array<String>)
	{
		if (songCharacters == null)
			songCharacters = ['dad'];

		var num:Int = 0;
		for (song in songs)
		{
			addSong(song, weekNum, songCharacters[num]);

			if (songCharacters.length != 1)
				num++;
		}
	}
	
	var holdTime:Float = 0;
	override function update(elapsed:Float)
	{
		menuItems.forEach(function(spr:FlxSprite)
		{
			if (spr.ID == curSelected)
			{
				var add:Float = 0;
				if(menuItems.length > 4)
				{
					add = menuItems.length * 8;
					spr.updateHitbox();
				}
				camFollow.setPosition(spr.getGraphicMidpoint().x, spr.getGraphicMidpoint().y - add);
				spr.centerOffsets();
				spr.updateHitbox();
			}
		});
		super.update(elapsed);

		var lerpVal:Float = CoolUtil.boundTo(elapsed * 7.5, 0, 1);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, CoolUtil.boundTo(elapsed * 24, 1, 1)));
		lerpRating = FlxMath.lerp(lerpRating, intendedRating, CoolUtil.boundTo(elapsed * 12, 1, 1));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;
		if (Math.abs(lerpRating - intendedRating) <= 0.01)
			lerpRating = intendedRating;

		var ratingSplit:Array<String> = Std.string(Highscore.floorDecimal(lerpRating * 100, 2)).split('.');
		if(ratingSplit.length < 2) { //No decimals, add an empty space
			ratingSplit.push('');
		}
		
		while(ratingSplit[1].length < 2) { //Less than 2 decimals in it, add decimals then
			ratingSplit[1] += '0';
		}
		
		shmoreText.text = 'PERSONAL BEST: ' + lerpScore + ' (' + ratingSplit.join('.') + '%)';

		positionHighscore();
		
		if (lerpRating * 100 >= 100)
		{
			scoreMedal.loadGraphic(Paths.image('fallmen/UI/Menu/Freeplay/medalGold'));
		}
		else if (lerpRating * 100 >= 90)
		{
			scoreMedal.loadGraphic(Paths.image('fallmen/UI/Menu/Freeplay/medalSilver'));
		}
		else if (lerpRating * 100 >= 70)
		{
			scoreMedal.loadGraphic(Paths.image('fallmen/UI/Menu/Freeplay/medalBronze'));
		}
		else if (lerpRating * 100 >= 1)
		{
			scoreMedal.loadGraphic(Paths.image('fallmen/UI/Menu/Freeplay/medalPink'));
		}
		else if (lerpRating * 100 >= 0)
		{
			scoreMedal.loadGraphic(Paths.image('fallmen/UI/Menu/Freeplay/medalPurple'));
		}

		if (curDifficulty == 0)
		{
			diffText.borderColor = 0xFF00A354;
		}
		if (curDifficulty == 1)
		{
			diffText.borderColor = 0xFFDBAF00;
		}
		if (curDifficulty == 2)
		{
			diffText.borderColor = 0xFFDD0088;
		}

		var rightP = controls.UI_RIGHT_P;
		var leftP = controls.UI_LEFT_P;
		var accepted = controls.ACCEPT;
		var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty); //REMINDER: "poop" is the song name AND difficulty EX: 'earthquake-hard'
		var JUSTsongName:String = (songs[curSelected].songName.toLowerCase()); //SONG NAME WITH SPACES AND ALL LOWER CASE
		var FILEsongName:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), 1); //SONG NAME WITH DASHES AND ALL LOWER CASE

		var shiftMult:Int = 1;

		songNameText.text = JUSTsongName.toUpperCase();

		if (JUSTsongName == 'free falling')
		{
			creditText.text = "ORIGINAL SONG IS ''GREATEST PLAN'' BY ETHANTHEDOODLER";
			creditText.size = 27;
		}
		else if (JUSTsongName == 'splash zone')
		{
			creditText.text = "ORIGINAL SONG IS ''BOILING POINT'' BY ETHANTHEDOODLER";
			creditText.size = 27;
		}
		else if (JUSTsongName == 'royal rumble')
		{
			creditText.text = "ORIGINAL SONG IS ''TURBULENCE'' BY KEEGAN";
			creditText.size = 27;
		}
		else if (JUSTsongName == 'stringbean')
		{
			creditText.text = "ORIGINAL SONG IS ''GLITCH'' BY MELYNDEE";
			creditText.size = 27;
		}
		else if (JUSTsongName == 'logic funkin collab')
		{
			creditText.text = "ORIGINAL SONG IS ''EMERGENCY'' BY DINGUSCOLA";
			creditText.size = 27;
		}
		else if (JUSTsongName == 'better bean')
		{
			creditText.text = "ORIGINAL SONG IS ''AMUSIA'' BY SASTER";
			creditText.size = 27;
		}
		else if (JUSTsongName == 'short circut')
		{
			creditText.text = "ORIGINAL SONG IS ''MISMATCH'' BY SASTER || BACKGROUND FROM TRISTAN VOULELIS ON ARTSTATION";
			creditText.size = 24;
		}

		if (JUSTsongName == 'logic funkin collab')
		{
			logicText.text = "THIS IS NOT THE ACTUAL COLLAB WITH LOGIC FUNKIN'. NO REAL WORK WAS DONE FOR THE COLLAB. EVERYTHING HERE IS EITHER A PLACEHOLDERER OR CONCEPT.";
		}
		else
		{
			logicText.text = "";
		}

		if (FlxG.keys.justPressed.F)
		{
			FlxG.fullscreen = !FlxG.fullscreen;
		}
		
		if (selectedSomethin == false && BackgroundState.transitioning == false)
		{
			if (controls.BACK)
			{
				menuTrans(1);
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				if (ClientPrefs.menuTrans)
				{
					new FlxTimer().start(1.1, function(tmr:FlxTimer)
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

			else if (FlxG.keys.justPressed.CONTROL)
			{
				if (JUSTsongName == 'locked')
				{
					FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), 0.2);
					camGame.shake(0.005, 0.2);
					trace('no <3');
				}
				else
				{
					if (Paths.fileExists('data/' + FILEsongName + '/' + poop + '.json', TEXT))
					{

						selectedSong = curSelected;
						menuItems.forEach(function(spr:FlxSprite)
						{
							if (curSelected != spr.ID)
							{
								spr.animation.play('idle');
								spr.updateHitbox();
							}
							else
							{
								spr.animation.play('press');
							}
						});

						selectedSomethin = true;

						FlxG.sound.play(Paths.sound('confirmMenu2'));
						trace(poop);
						universalPoop = poop;
						freeplaySongName = songs[curSelected].songName;
						PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
						PlayState.isStoryMode = false;
						PlayState.storyDifficulty = curDifficulty;
						PlayState.storyWeek = songs[curSelected].week;
						MainMenuState.showSelected = true;

						MainMenuState.curSong = JUSTsongName;

						new FlxTimer().start(1, function(tmr:FlxTimer)
						{
							menuTrans(1);
							if (ClientPrefs.menuTrans)
							{
								new FlxTimer().start(1.1, function(tmr:FlxTimer)
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

						});
					}
					else
					{
						FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.3));
						camGame.shake(0.005, 0.2);
						trace('data/' + FILEsongName + '/' + poop + '.json' + " doesn't exist");
					}
				}
			}

			else if (accepted)
			{
				if (JUSTsongName == 'locked')
				{
					FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), 0.2);
					camGame.shake(0.005, 0.2);
					trace('no <3');
				}
				else
				{
					BackgroundState.curMenu = "Main";
					kudoXslide = false;
					if (Paths.fileExists('data/' + FILEsongName + '/' + poop + '.json', TEXT))
					{

						selectedSong = curSelected;
						menuItems.forEach(function(spr:FlxSprite)
						{
							if (curSelected != spr.ID)
							{
								spr.animation.play('idle');
								spr.updateHitbox();
							}
							else
							{
								spr.animation.play('press');
							}
						});

						selectedSomethin = true;
						FlxG.mouse.visible = false;
						MainMenuState.showSelected = true;

						FlxG.sound.play(Paths.sound('confirmMenu2'));
						trace(poop);
						universalPoop = poop;
						freeplaySongName = songs[curSelected].songName;
						PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
						PlayState.isStoryMode = false;
						PlayState.storyDifficulty = curDifficulty;
						PlayState.storyWeek = songs[curSelected].week;
						FlxTween.tween(coverscreen, {alpha: 1}, 1, {startDelay: 0.5, ease: FlxEase.quadInOut, type: FlxTweenType.ONESHOT});
						MainMenuState.curSong = JUSTsongName;
						new FlxTimer().start(1.6, function(tmr:FlxTimer)
						{
							BackgroundState.coverscreen.alpha = 1;
							trace(FreeplayState.universalPoop);
							PlayState.SONG = Song.loadFromJson(FreeplayState.universalPoop, FreeplayState.freeplaySongName.toLowerCase());
							PlayState.isStoryMode = false;
							PlayState.storyDifficulty = FreeplayState.curDifficulty;
							if (MainMenuState.curSong == "better bean")
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
						FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.3));
						camGame.shake(0.005, 0.2);
						trace('data/' + FILEsongName + '/' + poop + '.json' + " doesn't exist");
					}
				}
			}

			if(FlxG.keys.pressed.SHIFT) shiftMult = 3;

				if (leftP)
				{
					FlxG.camera.follow(camFollowPos, null, 1);
					changeSelection(-shiftMult);
					holdTime = 0;
					leftArrow.animation.play('press');
				}
				else
				{
					leftArrow.animation.play('idle');
				}

				if (rightP)
				{
					FlxG.camera.follow(camFollowPos, null, 1);
					changeSelection(shiftMult);
					holdTime = 0;
					rightArrow.animation.play('press');
				}
				else
				{
					rightArrow.animation.play('idle');
				}

				if(controls.UI_LEFT || controls.UI_RIGHT)
				{
					songNameText.text = JUSTsongName.toUpperCase();
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

					if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
					{
						changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
						changeDiff();
					}
				}

				if(FlxG.mouse.wheel != 0)
				{
					FlxG.camera.follow(camFollowPos, null, 1);
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
					changeSelection(-shiftMult * FlxG.mouse.wheel);
					changeDiff();
				}
			}

			super.update(elapsed);

			menuItems.forEach(function(spr:FlxSprite)
			{
				if (BackgroundState.transitioning == false)
				{
					spr.screenCenter(Y);
					spr.y = spr.y - 100;
				}
			});
	}

	function changeDiff(change:Int = 0)
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = 2;
		if (curDifficulty > 2)
			curDifficulty = 0;

		// adjusting the highscore song name to be compatible (changeDiff)
		var songHighscore = StringTools.replace(songs[curSelected].songName, " ", "-");
		switch (songHighscore)
		{
			case 'Dad-Battle': songHighscore = 'Dadbattle';
			case 'Philly-Nice': songHighscore = 'Philly';
		}
		
		#if !switch
		intendedScore = Highscore.getScore(songHighscore, curDifficulty);
		intendedRating = Highscore.getRating(songHighscore, curDifficulty);
		#end

		PlayState.storyDifficulty = curDifficulty;
		diffText.text = '\n' + CoolUtil.difficultyString();
		positionHighscore();
	}


	function changeSelection(change:Int = 0)
	{
		#if !switch
		// NGio.logEvent('Fresh');
		#end

		// NGio.logEvent('Fresh');
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - weekbeaten - 1;
		if (curSelected >= songs.length - weekbeaten)
			curSelected = 0;

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		#end

		var bullShit:Int = 0;

		CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();

		menuItems.forEach(function(spr:FlxSprite)
		{
			if (spr.ID == selectedSong)
			{
				spr.animation.play('selected');
				spr.updateHitbox();
			}
			else
			{
				spr.animation.play('idle');
				spr.updateHitbox();

				if (spr.ID == curSelected)
				{
					spr.animation.play('idle');
					var add:Float = 0;
					if(menuItems.length > 4) {
						add = menuItems.length * 8;
					spr.updateHitbox();
					}
					camFollow.setPosition(spr.getGraphicMidpoint().x, spr.getGraphicMidpoint().y - add);
					spr.centerOffsets();
					spr.updateHitbox();
				}
			}
		});
	}
		private function positionHighscore() {
			scoreBG.scale.x = FlxG.width - scoreText.x + 6;
			scoreBG.x = 900;
			diffText.screenCenter(X);
		}
	}

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";

	public function new(song:String, week:Int, songCharacter:String)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
	}
}