package;

import flixel.FlxG;
import flixel.FlxSubState;

class DialogueSubstate extends FlxSubState
{

    private var dialogueText:TypeTextTwo;

    public function new() {
        super();

        dialogueText = new TypeTextTwo(0, 0, FlxG.width, "This is default dialogue text. jump over shit!!", 16);
		dialogueText.scrollFactor.set();
		add(dialogueText);

		dialogueText.start();
    }
}