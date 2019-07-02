import { log, logWarning, flush, isObject, isPositiveInt, arePositiveNumbers, round, distanceToDuration, randomFloat, MOUSE_BUTTONS, isMouseButton, isKeyList, anyInputBeingPressed } from "./lib/utilities.js";
import { Queue } from "./lib/Queue.js";

export class Player {
    constructor(id, name = `Player ${id}`, color = "white", L_keys, R_keys, holeConfig) {
        if (!isPositiveInt(id)) {
            throw new TypeError(`Cannot create a player with ID ${id}. Only positive integers are accepted.`);
        }
        this.id = id;
        this.name = name;
        this.color = color;
        this.alive = false;
        this.holy = false;
        this.x = null;
        this.y = null;
        this.direction = 0;
        this.velocity = 0;
        this.maxSpeed = undefined;
        this.lastPosition = null;
        this.queuedDraws = new Queue();
        this.holeTimer = null;
        this.holeConfig = null;

        if (!this.constructor.isHoleConfig(holeConfig)) {
            logWarning(`Creating player ${this.name} with no hole configuration because ${holeConfig} is not a valid hole configuration.`);
        } else {
            this.holeConfig = holeConfig;
        }

        if (isPositiveInt(L_keys)) {
            this.L_keys = [L_keys];
        } else if (isKeyList(L_keys)) {
            this.L_keys = L_keys;
        } else {
            logWarning(`Creating player "${this.name}" without any LEFT key(s).`);
            this.L_keys = [];
        }

        if (isPositiveInt(R_keys)) {
            this.R_keys = [R_keys];
        } else if (isKeyList(R_keys)) {
            this.R_keys = R_keys;
        } else {
            logWarning(`Creating player "${this.name}" without any RIGHT key(s).`);
            this.R_keys = [];
        }
    }

    static isPlayer(player) {
        return (player instanceof Player);
    }

    static isHoleConfig(holeConfig) {
        return isObject(holeConfig)
            && arePositiveNumbers([
                                   holeConfig.minPaddedHoleSize,
                                   holeConfig.maxPaddedHoleSize,
                                   holeConfig.minPaddedHoleInterval,
                                   holeConfig.maxPaddedHoleInterval
                                  ]);
    }


    // CHECKERS

    isAlive() {
        return this.alive;
    }

    justWasAt(left, top) {
        return this.lastPosition.left === left && this.lastPosition.top === top;
    }

    isHoly() {
        return this.holy; 
    }

    isPressingLeft() {
        return anyInputBeingPressed(this.L_keys);
    }

    isPressingRight() {
        return anyInputBeingPressed(this.R_keys);
    }

    hasID(id) {
        return this.id === id;
    }

    hasMouseButton(button) {
        return isMouseButton(button)
            && (this.L_keys.includes(button)
             || this.R_keys.includes(button));
    }

    usesAnyMouseButton() {
        return MOUSE_BUTTONS.some(button => this.hasMouseButton(button));
    }

    hasKey(key) {
        return this.L_keys.includes(key)
            || this.R_keys.includes(key);
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

    getLastPosition() {
        return this.lastPosition;
    }

    getVelocity() {
        return this.velocity;
    }

    getDirection() {
        return this.direction;
    }

    randomPaddedHoleSize() {
        return randomFloat(this.holeConfig.minPaddedHoleSize, this.holeConfig.maxPaddedHoleSize);
    }

    randomPaddedHoleInterval() {
        return randomFloat(this.holeConfig.minPaddedHoleInterval, this.holeConfig.maxPaddedHoleInterval);
    }

    firstHoleDelay() {
        return distanceToDuration(this.randomPaddedHoleInterval() - this.holeConfig.minPaddedHoleInterval, this.velocity);
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
        if (this.constructor.isHoleConfig(this.holeConfig)) {
            this.holeTimer = setTimeout(this.startCreatingHoles.bind(this), this.firstHoleDelay());
        }
    }

    stop() {
        this.alive = false;
        this.velocity = 0;
        clearTimeout(this.holeTimer);
    }

    reset() {
        this.holy = false;
        this.lastPosition = null;
        this.queuedDraws = new Queue();
    }

    /**
     * Called when the player does something that causes it do die.
     * @param {String} cause The cause of death.
     */
    die(cause) {
        this.alive = false;
        clearTimeout(this.holeTimer);
        log(`${this} ${(cause || "died")} at (${round(this.x, 2)}, ${round(this.y, 2)}).` );
    }

    beAt(left, top) {
        this.lastPosition = {
            "left": left,
            "top" : top
        };
    }

    beginHole() {
        this.holy = true;
        const paddedHoleSize = this.randomPaddedHoleSize();
        const paddedHoleDuration = distanceToDuration(paddedHoleSize, this.velocity);
        this.holeTimer = setTimeout(this.endHole.bind(this), paddedHoleDuration);
    }

    endHole() {
        this.holy = false;
        const paddedHoleInterval = this.randomPaddedHoleInterval();
        const paddedHoleIntervalDuration = distanceToDuration(paddedHoleInterval, this.velocity);
        this.holeTimer = setTimeout(this.beginHole.bind(this), paddedHoleIntervalDuration);
    }

    startCreatingHoles() {
        this.beginHole();
    }

    enqueueDraw() {
        this.queuedDraws.enqueue({ "x": this.x, "y": this.y });
    }
}
