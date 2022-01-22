package props;

interface Bouncer
{
    /** The increase to the min jump height of the player when bouncing */
    public var bumpMin(default, null):Float;
    /** The increase to the max jump height of the player when bouncing */
    public var bumpMax(default, null):Float;
}