package data;

import flixel.FlxCamera;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import data.OgmoTilemap;
import props.*;
import props.Platform;
import states.PlayState;

import flixel.FlxG;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.group.FlxGroup;

import zero.utilities.OgmoUtils;
import zero.flixel.utilities.FlxOgmoUtils;

using zero.utilities.OgmoUtils;
using zero.flixel.utilities.FlxOgmoUtils;

class Section extends FlxGroup
{
    public var path:String;
    
    public var map:OgmoTilemap;
    public var crack:OgmoTilemap;
    public var cameraTiles:CameraTilemap;
    public var foreground = new FlxGroup();
    public var background = new FlxGroup();
    public var grpDecals = new FlxGroup();
    public var grpPlayers = new FlxTypedGroup<Player>();
    
    public var grpCheese = new FlxTypedGroup<Cheese>();
    public var grpHooks = new FlxTypedGroup<Hook>();
    public var grpPlatforms = new FlxTypedGroup<TriggerPlatform>();
    public var grpOneWayPlatforms = new FlxTypedGroup<Platform>();
    public var grpSpikes = new FlxTypedGroup<SpikeObstacle>();
    public var grpEnemies = new FlxTypedGroup<Enemy>();
    public var grpCheckpoint = new FlxTypedGroup<Checkpoint>();
    public var grpLockedDoors = new FlxTypedGroup<Lock>();
    public var grpMusicTriggers = new FlxTypedGroup<MusicTrigger>();
    public var grpSecretTriggers = new FlxTypedGroup<SecretTrigger>();
    
    public var x(get, never):Float;
    inline function get_x():Float return map.x;
    public var y(get, never):Float;
    inline function get_y():Float return map.y;
    public var width(get, never):Float;
    inline function get_width():Float return map.width;
    public var height(get, never):Float;
    inline function get_height():Float return map.height;
    
    public var left(get, never):Float;
    inline function get_left():Float return x;
    public var top(get, never):Float;
    inline function get_top():Float return y;
    public var right(get, never):Float;
    inline function get_right():Float return x + width;
    public var bottom(get, never):Float;
    inline function get_bottom():Float return y + height;
    
    var state(get, never):PlayState;
    inline function get_state():PlayState return cast FlxG.state;
    
    public function new (path:String, ?offset:FlxPoint)
    {
        this.path = path;
        super();
        
        var ogmo = FlxOgmoUtils.get_ogmo_package("assets/data/ogmo/levelProject.ogmo", path);
        if (offset == null)
            offset = FlxPoint.weak(ogmo.level.offsetX, ogmo.level.offsetY);
        
        map = new OgmoTilemap(ogmo, 'tiles', 0, 3);
        map.x += offset.x;
        map.y += offset.y;
        #if debug map.ignoreDrawDebug = true; #end
        map.setTilesCollisions(40, 4, FlxObject.UP);
        
        crack = new OgmoTilemap(ogmo, 'Crack');
        crack.x += offset.x;
        crack.y += offset.y;
        #if debug crack.ignoreDrawDebug = true; #end
        
        grpDecals = ogmo.level.get_decal_layer('decals').get_decal_group('assets/images/decals', false);
        for (decal in (cast grpDecals.members:Array<FlxSprite>))
        {
            decal.x += offset.x;
            decal.y += offset.y;
            decal.moves = false;
            #if debug
            decal.ignoreDrawDebug = true;
            #end
        }
        
        add(crack);
        add(background);
        add(map);
        add(grpDecals);
        add(foreground);
        
        createOffsetEntityLayer(ogmo.level.get_entity_layer('BG entities'), offset, background);
        createOffsetEntityLayer(ogmo.level.get_entity_layer('FG entities'), offset, foreground);
        
        cameraTiles = new CameraTilemap(ogmo);
    }
    
    function createOffsetEntityLayer(entityLayer:EntityLayer, offset:FlxPoint, layer:FlxGroup)
    {
        for (e in entityLayer.entities)
        {
            e.x += Std.int(offset.x);
            e.y += Std.int(offset.y);
            if (e.nodes != null)
            {
                for (node in e.nodes)
                {
                    node.x += offset.x;
                    node.y += offset.y;
                }
            }
        }
        return entityLayer.load_entities(createEntities.bind(_, layer));
    }
    
    function createEntities(e:EntityData, layer:FlxGroup)
    {
        var entity:FlxBasic = null;
        switch(e.name)
        {
            case "player":
                var player = createAvatar(e.x, e.y);
                player.currentSection = this;
                FlxG.camera = player.playCamera;
                // entity = player; //layer not used
            case "spider":
                entity = grpEnemies.add(new Enemy(e));
            case "coins" | "cheese":
                entity = grpCheese.add(new Cheese(e.x, e.y, e.id, true));
            case "hook":
                entity = grpHooks.add(new Hook(e.x, e.y));
            case "blinking_platform"|"solid_blinking_platform"|"cloud_blinking_platform":
                var platform = BlinkingPlatform.fromOgmo(e);
                grpPlatforms.add(platform);
                if (platform.oneWayPlatform)
                    grpOneWayPlatforms.add(platform);
                entity = platform;
            case "moving_platform"|"solid_moving_platform"|"cloud_moving_platform":
                var platform = MovingPlatform.fromOgmo(e);
                grpPlatforms.add(platform);
                if (platform.oneWayPlatform)
                    grpOneWayPlatforms.add(platform);
                entity = platform;
            case "spike":
                entity = grpSpikes.add(new SpikeObstacle(e.x, e.y, e.rotation));
            case "checkpoint":
                entity = grpCheckpoint.add(Checkpoint.fromOgmo(e));
                // #if debug
                // if (!minimap.checkpoints.exists(rat.ID))
                // 	throw "Non-existent checkpoint id:" + rat.ID;
                // #end
            case "musicTrigger":
                entity = grpMusicTriggers.add(new MusicTrigger(e.x, e.y, e.width, e.height, e.values.song, e.values.fadetime));
            case "secretTrigger":
                trace('ADDED SECRET');
                entity = grpSecretTriggers.add(new SecretTrigger(e.x, e.y, e.width, e.height));
            case 'locked' | 'locked_tall':
                entity = grpLockedDoors.add(Lock.fromOgmo(e));
            case unhandled:
                throw 'Unhandled token:$unhandled';
        }
        
        if (entity != null)
            layer.add(entity);
    }
    
    public function setFocus(camera:FlxCamera)
    {
        setWorldBounds();
        final bounds = FlxG.worldBounds;
        camera.minScrollX = bounds.left;
        camera.maxScrollX = bounds.right;
        camera.minScrollY = bounds.top;
        camera.maxScrollY = bounds.bottom;
    }
    
    public function setWorldBounds()
    {
        final bounds = extendRect();
        FlxG.worldBounds.copyFrom(bounds);
        bounds.put();
    }
    
    public function extendRect(?rect:FlxRect)
    {
        if (rect == null)
            return FlxRect.get(left, top, right, bottom);
        
        if (rect.left   > left  ) rect.left   = left  ;
        if (rect.top    > top   ) rect.top    = top   ;
        if (rect.right  < right ) rect.right  = right ;
        if (rect.bottom < bottom) rect.bottom = bottom;
        
        return rect;
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        updateCollision();
        grpPlayers.forEach(checkAvatarState);
    }
    
    function updateCollision()
    {
        grpPlayers.forEach(updatePlatforms);
        
        checkDoors();
        
        grpPlayers.forEach((player)->player.updateTailPosition());
    }
    
    function updatePlatforms(player:Player)
    {
        // Disable one way platforms when pressing down
        grpOneWayPlatforms.forEach((platform)->platform.cloudSolid = !player.controls.DOWN);
        map.setTilesCollisions(40, 4, player.controls.DOWN ? FlxObject.NONE : FlxObject.UP);
        FlxG.collide(map, player);
        
        var oldPlatform = player.platform;
        player.platform = null;
        FlxG.collide(grpPlatforms, player,
            function(platform:TriggerPlatform, _)
            {
                var movingPlatform = Std.downcast(platform, MovingPlatform);
                if (movingPlatform != null && (player.platform == null || (platform.velocity.y < player.platform.velocity.y)))
                    player.platform = movingPlatform;
            }
        );
        
        if (player.platform == null && oldPlatform != null)
            player.onSeparatePlatform(oldPlatform);
        else if (player.platform != null && oldPlatform == null)
            player.onLandPlatform(player.platform);
    }
    
    function checkDoors()
    {
        FlxG.collide(grpLockedDoors, grpPlayers, state.checkDoor);
    }
    
    function checkAvatarState(avatar:Player)
    {
        if (avatar.state == Alive)
        {
            // if (avatar.x > FlxG.worldBounds.width)
            //     avatar.state = Won;
            
            FlxG.overlap(grpEnemies, avatar, 
                (enemy:Enemy, _)->
                {
                    if (avatar.y + avatar.height < enemy.y + enemy.height / 2)
                    {
                        avatar.y = enemy.y - avatar.height;
                        avatar.bounce();
                        enemy.die();
                    }
                    else
                        avatar.state = Dying;
                }
            );
            
            if (SpikeObstacle.overlap(grpSpikes, avatar))
                avatar.state = Dying;
            
            FlxG.overlap(cameraTiles, avatar, 
                (cameraTiles:CameraTilemap, _)->
                {
                    avatar.playCamera.leading = cameraTiles.getTileTypeAt(avatar.x, avatar.y);
                }
            );
        }
        
        state.dialogueBubble.visible = false;
        if (avatar.state == Alive)
        {
            if (avatar.onGround)
                FlxG.overlap(grpCheckpoint, avatar, state.handleCheckpoint);
            
            collectCheese();
            switch (avatar.action)
            {
                case Hanging(_) | Hung:
                case Hooked:
                case Platforming:
                    var tail = avatar.tail;
                    if (avatar.isFalling)
                    {
                        // var bounds = FlxRect.get(player.x, player.y, player.width, player.height);
                        // var center = FlxPoint.get();
                        FlxG.overlap(avatar, grpHooks, 
                            function (_, hook:Hook)
                            {
                                // hook.getCenter(center);
                                
                                // if (bounds.containsPoint(center))
                                    avatar.onTouchHook(hook);
                            }
                        );
                    }
                    if (!tail.isHooked() && tail.isWhipping())
                    {
                        tail.checkMapCollision(map);
                        
                        var overlap:Hook = null;
                        
                        FlxG.overlap(tail, grpHooks, (_, hook)->overlap = hook);
                        
                        if (overlap != null)
                        {
                            // function format(num:Float):String
                            // {
                            // 	// return Std.string(num);
                            // 	var str = Std.string(Math.round(num * 10) / 10);
                            // 	if (str.indexOf(".") == -1)
                            // 		str += ".0";
                            // 	return StringTools.lpad(str, " ", 6);
                            // }
                            // trace
                            // 	( 'hooked'
                            // 	+ '\n\tp :(${format(player.x  )}, ${format(player.y   )})'
                            // 	+ '\n\tts:(${format(tail.x    )}, ${format(tail.y     )})'
                            // 	+ '\n\ttf:(${format(tail.endX )}, ${format(tail.endY  )})'
                            // 	+ '\n\ttr:(${format(tail.width)}, ${format(tail.height)})'
                            // 	);
                            avatar.onWhipHook(overlap);
                        }
                    }
            }
        }
    }
    
    function collectCheese()
    {
        FlxG.overlap(grpPlayers, grpCheese, state.playerCollectCheese);
        
        // collect cheese with tail
        var player:Player;
        player = PlayerSettings.player1.avatar;
        FlxG.overlap(player.tail, grpCheese, (_, cheese)->state.playerCollectCheese(player, cheese));
        if (PlayerSettings.numAvatars > 1)
        {
            player = PlayerSettings.player2.avatar;
            FlxG.overlap(player.tail, grpCheese, (_, cheese)->state.playerCollectCheese(player, cheese));
        }
        
        // if (cheeseCount >= totalCheese)
        // 	NGio.unlockMedal(58884);
    }
    
    public function disableAllDebugDraw()
    {
        foreground.forEach((basic)->{
            if(Std.isOfType(basic, FlxSprite))
            {
                (cast basic:FlxSprite).ignoreDrawDebug = true;
            }
        });
    }
    
    public function contains(x:Float, y:Float)
    {
        return containsPoint(FlxPoint.weak(x, y));
    }
    
    public function overlaps(obj:FlxObject)
    {
        return FlxG.overlap(obj, map);
        // return map.overlaps(obj);
        // return obj.overlaps(map);
    }
    
    inline public function containsPoint(p:FlxPoint)
    {
        return map.overlapsPoint(p);
    }
    
    public function hasAvatar(avatar:Player)
    {
        return grpPlayers.members.indexOf(avatar) >= 0;
    }
    
    public function isOnScreen()
    {
        return map.isOnScreen(PlayerSettings.player1.camera)
            || (PlayerSettings.numAvatars > 1 && map.isOnScreen(PlayerSettings.player2.camera));
    }
    
    function resetProps():Void
    {
        // Reset moving platform
        for (i in 0...grpPlatforms.members.length)
        {
            if (grpPlatforms.members[i] != null && grpPlatforms.members[i].trigger != Load)
                grpPlatforms.members[i].resetTrigger();
        }
    }
    
    
    public function createAvatar(x:Float, y:Float):Player
    {
        var avatar = new Player(x, y);
        var settings = PlayerSettings.addAvatar(avatar);
        avatarEnter(avatar);
        
        return avatar;
    }
    
    public function avatarEnter(avatar:Player)
    {
        avatar.onRespawn.add(resetProps);
        grpPlayers.add(avatar);
    }
    
    public function avatarExit(avatar:Player)
    {
        avatar.onRespawn.remove(resetProps);
        grpPlayers.remove(avatar);
    }
}