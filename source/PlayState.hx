package;

// Imports
import allanly.Arrow;
import allanly.Background;
import allanly.Character;
import allanly.Cloud;
import allanly.Crank;
import allanly.Crown;
import allanly.Door;
import allanly.Drawbridge;
import allanly.Enemy;
import allanly.Ladder;
import allanly.Painting;
import allanly.Player;
import allanly.Spawn;
import allanly.Throne;
import allanly.Tools;
import allanly.Torch;
import allanly.Tree;
import flixel.FlxG;
import flixel.FlxState;
import flixel.addons.editors.tiled.TiledMap;
import flixel.addons.editors.tiled.TiledObject;
import flixel.addons.editors.tiled.TiledObjectLayer;
import flixel.addons.editors.tiled.TiledTileLayer;
import flixel.group.FlxGroup;
import flixel.tile.FlxTilemap;

// THE GAME!
class PlayState extends FlxState {
	// Level Number
	public static var levelOn:Int = 0;

	// Background
	public var sceneBackground:Background;

	// Group to hold all the guys
	public var characters:FlxGroup;

	// Hold ladders
	public var ladders:FlxGroup;

	// Hold doors
	private var doors:FlxGroup;

	// Cranks/drawbridges
	private var gameCrank:Crank;
	private var gameDrawbridge:Drawbridge;

	// Crown
	private var gameCrown:Crown;

	// Spawn point
	public var gameSpawn:Spawn;

	// Player
	private var jim:Player;

	// Level
	private var levelFront:FlxTilemap;
	private var levelMid:FlxTilemap;
	private var levelBack:FlxTilemap;
	private var levelCollide:FlxTilemap;

	// Our class constructor
	public function new() {
		super();
	}

	// Creates some stuff
	override public function create() {
		// Mouse
		FlxG.mouse.visible = true;

		// Make jim
		jim = new Player(0, 0);

		// Group to store players
		characters = new FlxGroup();

		// Ladders
		ladders = new FlxGroup();

		// Doors
		doors = new FlxGroup();

		// Background
		sceneBackground = new Background(5000);

		// Create location for pointer so no crashing
		gameCrank = new Crank(-100, -100);
		gameCrown = new Crown(-100, -100);
		gameDrawbridge = new Drawbridge(-100, -100, 0, 0);
		gameSpawn = new Spawn(-100, -100, 0, 0);

		// Pickup jims bow
		jim.pickupBow();

		// Load map :D
		loadMap(levelOn);

		// Zoom and follow
		// FlxG.camera.setScrollBounds(0, 0, levelBack.width, levelBack.height);
		FlxG.camera.follow(jim, PLATFORMER, 1);
	}

	// HINT: THIS UPDATES
	override public function update(elapsed:Float) {
		// Collide everybuddy
		FlxG.collide(characters, levelCollide);
		FlxG.collide(jim, levelCollide);
		FlxG.collide(jim.getArrows(), levelCollide);
		FlxG.overlap(jim.getArrows(), doors, hitDoorArrow);

		// kill "friends"
		FlxG.overlap(jim.getArrows(), characters, hitEnemy);

		// Ladders
		jim.onLadder(FlxG.overlap(jim, ladders, jim.ladderPosition));

		// Door action
		FlxG.overlap(jim, doors, collideDoor);
		FlxG.overlap(characters, doors, collideDoor);

		// Run into draw bridge
		FlxG.collide(jim, gameDrawbridge);
		FlxG.collide(characters, gameDrawbridge);
		FlxG.collide(jim.getArrows(), gameDrawbridge);

		// Win!
		if (FlxG.overlap(jim, gameSpawn) && gameCrown.isTaken()) {
			jim.win();
		}

		// The drawbridge + crank
		if (FlxG.overlap(gameCrank, jim.getArrows()) && !gameCrank.getActivated()) {
			gameDrawbridge.fall();
			gameCrank.spin();
		}

		// Crown
		if (FlxG.overlap(gameCrown, jim)) {
			gameCrown.takeCrown();
		}

		// Die
		if (FlxG.overlap(jim, characters)) {
			jim.die();
			FlxG.sound.music.stop();
		}

		// Make some clouds
		if (Tools.myRandom(0, 1000) == 1) {
			add(new Cloud(-100, Tools.myRandom(0, 200)));
		}

		super.update(elapsed);
	}

	// Door actions
	private function collideDoor(player:Character, door:Door) {
		door.hitDoor(player.velocity.x);
	}

	// Arrows through door
	private function hitDoorArrow(arrow:Arrow, door:Door) {
		// Door is closed
		if (!arrow.dead && (door.scale.x <= 0.2 || door.scale.x >= -0.2)) {
			arrow.velocity.x /= 1.2;
			arrow.velocity.y /= 1.2;
			door.hitDoor(arrow.velocity.x);
		}
	}

	// Enemy actions
	private function hitEnemy(arrow:Arrow, enemy:Enemy) {
		if (arrow.velocity.x != 0 && arrow.velocity.y != 0) {
			enemy.getHit(arrow.velocity.x / Math.cos(arrow.angle));
			arrow.velocity.x *= -0.1;

			if (enemy.health <= 0) {
				characters.remove(enemy);
			}
		}
	}

	/********************
	 * MAP LOADING HERE *
	********************/
	// Load each layer
	private function loadMap(levelOn) {
		trace("Loading Map!");

		levelFront = new FlxTilemap();
		levelMid = new FlxTilemap();
		levelBack = new FlxTilemap();
		levelCollide = new FlxTilemap();

		add(levelBack);
		add(levelMid);
		add(levelFront);
		add(levelCollide);

		// Tiles for level
		var spritesheet:String = "";
		var tmx:TiledMap;

		if (levelOn == 1) {
			spritesheet = AssetPaths.level1_tiles__png;
			tmx = new TiledMap(AssetPaths.level1_map__tmx);
			bgColor = 0xFF0094FE;
		}
		else if (levelOn == 2) {
			spritesheet = AssetPaths.level2_tiles__png;
			tmx = new TiledMap(AssetPaths.level2_map__tmx);
			bgColor = 0xFF76C4FC;
		}
		else if (levelOn == 3) {
			spritesheet = AssetPaths.level3_tiles__png;
			tmx = new TiledMap(AssetPaths.level3_map__tmx);
		}
		else {
			return;
		}

		// Set background color
		bgColor = tmx.backgroundColor;

		// Parse layers
		for (layer in tmx.layers) {
			if (layer.type == TILE) {
				var tileLayer:TiledTileLayer = cast(layer, TiledTileLayer);
				if (layer.name == "collide") {
					levelCollide.loadMapFromArray(tileLayer.tileArray, tileLayer.width, tileLayer.height, spritesheet, 16, 16, OFF, 1);
					levelCollide.follow();
				}
				else if (layer.name == "front") {
					levelFront.loadMapFromArray(tileLayer.tileArray, tileLayer.width, tileLayer.height, spritesheet, 16, 16, OFF, 1);
					levelFront.follow();
				}
				else if (layer.name == "back") {
					levelBack.loadMapFromArray(tileLayer.tileArray, tileLayer.width, tileLayer.height, spritesheet, 16, 16, OFF, 1);
					levelBack.follow();
				}
				else if (layer.name == "mid") {
					levelMid.loadMapFromArray(tileLayer.tileArray, tileLayer.width, tileLayer.height, spritesheet, 16, 16, OFF, 1);
					levelMid.follow();
				}
			}
			else if (layer.type == OBJECT) {
				var objLayer:TiledObjectLayer = cast(layer, TiledObjectLayer);
				spawnObjects(objLayer);
			}
		}
	}

	// Spawn objects using tiled object layer
	private function spawnObjects(group:TiledObjectLayer) {
		// Spawn stuff
		for (obj in group.objects) {
			spawnObject(obj);
		}
	}

	private function spawnObject(obj:TiledObject) {
		trace("Adding " + obj.type + " at x:" + obj.x + " y:" + obj.y + " width:" + obj.width + " height:" + obj.height);

		// Add game objects based on the 'type' property
		switch (obj.type) {
			case "player":
				jim.setPosition(obj.x, obj.y);
				add(jim);
				gameSpawn = new Spawn(obj.x, obj.y, obj.width, obj.height);
				return;
			case "enemy":
				var enemy = new Enemy(jim, obj.x, obj.y);
				characters.add(enemy);
				add(enemy);
				enemy.pickupSword();
				return;
			case "door":
				var door = new Door(obj.x, obj.y);
				add(door);
				doors.add(door);
				return;
			case "torch":
				add(new Torch(obj.x, obj.y));
				return;
			case "tree":
				add(new Tree(obj.x, obj.y));
				return;
			case "ladder":
				ladders.add(new Ladder(obj.x, obj.y, obj.width, obj.height));
				return;
			case "crown":
				gameCrown.setPosition(obj.x, obj.y);
				add(gameCrown);
				return;
			case "painting":
				add(new Painting(obj.x, obj.y));
				return;
			case "throne":
				add(new Throne(obj.x, obj.y));
				return;
			case "drawBridge":
				gameDrawbridge = new Drawbridge(obj.x, obj.y, obj.width, obj.height);
				add(gameDrawbridge);
				return;
			case "crank":
				gameCrank.setPosition(obj.x, obj.y);
				add(gameCrank);
				return;
			case "water":
				// var water = new Water(obj.x, obj.y, obj.width, obj.height);
				return;
			default:
				return;
		}
	}
}
