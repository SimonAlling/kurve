"use strict";

class Player {
    constructor(id, name = `Player ${id}`, color = "white", keyL = undefined, keyR = undefined) {
        if (!isPositiveInt(id)) {
            throw new TypeError(`Cannot create a player with ID ${id}.`);
        }
        this.id = id;
        this.name = name;
        this.color = color;
        this.alive = false;
        this.score = 0;
        this.x = null;
        this.y = null;
        this.direction = 0;
        this.velocity = 0;
        this.lastDraw = null;
        this.queuedDraws = new Queue();
        this.game = undefined;
        this.config = undefined;
        this.angleChangePerTick = undefined;
        this.maxTicksBeforeDraw = undefined;
        if (isPositiveInt(keyL)) {
            this.L_keys = [keyL];
        } else {
            logWarning(`Creating player "${this.name}" without a LEFT key.`);
        }
        if (isPositiveInt(keyR)) {
            this.R_keys = [keyR];
        } else {
            logWarning(`Creating player "${this.name}" without a RIGHT key.`);
        }
    }

    static isPlayer(player) {
        return (player instanceof Player);
    }


    // CHECKERS

    isAlive() {
        return this.alive;
    }

    justDrewAt(left, top) {
        return this.lastDraw.left === left && this.lastDraw.top === top;
    }

    isHoly() {
        return false; // TODO 
    }

    isPressingLeft() {
        return anyKeyBeingPressed(this.L_keys);
    }

    isPressingRight() {
        return anyKeyBeingPressed(this.R_keys);
    }


    // GETTERS

    getID() {
        return this.id;
    }

    getName() {
        return this.name;
    }

    getColor() {
        return this.color;
    }

    toString() {
        return this.name;
    }

    getLastDraw() {
        return this.lastDraw;
    }

    getScore() {
        return this.score;
    }


    // SETTERS

    setGame(game) {
        if (!(game instanceof Game)) {
            throw new TypeError(`Cannot connect ${this} to ${game} because it is not a Game.`);
        }
        this.game = game;
        this.config = game.config;
        this.angleChangePerTick = game.computeAngleChange();
        this.maxTicksBeforeDraw = Math.max(Math.floor(this.config.tickrate/this.config.speed), 1);
    }


    // DOERS

    flicker() {
        let isVisible = false;
        let left = this.game.edgeOfSquare(this.x);
        let top  = this.game.edgeOfSquare(this.y);
        let color = this.getColor();
        this.flickerTicker = setInterval(() => {
            if (isVisible) {
                this.game.Render_clearSquare(left, top);
                isVisible = false;
            } else {
                this.game.Render_drawSquare(left, top, color);
                isVisible = true;
            }
        }, 1000/this.config.flickerFrequency);
    }

    stopFlickering() {
        clearInterval(this.flickerTicker);
        let left = this.game.edgeOfSquare(this.x);
        let top  = this.game.edgeOfSquare(this.y);
        this.game.Render_drawSquare(left, top, this.color);
    }

    spawn(position, direction) {
        if (!(this.game instanceof Game)) {
            throw new TypeError(`${this} is not attached to any game.`);
        } else {
            log(`${this} spawning at (${round(position.x, 2)}, ${round(position.y, 2)}).`);
            this.x = position.x;
            this.y = position.y;
            this.direction = direction;
            this.flicker();
            let self = this;
            setTimeout(() => { self.stopFlickering(); }, self.config.flickerDuration);
            this.occupy(this.game.edgeOfSquare(this.x), this.game.edgeOfSquare(this.y));
        }
    }

    start() {
        log(`${this} starting.`);
        this.alive = true;
        this.velocity = this.config.speed;
    }

    incrementScore() {
        this.score++;
    }

    /**
     * Called when the player does something that causes it do die.
     * @param {String} cause The cause of death.
     */
    die(cause) {
        this.alive = false;
        log(`${this} ${(cause || "died")} at (${round(this.x, 2)}, ${round(this.y, 2)}).` );
    }

    occupy(left, top) {
        this.lastDraw = {
            "left": left,
            "top" : top
        };
    }

    update(delta, totalNumberOfTicks) {
        // Debugging:
        let debugFieldID = "debug_" + this.getName().toLowerCase();
        let debugField = document.getElementById(debugFieldID);
        debugField.textContent = "x ~ "+Math.round(this.x)+", y ~ "+Math.round(this.y)+", dir = "+round(radToDeg(this.direction), 2);
        if (this.isAlive()) {
            if (this.isPressingLeft()) {
                this.direction += this.angleChangePerTick;
            }
            if (this.isPressingRight()) {
                this.direction -= this.angleChangePerTick;
            }
            // We want the direction to stay in the interval -pi < dir <= pi:
            this.direction = normalizeAngle(this.direction);
            let theta = this.velocity * delta / 1000;
            this.x = this.x + theta * Math.cos(this.direction);
            this.y = this.y - theta * Math.sin(this.direction);
            if (totalNumberOfTicks % this.maxTicksBeforeDraw === 0) { // TODO
                this.queuedDraws.enqueue({"x": this.x, "y": this.y });
            }
        }
    }
}
