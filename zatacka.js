// IIFE start
var Zatacka = (function(window, document) {
"use strict";

var canvas = document.getElementById("canvas");
var context = canvas.getContext("2d");
var canvasWidth = canvas.width;
var canvasHeight = canvas.height;
var pixels = new Array(canvasWidth*canvasHeight).fill(0);

var KEY = Object.freeze({ BACKSPACE: 8, TAB: 9, ENTER: 13, SHIFT: 16, CTRL: 17, ALT: 18, PAUSE: 19, CAPS_LOCK: 20, ESCAPE: 27, SPACE: 32, PAGE_UP: 33, PAGE_DOWN: 34, END: 35, HOME: 36, LEFT_ARROW: 37, UP_ARROW: 38, RIGHT_ARROW: 39, DOWN_ARROW: 40, INSERT: 45, DELETE: 46, "0": 48, "1": 49, "2": 50, "3": 51, "4": 52, "5": 53, "6": 54, "7": 55, "8": 56, "9": 57, A: 65, B: 66, C: 67, D: 68, E: 69, F: 70, G: 71, H: 72, I: 73, J: 74, K: 75, L: 76, M: 77, N: 78, O: 79, P: 80, Q: 81, R: 82, S: 83, T: 84, U: 85, V: 86, W: 87, X: 88, Y: 89, Z: 90, LEFT_META: 91, RIGHT_META: 92, SELECT: 93, NUMPAD_0: 96, NUMPAD_1: 97, NUMPAD_2: 98, NUMPAD_3: 99, NUMPAD_4: 100, NUMPAD_5: 101, NUMPAD_6: 102, NUMPAD_7: 103, NUMPAD_8: 104, NUMPAD_9: 105, MULTIPLY: 106, ADD: 107, SUBTRACT: 109, DECIMAL: 110, DIVIDE: 111, F1: 112, F2: 113, F3: 114, F4: 115, F5: 116, F6: 117, F7: 118, F8: 119, F9: 120, F10: 121, F11: 122, F12: 123, NUM_LOCK: 144, SCROLL_LOCK: 145, SEMICOLON: 186, EQUALS: 187, COMMA: 188, DASH: 189, PERIOD: 190, FORWARD_SLASH: 191, GRAVE_ACCENT: 192, OPEN_BRACKET: 219, BACK_SLASH: 220, CLOSE_BRACKET: 221, SINGLE_QUOTE: 222 });

var config = {
    tickrate: 600, // Hz
    drawrate: 60, // Hz
    kurveThickness: 3,
    minSpawnAngle: -Math.PI/2,
    maxSpawnAngle:  Math.PI/2,
    spawnMargin: 100,
    spawnArea: null,
    maxPlayers: 6,
    speed: 64, // Kuxels per second
    turningRadius: 27, // Kuxels (NB: _radius_)
    flickerFrequency: 20, // Hz, when spawning
    flickerDuration: 830, // ms, when spawning
    players: [
        null, // => very neat logic since Red = P1, Yellow = P2 etc
        { name: "Red",    color: "#FF2800", keyL: KEY["1"], keyR: KEY.Q },
        { name: "Yellow", color: "#C3C300", keyL: KEY.CTRL, keyR: KEY.ALT },
        { name: "Orange", color: "#FF7900", keyL: KEY.M, keyR: KEY.COMMA },
        { name: "Green",  color: "#00CB00", keyL: KEY.LEFT_ARROW, keyR: KEY.DOWN_ARROW },
        { name: "Pink",   color: "#DF51B6", keyL: KEY.DIVIDE, keyR: KEY.MULTIPLY },
        { name: "Blue",   color: "#00A2CB", keyL: null, keyR: null }
    ]
};

config.spawnArea = computeSpawnArea(config.spawnMargin);
var ticksSinceDraw = 0;
var maxTicksBeforeDraw = config.tickrate/config.drawrate;



Object.typeOf = (function typeOf(global) {
    return function(obj) {
        if (obj === global) {
            return "global";
        }
        return ({}).toString.call(obj).match(/\s([a-z|A-Z]+)/)[1].toLowerCase();
    };
})(this);

function isInt(n) {
    return Object.typeOf(n) === 'number' && n % 1 === 0;
}

function init() {

}


var Keyboard = {
    pressed: {},
    isDown: function(keyCode) {
        return this.pressed[keyCode];
    },
    onKeydown: function(event) {
        this.pressed[event.keyCode] = true;
    },
    onKeyup: function(event) {
        delete this.pressed[event.keyCode];
    }
};

function isOnField(x, y) {
    return x >= 0
        && y >= 0
        && x+config.kurveThickness <= canvasWidth
        && y+config.kurveThickness <= canvasHeight;
}

function isOccupiedByOpponent(left, top, id) {
    var x, y;
    var right = left + config.kurveThickness;
    var bottom = top + config.kurveThickness;
    for (y = top; y < bottom; y++) {
        for (x = left; x < right; x++) {
            if (pixels[pixelAddress(x, y)] > 0 && pixels[pixelAddress(x, y)] !== id) {
                return true;
            }
        }
    }
    return false;
}

function isOccupied(left, top) {
    return isOccupiedByOpponent(left, top, undefined);
}

function isOccupiedPixel(x, y) {
    return isOccupiedPixelAddress(pixelAddress(x, y));
}

function isOccupiedPixelAddress(addr) {
    return pixels[addr] > 0;
}



/**
 * Computes the available spawn area.
 *
 * @param {Number} margin
 *   Minimum distance to edge of game field.
 */
function computeSpawnArea(margin) {
    return {
        x_min: margin,
        y_min: margin,
        x_max: canvasWidth - margin,
        y_max: canvasHeight - margin
    };
}

function computeAngleChange() {
    return config.speed / (config.tickrate * config.turningRadius);
}

/**
 * Generates a random float between min (inclusive) and max (exclusive).
 *
 * @param {Number} min
 *   Minimum value (inclusive).
 * @param {Number} max
 *   Maximum value (exclusive).
 */
function randomFloat(min, max) {
    return Math.random() * (max - min) + min;
}

// Translates a pair of coordinates (x, y) into a single pixel address:
function pixelAddress(x, y) {
    return y*canvasWidth + x;
}

function pixelAddressToCoordinates(addr) {
    var x = addr % canvasWidth;
    var y = (addr - x) / canvasWidth;
    return "("+x+", "+y+")";
}

// Returns true iff the two specified rectangles overlap each other:
function isOverlap(left1, top1, left2, top2, thickness) {
    return left2 > (left1 - thickness)
        && left2 < (left1 + thickness)
        && top2  > (top1  - thickness)
        && top2  < (top1  + thickness);
}

// Returns an array with the pixel addresses to the pixels comprising the square at (left, top):
function getPixels(left, top) {
    var pixels = [];
    var right = left + config.kurveThickness;
    var bottom = top + config.kurveThickness;
    for (var y = top; y < bottom; y++) {
        for (var x = left; x < right; x++) {
            pixels.push(pixelAddress(x, y));
        }
    }
    return pixels;
}

function generateSpawnPosition() {
    return {
        x: randomFloat(config.spawnArea.x_min, config.spawnArea.x_max),
        y: randomFloat(config.spawnArea.y_min, config.spawnArea.y_max)
    };
}

function generateSpawnDirection() {
    return randomFloat(config.minSpawnAngle, config.maxSpawnAngle);
}

function drawKurveSquare(x, y, color) {
    context.fillStyle = color;
    context.fillRect(x, y, config.kurveThickness, config.kurveThickness);
}

function clearKurveSquare(x, y) {
    context.clearRect(x, y, config.kurveThickness, config.kurveThickness);
}


/**
 * Draws all players.
 *
 * @param {Number} interpolationPercentage
 *   How much to interpolate between frames.
 */
function draw(interpolationPercentage) {
    var livePlayers = game.livePlayers;
    // We cannot cache the length here since it is changed if some player dies:
    for (var i = 0; i < livePlayers.length; i++) {
        livePlayers[i].draw();
    }
}

/**
 * Updates everything.
 *
 * @param {Number} delta
 *   The amount of time since the last update, in seconds.
 */
function update(delta) {
    for (var i = 0, len = game.livePlayers.length; i < len; i++) {
        game.livePlayers[i].update(delta);
    }
    ticksSinceDraw++;
}

/**
 * Updates the FPS counter etc.
 *
 * @param {Number} framerate
 *   The smoothed frames per second.
 * @param {Boolean} panic
 *   Whether the main loop panicked because the simulation fell too far behind real time.
 */
function end(framerate, panic) {
    if (panic) {
        var discardedTime = Math.round(MainLoop.resetFrameDelta());
        console.warn("Main loop panicked. Discarding " + discardedTime + "ms.");
    }
}






/**
 * Player constructor
 *
 * @param {String} color
 *   The color of the player.
 */
function Player(id, name, color, keyL, keyR) {
    if (isInt(id) && id > 0 && id <= config.maxPlayers) {
        this.id    = id;
        this.name  = name  || config.players[id].name  || "Player "+id;
        this.color = color || config.players[id].color || "white";
        this.keyL  = keyL  || config.players[id].keyL  || null;
        this.keyR  = keyR  || config.players[id].keyR  || null;
        this.queuedDraws  = new Queue();
        this.lastDraw     = { "x": null, "y": null };
        this.secondLastDraw = { "x": null, "y": null };
        this.thirdLastDraw = { "x": null, "y": null };
    } else {
        throw new Error("Cannot create a player with ID "+id+".");
    }
}

// "Constants" for easier use of player IDs:
Player.RED = 1;
Player.YELLOW = 2;
Player.ORANGE = 3;
Player.GREEN = 4;
Player.PINK = 5;
Player.BLUE = 6;

Player.prototype.score = 0;
Player.prototype.alive = false;
Player.prototype.x = null;
Player.prototype.y = null;
Player.prototype.lastX = null;
Player.prototype.lastY = null;
Player.prototype.direction = 0;
Player.prototype.velocity = 0;
Player.prototype.keyL = null;
Player.prototype.keyR = null;
Player.prototype.flickerTicker = null;

Player.prototype.getID = function() {
    return this.id;
};

Player.prototype.getName = function() {
    return this.name;
};

Player.prototype.toString = function() {
    return this.name;
};

Player.prototype.isAlive = function() {
    return this.alive;
};

Player.prototype.occupies = function(left, top) {
    var x, y;
    var right = left + config.kurveThickness;
    var bottom = top + config.kurveThickness;
    for (y = top; y < bottom; y++) {
        for (x = left; x < right; x++) {
            if (pixels[pixelAddress(x, y)] > 0 && pixels[pixelAddress(x, y)] === this.id) {
                return true;
            }
        }
    }
    return false;
};

Player.prototype.setKeybind = function(dir, key) {
    if (dir === LEFT) {
        this.keyL = key;
        console.log("Set LEFT key of "+this.toString()+" to "+key+".");
    } else if (dir === RIGHT) {
        this.keyR = key;
        console.log("Set RIGHT key of "+this.toString()+" to "+key+".");
    } else {
        console.warn("Could not bind "+key+" to "+dir+" because it is not a valid direction.");
    }
};

Player.prototype.reset = function() {
    this.score = 0;
    this.alive = false;
    this.lastY = null;
    this.lastX = null;
    this.x = null;
    this.y = null;
    this.direction = 0;
    this.queuedDraws  = new Queue();
    this.lastDraw     = { "x": null, "y": null };
    this.secondLastDraw = { "x": null, "y": null };
    this.thirdLastDraw = { "x": null, "y": null };
};

Player.prototype.flicker = function() {
    var isVisible = false;
    var x = Math.round(this.x - config.kurveThickness/2);
    var y = Math.round(this.y - config.kurveThickness/2);
    var color = this.color;
    this.flickerTicker = setInterval(function() {
        if (isVisible) {
            clearKurveSquare(x, y);
            isVisible = false;
        } else {
            drawKurveSquare(x, y, color);
            isVisible = true;
        }
    }, 1000/config.flickerFrequency);
};

Player.prototype.stopFlickering = function() {
    clearInterval(this.flickerTicker);
    var x = Math.round(this.x - config.kurveThickness/2);
    var y = Math.round(this.y - config.kurveThickness/2);
    drawKurveSquare(x, y, this.color);
};

Player.prototype.spawn = function() {
    var spawnPosition = generateSpawnPosition();
    this.x = spawnPosition.x;
    this.y = spawnPosition.y;
    var spawnDirection = generateSpawnDirection();
    this.direction = spawnDirection;
    // Player should flicker when it spawns:
    this.flicker();
    var self = this;
    setTimeout(function() { self.stopFlickering(); }, config.flickerDuration);
    console.log(this+" spawning at ("+Math.round(spawnPosition.x)+", "+Math.round(spawnPosition.y)+") with direction "+Math.round(spawnDirection*180/Math.PI)+" deg.");
    this.alive = true;
};

Player.prototype.start = function() {
    this.velocity = config.speed;
};

Player.prototype.occupy = function(left, top) {
    var id = this.id;
    var right = left + config.kurveThickness;
    var bottom = top + config.kurveThickness;
    var thickness = config.kurveThickness;
    for (var y = top; y < bottom; y++) {
        for (var x = left; x < right; x++) {
            pixels[pixelAddress(x, y)] = id;
        }
    }
    this.thirdLastDraw = { "x": this.secondLastDraw.x, "y": this.secondLastDraw.y };
    this.secondLastDraw = { "x": this.lastDraw.x, "y": this.lastDraw.y };
    this.lastDraw = { "x": left, "y": top };
    context.fillStyle = this.color;
    context.fillRect(left, top, thickness, thickness);
};

Player.prototype.die = function(cause) {
    console.log(this+" died from "+cause+".");
    game.deathOf(this);
    this.alive = false;
};

Player.prototype.incrementScore = function() {
    this.score++;
};

Player.prototype.justDrewAt = function(left, top) {
    return this.lastDraw.x === left && this.lastDraw.y === top;
};

Player.prototype.overlapsOwnNeck = function(left, top) {
    return isOverlap(left, top, this.lastDraw.x, this.lastDraw.y, config.kurveThickness)
        || isOverlap(left, top, this.secondLastDraw.x, this.secondLastDraw.y, config.kurveThickness)
        || isOverlap(left, top, this.thirdLastDraw.x, this.thirdLastDraw.y, config.kurveThickness);
};

Player.prototype.getNewPixels = function(left, top) {
    var right = left + config.kurveThickness;
    var bottom = top + config.kurveThickness;
    var newPixels = [];
    var oldPixels = getPixels(this.lastDraw.x, this.lastDraw.y).concat(getPixels(this.secondLastDraw.x, this.secondLastDraw.y)).concat(getPixels(this.thirdLastDraw.x, this.thirdLastDraw.y));
    var maybeNewPixels = getPixels(left, top);
    for (var i = 0, len = maybeNewPixels.length; i < len; i++) {
        if (oldPixels.indexOf(maybeNewPixels[i]) === -1) {
            newPixels.push(maybeNewPixels[i]);
        }
    }
    return newPixels;
};

Player.prototype.isCrashingIntoSelf = function(left, top) {
    var newPixels = this.getNewPixels(left, top);
    for (var i = 0, len = newPixels.length; i < len; i++) {
        if (isOccupiedPixelAddress(newPixels[i])) {
            // For debugging the seemingly random death on self:
            // console.log(this+" dying at ("+left+", "+top+")");
            // console.log(newPixels);
            // console.log(this+".lastDraw:");
            // console.log(this.lastDraw);
            // console.log(this+".secondLastDraw:");
            // console.log(this.secondLastDraw);
            // console.log(this+".thirdLastDraw:");
            // console.log(this.thirdLastDraw);
            // for (var n = 0; n < newPixels.length; n++) {
            //     console.log(pixelAddressToCoordinates(newPixels[n]));
            // }
            return true;
        }
    }
    return false;
};

/**
 * Draws the player.
 *
 * @param {Number} interpolationPercentage
 *   How much to interpolate between frames.
 */
Player.prototype.draw = function() {
    var id = this.id;
    var queuedDraws = this.queuedDraws;
    var thickness  = config.kurveThickness;
    var currentDraw;
    var left, top, right, bottom, x, y, pixelAddress;
    while (this.isAlive() && !this.queuedDraws.isEmpty()) {
        // Player is alive and there are queued draw operations to handle.
        currentDraw =  queuedDraws.dequeue();
        left = Math.round(currentDraw.x - thickness/2);
        top  = Math.round(currentDraw.y - thickness/2);
        if (!this.justDrewAt(left, top)) {
            // The new draw position is not identical to the last one.
            if (!isOnField(left, top)) {
                // The player wants to draw outside the playing field.
                this.die("crashing into the wall");
            } else if (isOccupiedByOpponent(left, top, id)) {
                // The player wants to draw on a spot occupied by an opponent.
                this.die("crashing into an opponent");
            } else if (this.isCrashingIntoSelf(left, top)) {
                // The player wants to draw on a spot occupied by itself.
                this.die("crashing into itself");
            } else {
                this.occupy(left, top);
            }
        }
    }
};

/**
 * Updates the player's position.
 *
 * @param {Number} delta
 *   The amount of time since the last time the player was updated, in seconds.
 */
Player.prototype.update = function(delta) {
    if (Keyboard.isDown(this.keyL)) {
        this.direction += computeAngleChange();
    }
    if (Keyboard.isDown(this.keyR)) {
        this.direction -= computeAngleChange();
    }

    this.lastX = this.x;
    this.lastY = this.y;
    var theta = this.velocity * delta / 1000;
    this.x = this.x + theta * Math.cos(this.direction);
    this.y = this.y - theta * Math.sin(this.direction);
    if (ticksSinceDraw % maxTicksBeforeDraw === 0) {
        this.queuedDraws.enqueue({"x": this.x, "y": this.y });
    }
};






/**
 * Round constructor. A Round object holds information about a round.
 */
function Round(maxPlayers) {
    this.scoreboard = (new Array(maxPlayers+1)).fill(0);
}

Round.prototype.finished = false;
Round.prototype.length = null;

Round.prototype.isFinished = function() {
    return this.finished;
};

Round.prototype.getLength = function() {
    return this.length;
};





/**
 * Game constructor. A Game object holds information about a running game.
 */
function Game(maxPlayers) {
    // Length not dependent on number of ACTIVE players; empty player slots are null:
    this.players = new Array(maxPlayers+1).fill(null);
    this.livePlayers = [];
    this.rounds = Game.emptyRoundsArray(maxPlayers);
    this.scoreboard = (new Array(maxPlayers+1)).fill(null);
}

Game.calculateTargetScore = function(numberOfActivePlayers) {
    return (numberOfActivePlayers - 1) * 10;
};

Game.emptyRoundsArray = function(maxPlayers) {
    var rounds = new Array(maxPlayers + 1);
};


Game.prototype.numberOfActivePlayers = 0;
Game.prototype.targetScore = null;

Game.prototype.setTargetScore = function(s) {
    console.log("Setting target score to "+s+".");
    this.targetScore = s;
};

Game.prototype.getTargetScore = function() {
    return this.targetScore;
};

Game.prototype.getNumberOfActivePlayers = function() {
    return this.numberOfActivePlayers;
};


/**
 * Adds a player to the game.
 *
 * @param {Player} player
 *   The Player object representing the player.
 */
Game.prototype.addPlayer = function(player) {
    if (this.players[player.getID()] !== null) {
        console.warn("There is already a player with ID "+player.getID()+". It will be replaced.");
    }
    this.numberOfActivePlayers++;
    this.players[player.getID()] = player;
    console.log("Added "+player+" as player "+player.getID()+".");
};

/**
 * Adds a player to the game.
 *
 * @param {Number} id
 *   The ID of the player to be removed.
 */
Game.prototype.removePlayer = function(id) {
    if (this.players[id] === null) {
        console.warn("Cannot remove player "+id+" because they are not in the game.");
    } else {
        this.numberOfActivePlayers--;
        console.log("Removed "+this.players[id]+" (player "+id+").");
        this.players[id] = null;
    }
};

Game.prototype.start = function() {
    // Grab all added players and put them in livePlayers:
    for (var i = 0, len = this.players.length; i < len; i++) {
        if (this.players[i] instanceof Player) {
            this.numberOfActivePlayers++;
            this.livePlayers.push(this.players[i]);
            console.log("Added "+this.players[i]+" to livePlayers.");
        }
    }
    this.setTargetScore(Game.calculateTargetScore(this.numberOfActivePlayers));
    for (i = 0, len = this.livePlayers.length; i < len; i++) {
        this.livePlayers[i].spawn();
    }
};

Game.prototype.deathOf = function(player) {
    for (var i = 0; i < this.livePlayers.length; i++) {
        if (this.livePlayers[i] === player) {
            // Remove dead player from livePlayers:
            this.livePlayers.splice(i, 1);
            break;
        }
    }
    for (var i = 0, len = this.livePlayers.length; i < len; i++) {
        this.livePlayers[i].score++;
    }
    // for (var i = 1, len = this.players.length; i < len; i++) {
    //     console.log(this.players[i] + ": " +this.players[i].score);
    // }
};



var GUIController = {};

GUIController.lobby = document.getElementById("lobby");
GUIController.controlsList = document.getElementById("controls");
GUIController.scoreboard = document.getElementById("scoreboard");

GUIController.lobbyKeyListener = function(event) {
    for (var i = 1; i < config.players.length; i++) {
        if (event.keyCode === config.players[i].keyL) {
            game.addPlayer(new Player(i));
            GUIController.playerReady(i);
        } else if (event.keyCode === config.players[i].keyR) {
            game.removePlayer(i);
            GUIController.playerUnready(i);
        }
    }
    if (event.keyCode === KEY.SPACE) {
        if (game.getNumberOfActivePlayers() > 0) {
            GUIController.startGame();
        }
    }
};

GUIController.initLobby = function() {
    console.log("======== Zatacka Lobby ========");
    document.addEventListener("keydown", GUIController.lobbyKeyListener);
};

GUIController.startGame = function() {
    console.log("OK, let's go!");
    // Hide lobby:
    this.lobby.classList.add("hidden");
    // Remove lobby key listener:
    document.removeEventListener("keydown", GUIController.lobbyKeyListener);
    // Show score of active players:
    for (var i = 1, len = game.players.length; i < len; i++) {
        if (game.players[i] instanceof Player) {
            this.showScoreOfPlayer(i);
        }
    }
    game.start();
    MainLoop.start();
};

GUIController.showScoreOfPlayer = function(id) {
    var index = id - 1;
    var scoreboard = this.scoreboard;
    if (scoreboard instanceof HTMLElement) {
        var scoreboardEntry = scoreboard.children[index];
        if (scoreboardEntry instanceof HTMLElement) {
            scoreboardEntry.classList.add("active");
        }
    }
};

GUIController.playerReady = function(id) {
    var index = id - 1;
    this.controlsList.children[index].children[1].classList.add("active");
};

GUIController.playerUnready = function(id) {
    var index = id - 1;
    this.controlsList.children[index].children[1].classList.remove("active");
};

/**
 * Updates the displayed score of the specified player to the specified value.
 *
 * @param {Number} id
 *   The id of the player whose score is to be updated.
 * @param {Number} newScore
 *   The new score to display.
 */
GUIController.updateScoreOfPlayer = function(id, newScore) {
    if (!(this.scoreboard instanceof HTMLElement)) {
        console.error("Scoreboard HTML element could not be found.");
    } else {
        var scoreboardItem = this.scoreboard.children[id-1]; // minus 1 necessary since players are 1-indexed
        var onesDigit = newScore % 10;                       // digit at the ones position (4 in 14)
        var tensDigit = (newScore - (newScore % 10)) / 10;   // digit at the tens position (1 in 14)
        if (scoreboardItem instanceof HTMLDivElement && scoreboardItem.children[0] instanceof HTMLDivElement && scoreboardItem.children[1] instanceof HTMLDivElement) {
            // The digit elements are ordered such that children[0] is ones, children[1] is tens, and so on.
            // First, we have to remove all digit classes:
            scoreboardItem.children[0].classList.remove("d0", "d1", "d2", "d3", "d4", "d5", "d6", "d7", "d8", "d9");
            scoreboardItem.children[1].classList.remove("d0", "d1", "d2", "d3", "d4", "d5", "d6", "d7", "d8", "d9");
            // Add appropriate classes to ones and tens position, respectively:
            scoreboardItem.children[0].classList.add("d"+onesDigit);
            scoreboardItem.children[1].classList.add("d"+tensDigit);
        } else {
            console.error("Could not find HTML scoreboard entry for "+this.players[id].toString()+".");
        }
    }
};


window.addEventListener("keyup"  , function(event) { Keyboard.onKeyup(event);   }, false);
window.addEventListener("keydown", function(event) { Keyboard.onKeydown(event); }, false);

var game = new Game(config.maxPlayers);

GUIController.initLobby();

// Debugging:
// game.players[1].direction = 0;
// game.players[1].x = 500;
// game.players[1].y = 50;
// game.players[2].direction = 180/Math.PI;
// game.players[2].x = 500;
// game.players[2].y = 100;

function drawManually(x, y, color) {
    context.fillStyle = color;
    context.fillRect(x, y, config.kurveThickness, config.kurveThickness);
}

MainLoop
    .setUpdate(update)
    .setDraw(draw)
    .setEnd(end)
    .setSimulationTimestep(1000/config.tickrate)
    .setMaxAllowedFPS(60);

return {
   "isOccupiedPixel": isOccupiedPixel,
   "drawManually": drawManually
};

// IIFE end
})(window, document);
