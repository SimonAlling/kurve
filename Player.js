"use strict";

class Player {
    constructor(id, name = `Player ${id}`, color = "white", keyL = undefined, keyR = undefined) {
        if (!isPositiveInt(id)) {
            throw new TypeError(`Cannot create a player with ID ${id}. Only positive integers are accepted.`);
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

    getVelocity() {
        return this.velocity;
    }

    getDirection() {
        return this.direction;
    }


    // SETTERS

    setMaxSpeed(speed) {
        this.maxSpeed = speed;
    }

    setDirection(direction) {
        this.direction = direction;
    }


    // DOERS

    start() {
        log(`${this} starting.`);
        this.alive = true;
        this.velocity = this.maxSpeed;
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

    enqueueDraw() {
        this.queuedDraws.enqueue({ "x": this.x, "y": this.y });
    }
}
