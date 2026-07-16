package options;

#if desktop
import Discord.DiscordClient;
#end
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;
import flixel.FlxSubState;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxSave;
import haxe.Json;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.input.keyboard.FlxKey;
import flixel.graphics.FlxGraphic;
import Controls;
import flixel.util.FlxTimer;

using StringTools;

class OptionsState extends MusicBeatSubstate
{
	var options:Array<String> = ['Note Colors', 'Controls', 'Adjust Delay and Combo', 'Graphics', 'Visuals and UI', 'Gameplay', 'Mobile Options'];
	private var grpOptions:FlxTypedGroup<Alphabet>;
	private static var curSelected:Int = 0;

	function openSelectedSubstate(label:String) {
		if (label != "Adjust Delay and Combo"){
			removeTouchPad();
		}
		switch(label) {
			case 'Note Colors':
				openSubState(new options.NotesSubState());
			case 'Controls':
				openSubState(new options.ControlsSubState());
			case 'Graphics':
				openSubState(new options.GraphicsSettingsSubState());
			case 'Visuals and UI':
				openSubState(new options.VisualsUISubState());
			case 'Gameplay':
				openSubState(new options.GameplaySettingsSubState());
			case 'Adjust Delay and Combo':
				LoadingState.loadAndSwitchState(new options.NoteOffsetState());
			case 'Mobile Options':
				openSubState(new mobile.options.MobileOptionsSubState());
		}
	}

	var selectorLeft:Alphabet;
	var selectorRight:Alphabet;

	override function create() {
		#if desktop
		DiscordClient.changePresence("Options Menu", null);
		#end

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		for (i in 0...options.length)
		{
			var optionText:Alphabet = new Alphabet(0, 0, options[i], true, false);
			optionText.screenCenter();
			optionText.y += (100 * (i - (options.length / 2))) + 50;
			grpOptions.add(optionText);
		}

		selectorLeft = new Alphabet(0, 0, '>', true, false);
		add(selectorLeft);
		selectorRight = new Alphabet(0, 0, '<', true, false);
		add(selectorRight);

		changeSelection();
		ClientPrefs.saveSettings();

		addTouchPad("UP_DOWN", "A_B_C");
		
		super.create();
	}

	public static function menuTrans(INorOUT)
	{
		if (ClientPrefs.menuTrans)
		{
			BackgroundState.transitioning = true;

			if (INorOUT == 0)
			{
				new FlxTimer().start(2, function(tmr:FlxTimer)
				{
					BackgroundState.transitioning = false;
				});
			}
			else
			{
			}
		}
	}

	override function closeSubState() {
		FlxG.save.data.OptionsExit = true;
		super.closeSubState();
		removeTouchPad();
		addTouchPad("UP_DOWN", "A_B_C");
		ClientPrefs.saveSettings();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.F)
		{
			FlxG.fullscreen = !FlxG.fullscreen;
		}

		if (controls.UI_UP_P || touchPad != null && touchPad.buttonUp.justPressed) {
			changeSelection(-1);
		}
		if (controls.UI_DOWN_P || touchPad != null && touchPad.buttonDown.justPressed) {
			changeSelection(1);
		}

		if (controls.BACK || touchPad != null && touchPad.buttonB.justPressed) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			close();
			BackgroundState.curMenu = "Settings";
			BackgroundState.fadeBackground();
			BackgroundState.doneSwitching = false;
		}

		if (FlxG.save.data.OptionsExit == true)
		{
			FlxG.save.data.OptionsExit = false;
			grpOptions.visible = true;
			selectorLeft.visible = true;
			selectorRight.visible = true;
		}

		if (controls.ACCEPT || touchPad != null && touchPad.buttonA.justPressed) {
			if (curSelected != 2)
			{
				grpOptions.visible = false;
				selectorLeft.visible = false;
				selectorRight.visible = false;
			}
			openSelectedSubstate(options[curSelected]);
		}
		
		if (touchPad != null && touchPad.buttonC.justPressed) {
			touchPad.active = touchPad.visible = false;
			openSubState(new mobile.MobileControlSelectSubState());
		}
	}
	
	function changeSelection(change:Int = 0) {
		curSelected += change;
		if (curSelected < 0)
			curSelected = options.length - 1;
		if (curSelected >= options.length)
			curSelected = 0;

		var bullShit:Int = 0;

		for (item in grpOptions.members) {
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			if (item.targetY == 0) {
				item.alpha = 1;
				selectorLeft.x = item.x - 63;
				selectorLeft.y = item.y;
				selectorRight.x = item.x + item.width + 15;
				selectorRight.y = item.y;
			}
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}
}