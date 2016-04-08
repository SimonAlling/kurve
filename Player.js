"use strict";

class Player {
    constructor(id, name = `Player ${id}`, color = "white", L_keys, R_keys) {
        if (!isPositiveInt(id)) {
            throw new TypeError(`Cannot create a player with ID ${id}. Only positive integers are accepted.`);
        }
        this.id = id;
        this.name = name;
        this.color = color;
        this.alive = false;
        this.x = null;
        this.y = null;
        this.direction = 0;
        this.velocity = 0;
        this.lastDraw = null;
        this.queuedDraws = new Queue();
        
        if (isPositiveInt(L_keys)) {
            this.L_keys = [L_keys];
        } else if (isKeyList(L_keys)) {
            this.L_keys = L_keys;
        } else {
            logWarning(`Creating player "${this.name}" without any LEFT key(s).`);
        }

        if (isPositiveInt(R_keys)) {
            this.R_keys = [R_keys];
        } else if (isKeyList(R_keys)) {
            this.R_keys = R_keys;
        } else {
            logWarning(`Creating player "${this.name}" without any RIGHT key(s).`);
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

    hasID(id) {
        return this.id === id;
    }

    hasKey(key) {
        return this.L_keys.indexOf(key) > -1
            || this.R_keys.indexOf(key) > -1;
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

    stop() {
        this.alive = false;
        this.velocity = 0;
    }

    reset() {
        this.queuedDraws = new Queue();
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
