package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

class GameOverSubstate extends MusicBeatSubstate
{
	public var boyfriend:Boyfriend;
	var camFollow:FlxPoint;
	var camFollowPos:FlxObject;
	var updateCamera:Bool = false;

	var stageSuffix:String = "";

	public static var characterName:String;
	public static var deathSoundName:String = 'fnf_loss_sfx';
	public static var loopSoundName:String = 'gameOver';
	public static var endSoundName:String = 'gameOverEnd';

	public static var instance:GameOverSubstate;

	public static function resetVariables() {
		deathSoundName = 'fnf_loss_sfx';
		loopSoundName = 'gameOver';
		endSoundName = 'gameOverEnd';
	}

	override function create()
	{
		instance = this;
		PlayState.instance.callOnLuas('onGameOverStart', []);

		super.create();
	}

	public function new(x:Float, y:Float, camX:Float, camY:Float)
	{
		super();

		switch (PlayState.SONG.player1)
		{
			case 'bf-pixel':
				characterName = 'bf-pixel-dead';
				deathSoundName = 'fnf_loss_sfx-pixel';
				loopSoundName = 'gameOver-pixel';
				endSoundName = 'gameOverEnd-pixel';
			case 'rapguy':
				characterName = 'rapguy';
				deathSoundName = '';
				loopSoundName = '';
				endSoundName = '';
			case 'plush-guy-player':
				characterName = 'plush-guy-player';
				deathSoundName = 'fnf_loss_sfx-plushguy';
				loopSoundName = 'gameOver-plushguy';
				endSoundName = 'gameOverEnd-plushguy';
			default:
				characterName = 'bf-og';
				deathSoundName = 'fnf_loss_sfx';
				loopSoundName = 'gameOver';
				endSoundName = 'gameOverEnd';
		}

		PlayState.instance.setOnLuas('inGameOver', true);

		Conductor.songPosition = 0;

		boyfriend = new Boyfriend(x, y, characterName);
		boyfriend.x += boyfriend.positionArray[0];
		boyfriend.y += boyfriend.positionArray[1];
		if (characterName == 'rapguy')
		{
		}
		else
		{
			add(boyfriend);
		}
		
		if (characterName == 'plush-guy-player')
		{
			camFollow = new FlxPoint(boyfriend.getGraphicMidpoint().x - 650, boyfriend.getGraphicMidpoint().y - 80);
		}
		else
		{
			camFollow = new FlxPoint(boyfriend.getGraphicMidpoint().x, boyfriend.getGraphicMidpoint().y);
		}

		FlxG.sound.play(Paths.sound(deathSoundName));
		Conductor.changeBPM(100);
		// FlxG.camera.followLerp = 1;
		// FlxG.camera.focusOn(FlxPoint.get(FlxG.width / 2, FlxG.height / 2));
		FlxG.camera.scroll.set();
		FlxG.camera.target = null;

		boyfriend.playAnim('firstDeath');

		var exclude:Array<Int> = [];

		camFollowPos = new FlxObject(0, 0, 1, 1);
		camFollowPos.setPosition(FlxG.camera.scroll.x + (FlxG.camera.width / 2), FlxG.camera.scroll.y + (FlxG.camera.height / 2));
		add(camFollowPos);
		
		addTouchPad("NONE", "A_B");
		addTouchPadCamera();
	}

	var isFollowingAlready:Bool = false;

	var linkopened:Bool = false;
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (characterName == 'rapguy')
		{
			endBullshit();
			if (!linkopened)
			{
				linkopened = true;
				CoolUtil.browserLoad("https://www.youtube.com/watch?v=grd-K33tOSM");
			}
		}
		else
		{
		}

		PlayState.instance.callOnLuas('onUpdate', [elapsed]);
		if(updateCamera) {
			var lerpVal:Float = CoolUtil.boundTo(elapsed * 0.6, 0, 1);
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
		}

		if (FlxG.keys.justPressed.F)
		{
			FlxG.fullscreen = !FlxG.fullscreen;
		}

		if (controls.ACCEPT)
		{
			endBullshit();
		}

		if (controls.BACK && characterName == 'rapguy')
		{
		}
		else if (controls.BACK)
		{
			FlxG.sound.music.stop();
			PlayState.deathCounter = 0;
			PlayState.seenCutscene = false;
			
			MusicBeatState.switchState(new BackgroundState());

			FlxG.sound.playMusic(Paths.music('freakyMenu'), 0.5);
			PlayState.instance.callOnLuas('onGameOverConfirm', [false]);
		}

		if (boyfriend.animation.curAnim.name == 'firstDeath')
		{
			if(boyfriend.animation.curAnim.curFrame >= 12 && !isFollowingAlready)
			{
				FlxG.camera.follow(camFollowPos, LOCKON, 1);
				updateCamera = true;
				isFollowingAlready = true;
			}

			if (boyfriend.animation.curAnim.finished)
			{
				coolStartDeath();
				boyfriend.startedDeath = true;
			}
		}

		if (FlxG.sound.music.playing)
		{
			Conductor.songPosition = FlxG.sound.music.time;
		}
		PlayState.instance.callOnLuas('onUpdatePost', [elapsed]);
	}

	override function beatHit()
	{
		super.beatHit();

		//FlxG.log.add('beat');
	}

	var isEnding:Bool = false;

	function coolStartDeath(?volume:Float = 1):Void
	{
		FlxG.sound.playMusic(Paths.music(loopSoundName), volume);
	}

	function endBullshit():Void
	{
		PlayState.SONG = Song.loadFromJson(FreeplayState.universalPoop, FreeplayState.freeplaySongName.toLowerCase());
		PlayState.storyDifficulty = FreeplayState.curDifficulty;
		if (!isEnding && characterName == 'rapguy')
		{
			isEnding = true;
			FlxG.sound.music.stop();
			MusicBeatState.resetState();
			PlayState.instance.callOnLuas('onGameOverConfirm', [true]);
		}
		else if (!isEnding)
		{
			isEnding = true;
			boyfriend.playAnim('deathConfirm', true);
			FlxG.sound.music.stop();
			FlxG.sound.play(Paths.music(endSoundName));
			new FlxTimer().start(0.7, function(tmr:FlxTimer)
			{
				FlxG.camera.fade(FlxColor.BLACK, 2, false, function()
				{
					MusicBeatState.resetState();
				});
			});
			PlayState.instance.callOnLuas('onGameOverConfirm', [true]);
		}
	}
}
