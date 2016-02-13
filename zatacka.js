// IIFE start
var Zatacka = (function(window, document) {
"use strict";

var canvas = document.getElementById("canvas");
var context = canvas.getContext("2d");
var canvasWidth = canvas.width;
var canvasHeight = canvas.height;
var pixels = new Array(canvasWidth*canvasHeight).fill(0);

var KEY = Object.freeze({ BACKSPACE: 8, TAB: 9, ENTER: 13, SHIFT: 16, CTRL: 17, ALT: 18, PAUSE: 19, CAPS_LOCK: 20, ESCAPE: 27, SPACE: 32, PAGE_UP: 33, PAGE_DOWN: 34, END: 35, HOME: 36, LEFT_ARROW: 37, UP_ARROW: 38, RIGHT_ARROW: 39, DOWN_ARROW: 40, INSERT: 45, DELETE: 46, 0: 48, 1: 49, 2: 50, 3: 51, 4: 52, 5: 53, 6: 54, 7: 55, 8: 56, 9: 57, A: 65, B: 66, C: 67, D: 68, E: 69, F: 70, G: 71, H: 72, I: 73, J: 74, K: 75, L: 76, M: 77, N: 78, O: 79, P: 80, Q: 81, R: 82, S: 83, T: 84, U: 85, V: 86, W: 87, X: 88, Y: 89, Z: 90, LEFT_META: 91, RIGHT_META: 92, SELECT: 93, NUMPAD_0: 96, NUMPAD_1: 97, NUMPAD_2: 98, NUMPAD_3: 99, NUMPAD_4: 100, NUMPAD_5: 101, NUMPAD_6: 102, NUMPAD_7: 103, NUMPAD_8: 104, NUMPAD_9: 105, MULTIPLY: 106, ADD: 107, SUBTRACT: 109, DECIMAL: 110, DIVIDE: 111, F1: 112, F2: 113, F3: 114, F4: 115, F5: 116, F6: 117, F7: 118, F8: 119, F9: 120, F10: 121, F11: 122, F12: 123, NUM_LOCK: 144, SCROLL_LOCK: 145, SEMICOLON: 186, EQUALS: 187, COMMA: 188, DASH: 189, PERIOD: 190, FORWARD_SLASH: 191, GRAVE_ACCENT: 192, OPEN_BRACKET: 219, BACK_SLASH: 220, CLOSE_BRACKET: 221, SINGLE_QUOTE: 222 });

var config = {
    tickrate: 500, // Hz
    kurveThickness: 3,
    minSpawnAngle: -Math.PI/2,
    maxSpawnAngle:  Math.PI/2,
    spawnMargin: 50,
    spawnArea: null,
    maxPlayers: 6,
    speed: 64, // Kuxels per second
    turningRadius: 27, // Kuxels (NB: _radius_)
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
    _pressed: {},

    isDown: function(keyCode) {
        return this._pressed[keyCode];
    },

    onKeydown: function(event) {
        this._pressed[event.keyCode] = true;
    },

    onKeyup: function(event) {
        delete this._pressed[event.keyCode];
    }
};

// TODO maybe remove
function getColorAt(data, x, y) {
    return (y * canvasWidth + x) * 4;
    for (var i = (y * canvasWidth + x) * 4; i < 4; i += 4) {
        if (data[i] !== 0) {
            return false;
        }
    }
}

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

function isOccupiedBySelf(left, top, id) {
    // TODO THIS IS A DUMMY 
    return false;
    var x, y;
    var right = left + config.kurveThickness;
    var bottom = top + config.kurveThickness;
    for (y = top; y < bottom; y++) {
        for (x = left; x < right; x++) {
            if (pixels[pixelAddress(x, y)] === id) {
                return true;
            }
        }
    }
    return false;
}

function isOccupied(left, top) {
    var x, y;
    var right = left + config.kurveThickness;
    var bottom = top + config.kurveThickness;
    for (y = top; y < bottom; y++) {
        for (x = left; x < right; x++) {
            if (pixels[y*canvasWidth + x] > 0) {
                return true;
            }
        }
    }
    return false;
}

function isOccupiedPixel(x, y) {
    //console.log("isOccupiedPixel("+x+", "+y+")? return "+(pixels[pixelAddress(x, y)] > 0));
    return pixels[pixelAddress(x, y)] > 0;
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
    return (config.speed) / (config.tickrate * config.turningRadius);
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

// Translate a pair of coordinates (x, y) into a single pixel address:
function pixelAddress(x, y) {
    return y*canvasWidth + x;
}

function generateSpawnPosition() {
    var x_min = config.spawnArea.x_min,
        x_max = config.spawnArea.x_max,
        y_min = config.spawnArea.y_min,
        y_max = config.spawnArea.y_max;
    var x = randomFloat(x_min, x_max);
    var y = randomFloat(y_min, y_max);
    return {
        x: x,
        y: y
    };
}

function generateSpawnDirection() {
    return randomFloat(config.minSpawnAngle, config.maxSpawnAngle);
}


/**
 * Draws all players.
 *
 * @param {Number} interpolationPercentage
 *   How much to interpolate between frames.
 */
function draw(interpolationPercentage) {
    // console.log("draw("+interpolationPercentage+")");
    var livePlayers = game.livePlayers;
    for (var i = 0, len = livePlayers.length; i < len; i++) {
        if (livePlayers[i] instanceof Player) {
            livePlayers[i].draw();
        }
    }
}

/**
 * For profiling.
 *
 */
function begin() {
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
        this.queuedDraws = new Queue();
    } else {
        throw new Error("Cannot create a player with ID "+id+".");
    }
}

Player.prototype.score = 0;
Player.prototype.alive = false;
Player.prototype.x = null;
Player.prototype.y = null;
Player.prototype.lastX = null;
Player.prototype.lastY = null;
Player.prototype.direction = 0;
Player.prototype.velocity = config.speed;
Player.prototype.keyL = null;
Player.prototype.keyR = null;

Player.prototype.getID = function() {
    return this.id;
};

Player.prototype.getName = function() {
    return this.name;
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

Player.prototype.spawn = function() {
    var spawnPosition = generateSpawnPosition();
    this.x = spawnPosition.x;
    this.y = spawnPosition.y;
    var spawnDirection = generateSpawnDirection();
    this.direction = spawnDirection;
    console.log(this+" spawning at ("+Math.floor(spawnPosition.x)+", "+Math.floor(spawnPosition.y)+") with direction "+Math.round(spawnDirection*180/Math.PI)+" deg.");
    this.alive = true;
};

Player.prototype.die = function(cause) {
    console.log(this+" died from "+cause+".");
    game.death(this);
    this.alive = false;
};

Player.prototype.isAlive = function() {
    return this.alive;
};

Player.prototype.incrementScore = function() {
    this.score++;
};

Player.prototype.reset = function() {
    this.score = 0;
    this.alive = false;
    this.lastY = null;
    this.lastX = null;
    this.x = null;
    this.y = null;
    this.direction = 0;
};

Player.prototype.occupySquare = function(left, top) {
    var id = this.id;
    var right = left + config.kurveThickness;
    var bottom = top + config.kurveThickness;
    for (var y = top; y < bottom; y++) {
        for (var x = left; x < right; x++) {
            pixels[pixelAddress(x, y)] = id;
        }
    }
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
    var currentDraw;
    var thickness  = config.kurveThickness;
    var left, top, right, bottom, x, y, pixelAddress;
    while (this.isAlive() && !this.queuedDraws.isEmpty()) {
        // Player is alive and there are queued draw operations to handle.
        currentDraw =  queuedDraws.dequeue();
        left = Math.floor(currentDraw.x - thickness/2);
        top  = Math.floor(currentDraw.y - thickness/2);
        if (!isOnField(left, top)) {
            this.die("crashing into the wall");
        } else if (isOccupiedByOpponent(left, top, id)) {
            // The player wants to draw on the field, but on a spot occupied by an opponent.
            this.die("crashing into an opponent");
        } else if (isOccupiedBySelf(left, top, id)) {
            // The player wants to draw on the field, but on a spot occupied by itself.
            this.die("crashing into itself");
        } else {
            this.occupySquare(left, top);
            context.fillStyle = this.color;
            context.fillRect(left, top, thickness, thickness);
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
    // TODO fixa så det ritas exakt identiskt oberoende av framerate
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
    this.queuedDraws.enqueue({"x": this.x, "y": this.y });
};

Player.prototype.toString = function() {
    return this.name;
};






/**
 * Game constructor. A Game object holds information about a running game.
 */
function Game() {
    this.players = new Array(config.maxPlayers+1).fill(null);
    this.livePlayers = [];
    this.scoreboard = (new Array(config.maxPlayers+1)).fill(0);
}

/**
 * Adds a player to the game.
 *
 * @param {Player} player
 *   The Player object representing the player.
 * @param {Number} playerNumber
 *   Player number, e.g. RED = P1, YELLOW = P2, ... , BLUE = P6.
 */
Game.prototype.addPlayer = function(player) {
   this.players[player.getID()] = player;
   console.log("Added "+player+" as player "+player.getID()+".");
};

Game.prototype.start = function() {
    // Grab all added players and put them in livePlayers:
    for (var i = 0, len = this.players.length; i < len; i++) {
        if (this.players[i] instanceof Player) {
            this.livePlayers.push(this.players[i]);
            console.log("Added "+this.players[i]+" to livePlayers.");
        }
    }
    for (i = 0, len = this.livePlayers.length; i < len; i++) {
        this.livePlayers[i].spawn();
    }
};

Game.prototype.death = function(player) {
    for (var i = 0, len = this.livePlayers.length; i < len; i++) {
        if (this.livePlayers[i] === player) {
            this.livePlayers.splice(i, 1);
        }
    }
};


window.addEventListener("keyup"  , function(event) { Keyboard.onKeyup(event);   }, false);
window.addEventListener("keydown", function(event) { Keyboard.onKeydown(event); }, false);

var game = new Game();
game.addPlayer(new Player(1));
game.addPlayer(new Player(2));
game.addPlayer(new Player(3));
game.addPlayer(new Player(4));
game.addPlayer(new Player(5));
game.addPlayer(new Player(6));
game.start();

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
    //.setBegin(begin)
    .setUpdate(update)
    .setDraw(draw)
    .setEnd(end)
    .setSimulationTimestep(1000/config.tickrate)
    .setMaxAllowedFPS(30)
    .start();

return {
   "isOccupiedPixel": isOccupiedPixel,
   "drawManually": drawManually
};

// IIFE end
})(window, document);
