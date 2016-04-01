"use strict";

class Game {
    constructor(config, renderer, guiController) {
        // Class variables:
        this.constructor.PRACTICE = "practice";
        this.constructor.COMPETITIVE = "competitive";
        this.constructor.DEFAULT_MODE = this.constructor.PRACTICE;
        this.constructor.DEFAULT_TARGET_SCORE = 10;
        this.constructor.MAX_TARGET_SCORE = 1000;
        this.constructor.KONEC_HRY = "KONEC HRY!";

        if (renderer === undefined) {
            throw new TypeError("Cannot create a Game with no renderer.");
        } else if (!this.constructor.isRenderer(renderer)) {
            throw new TypeError(`${renderer} is not a valid renderer.`);
        }

        if (guiController === undefined) {
            throw new TypeError("Cannot create a Game with no GUI controller.");
        } else if (!this.constructor.isGUIController(guiController)) {
            throw new TypeError(`${guiController} is not a valid GUI controller.`);
        }

        // Instance variables:
        this.config = config;
        this.pixels = new Uint8Array(this.config.width * this.config.height); // Limits the number of players to 255, which should be enough.
        this.players = [];
        this.rounds = [];
        this.renderer = renderer;
        this.guiController = guiController;
        this.mode = this.constructor.DEFAULT_MODE;
        this.started = false;
        this.betweenRounds = false; // true when everyone is dead AFTER a round; not during the spawn procedure
        this.totalNumberOfTicks = 0;
        this.currentRound = 0;
        this.targetScore = null;
        this.initMainLoop();
    }

    static isRenderer(obj) {
        // TODO
        return obj !== undefined;
    }

    static isGUIController(obj) {
        // TODO
        return obj !== undefined;
    }

    static calculateTargetScore(numberOfPlayers) {
        // Default target score is (n-1) * 10 for n players:
        return (numberOfPlayers - 1) * 10;
    }

    edgeOfSquare(coordinate) {
        return Math.round(coordinate - this.config.thickness/2);
    }

    maxPlayers() {
        return numberOfBytesToMaxValue(this.pixels.BYTES_PER_ELEMENT);
    }

    computeMaxTicksBeforeDraw() {
        return Math.max(Math.floor(this.config.tickrate/this.config.speed), 1);
    }

    // Computes the angle change for one tick when turning, in radians:
    computeAngleChange() {
        return this.config.speed / (this.config.tickrate * this.config.turningRadius);
    }

    computeSpawnArea() {
        return {
            x_min: this.config.spawnMargin,
            y_min: this.config.spawnMargin,
            x_max: this.config.width - this.config.spawnMargin,
            y_max: this.config.height - this.config.spawnMargin
        };
    }

    computeFrontCornerPixel(edge, dir) {
        let t = this.config.thickness;
        let cf = 100;
        return (cf*edge + cf*(t-1)/2 + cf*dir*(t-1)/2) / cf;
    }

    computeFrontEdgePixel(edge, dir_parallel, dir_perpendicular, i) {
        let t = this.config.thickness;
        return edge + Math.abs(dir_parallel)*(t-1)/2 + dir_parallel*(t-1)/2 + Math.abs(dir_perpendicular)*i;
    }

    computeHitbox(player, left, top) {
        let hitboxPixels = [];
        let lastDraw = player.getLastDraw();
        let dir_horizontal = left - lastDraw.left; // positive => going right; negative => going left
        let dir_vertical   = top  - lastDraw.top;  // positive => going down;  negative => going up
        // console.log(`left, top = ${left}, ${top}`);
        // console.log(`lastDraw.left, lastDraw.top = ${lastDraw.left}, ${lastDraw.top}`);
        // console.log(`dir_horizontal = ${dir_horizontal}`);
        // console.log(`dir_vertical = ${dir_vertical}`);
        if (sameAbs(dir_horizontal, dir_vertical)) {
            // "45 degree" draw
            let frontPixel_left = this.computeFrontCornerPixel(left, dir_horizontal);
            let frontPixel_top  = this.computeFrontCornerPixel(top, dir_vertical);
            hitboxPixels.push(this.pixelAddress(frontPixel_left, frontPixel_top));
        } else {
            // "90 degree" draw
            for (let i = 0; i < this.config.thickness; i++) {
                let frontPixel_left = this.computeFrontEdgePixel(left, dir_horizontal, dir_vertical, i);
                let frontPixel_top = this.computeFrontEdgePixel(top, dir_vertical, dir_horizontal, i);
                hitboxPixels.push(this.pixelAddress(frontPixel_left, frontPixel_top));
            }
        }
        return hitboxPixels;
    }

    randomSpawnPosition() {
        let spawnArea = this.computeSpawnArea();
        return {
            x: randomFloat(spawnArea.x_min, spawnArea.x_max),
            y: randomFloat(spawnArea.y_min, spawnArea.y_max)
        };
    }

    randomSpawnAngle() {
        return randomFloat(this.config.minSpawnAngle, this.config.maxSpawnAngle);
    }

    pixelAddress(x, y) {
        return y*this.config.width + x;
    }

    pixelAddressToCoordinates(addr) {
        let x = addr % this.config.width;
        let y = (addr - x) / this.config.width;
        return "("+x+", "+y+")";
    }

    
    // GETTERS

    getMode() {
        return this.mode;
    }

    getTargetScore() {
        return this.targetScore;
    }

    getNumberOfActivePlayers() {
        return this.players.length;
    }

    getNumberOfLivePlayers() {
        const isAlive = player => player.isAlive();
        return this.players.filter(isAlive).length;
    }


    // SETTERS

    setMode(mode) {
        if (mode === this.constructor.COMPETITIVE || mode === this.constructor.PRACTICE) {
            log(`Setting game mode to ${mode}.`);
            this.mode = mode;
        } else {
            logError(`${mode} is not a valid game mode. Keeping ${this.getMode()}.`);
        }
    }

    setTargetScore(score) {
        let ts = this.constructor.DEFAULT_TARGET_SCORE;
        let mts = this.constructor.MAX_TARGET_SCORE;
        // Neither floats nor negative numbers are allowed:
        if (isInt(score) && score > 0) {
            // Check if the desired target score is allowed:
            if (score > mts) {
                // It is too high. Fall back to max value:
                logWarning(`${score} is larger than the maximum allowed target score of ${mts}. Falling back to ${mts}.`);
                ts = mts;
            } else {
                // The desired target score is OK!
                log(`Setting target score to ${score}.`);
                ts = score;
            }
        } else {
            logWarning(`${score} is not a valid target score. Defaulting to ${ts}.`);
        }
        this.targetScore = ts;
    }


    // CHECKERS

    isStarted() {
        return this.started;
    }

    isBetweenRounds() {
        return this.betweenRounds;
    }

    isLive() {
        if (this.isCompetitive()) {
            return this.getNumberOfLivePlayers() > 1;
        } else {
            return this.getNumberOfLivePlayers() > 0;
        }
    }

    // Caution: Returns true if called during the spawn procedure, since it only checks whether the game is live or not.
    isRoundOver() {
        return !this.isLive();
    }

    isGameOver() {
        const hasReachedTargetScore = player => player.getScore() >= this.getTargetScore();
        return this.isCompetitive() && this.players.some(hasReachedTargetScore);
    }

    isCompetitive() {
        return this.getMode() === this.constructor.COMPETITIVE;
    }

    isOccupiedPixelAddress(addr) {
        return this.pixels[addr] > 0;
    }

    isCrashing(player, left, top) {
        const hitboxPixels = this.computeHitbox(player, left, top);
        return hitboxPixels.some(this.isOccupiedPixelAddress, this);
    }

    /**
     * Checks whether a draw at the specified coordinates is inside the field.
     * @param {Number} left The x coordinate of the left edge of the draw.
     * @param {Number} top  The y coordinate of the top edge of the draw.
     */
    isOnField(left, top) {
        return left >= 0
            && top  >= 0
            && left+this.config.thickness <= this.config.width
            && top +this.config.thickness <= this.config.height;
    }

    /** 
     * Checks whether there is a player with a specific ID in the game.
     * @param {Number} id The ID to check for.
     */
    hasPlayer(id) {
        return this.players.some((player) => player.hasID(id));
    }


    // DOERS

    /** 
     * Adds a player to the game.
     * @param {Player} player The player to add.
     */
    addPlayer(player) {
        const maxPlayers = this.maxPlayers();
        if (!Player.isPlayer(player)) {
            throw new TypeError(`Cannot add ${player} to the game because it is not a player.`);
        } else if (player.getID() > maxPlayers) {
            throw new RangeError(`Cannot add ${player} to the game because player IDs larger than ${maxPlayers} are not supported.`);
        } else if (this.hasPlayer(player.getID())) {
            logWarning(`Not adding ${player} to the game because there is already a player with ID ${player.getID()}.`);
        } else {
            log(`${player} ready!`);
            this.players.push(player);
            player.setMaxSpeed(this.config.speed);
            this.GUI_playerReady(player.getID());
        }
    }

    /** 
     * Removes a player from the game.
     * @param {Number} id The ID of the player to remove.
     */
    removePlayer(id) {
        this.players.forEach((player, index) => {
            if (player.getID() === id) {
                log(`${player} unready!`);
                this.players[index] = null;
                this.GUI_playerUnready(id);
            }
        }, this);
        // this.players may now contain a null value that we do not want to keep:
        this.players = this.players.filter(Player.isPlayer);
    }

    /** Starts the game. */
    start() {
        if (this.isCompetitive()) {
            this.setTargetScore(this.constructor.calculateTargetScore(this.getNumberOfActivePlayers()));
            this.players.forEach((player) => {
                this.GUI_updateScoreOfPlayer(player.getID(), player.getScore());
            });
        }
        log("Starting game!");
        this.started = true;
        this.GUI_gameStarted();
        MainLoop.start();
        this.proceed();
    }

    /** Quits the game. */
    quit() {
        document.location.reload();
    }

    /** Announce KONEC HRY, show results etc. */
    konecHry() {
        log(this.constructor.KONEC_HRY);
    }

    clearField() {
        this.pixels.fill(0);
        this.Render_clearField();
    }

    /** Proceeds to the next round (or KONEC HRY). */
    proceed() {
        this.betweenRounds = false;
        this.currentRound++;
        this.resetPlayers();
        if (this.isGameOver()) {
            this.konecHry();
        } else {
            log(`======== ROUND ${this.currentRound} ========`);
            this.clearField();
            // Sort the players by their IDs so they spawn in the correct order:
            this.sortPlayers();
            this.spawnAndStartPlayers();
        }
    }

    endRound() {
        this.stopPlayers();
        this.betweenRounds = true;
    }

    sortPlayers() {
        this.players.sort((a, b) => (a.getID() - b.getID()));
    }

    startPlayer(player) {
        player.start();
    }

    stopPlayer(player) {
        player.stop();
    }

    resetPlayer(player) {
        player.reset();
    }

    /** Starts all players. */
    startPlayers() {
        this.players.forEach(this.startPlayer);
    }

    stopPlayers() {
        this.players.forEach(this.stopPlayer);
    }

    resetPlayers() {
        this.players.forEach(this.resetPlayer);
    }

    occupyPixel(x, y, id) {
        this.pixels[this.pixelAddress(x, y)] = id;
    }

    occupy(player, left, top) {
        player.occupy(left, top);
        let right = left + this.config.thickness;
        let bottom = top + this.config.thickness;
        let id = player.getID();
        forfor(top, bottom, left, right, this.occupyPixel.bind(this), id);
        this.Render_drawSquare(left, top, player.getColor());
    }

    flicker(player) {
        const stopFlickering = () => {
            clearInterval(flickerTicker);
            let left = this.edgeOfSquare(player.x);
            let top  = this.edgeOfSquare(player.y);
            this.Render_drawSquare(left, top, player.getColor());
        }
        const self = this;
        const left = this.edgeOfSquare(player.x);
        const top  = this.edgeOfSquare(player.y);
        const color = player.getColor();
        let isVisible = false;
        let flickerTicker = setInterval(() => {
            if (isVisible) {
                this.Render_clearSquare(left, top);
            } else {
                this.Render_drawSquare(left, top, color);
            }
            isVisible = !isVisible;
        }, 1000/this.config.flickerFrequency);
        setTimeout(stopFlickering, self.config.flickerDuration);
    }

    spawn(player, position, direction) {
        log(`${player} spawning at (${round(position.x, 2)}, ${round(position.y, 2)}).`);
        player.x = position.x;
        player.y = position.y;
        player.direction = direction;
        player.occupy(this.edgeOfSquare(player.x), this.edgeOfSquare(player.y));
        this.flicker(player);
    }

    /** Spawns and then starts all players. */
    spawnAndStartPlayers() {
        const self = this;
        // Spawn each player, then wait for it to finish flickering before spawning the next one:
        (function spawnPlayer(i) {
            if (i < self.players.length) {
                self.spawn(self.players[i], self.randomSpawnPosition(), self.randomSpawnAngle());
                setTimeout(() => spawnPlayer(++i), self.config.flickerDuration);
            } else {
                // All players have spawned. Start them!
                self.startPlayers();
            }
        })(0);
    }

    /**
     * Draws a specific player.
     */
    drawPlayer(player) {
        const thickness = this.config.thickness;
        while (player.isAlive() && !player.queuedDraws.isEmpty()) {
            let currentDraw = player.queuedDraws.dequeue();
            let left = this.edgeOfSquare(currentDraw.x);
            let top  = this.edgeOfSquare(currentDraw.y);
            if (!player.justDrewAt(left, top)) {
                // The new draw position is not identical to the last one.
                // TODO
                let diff_left = left - player.getLastDraw().left;
                let diff_top  = top  - player.getLastDraw().top;
                if (!this.isOnField(left, top)) {
                    // The player wants to draw outside the playing field => DIE.
                    this.death(player, "crashed into the wall");
                } else if (this.isCrashing(player, left, top)) {
                    // The player wants to draw on a spot occupied by a Kurve => DIE.
                    this.death(player, "crashed");
                } else if (!player.isHoly()) {
                    // The player is allowed to draw and is not holy.
                    this.occupy(player, left, top);
                }
            }
        }
    }

    updateScores() {
        const isAlive = player => player.isAlive();
        const updateScore = (player) => {
            player.incrementScore();
            this.GUI_updateScoreOfPlayer(player.getID(), player.getScore());
        }
        this.players.filter(isAlive).forEach(updateScore);
    }

    death(player, cause) {
        // Increment score and update it TODO
        // Check if round end
        player.die(cause);
        this.updateScores();
        if (this.isRoundOver()) {
            this.endRound();
        }
    }

    proceedKeyPressed() {
        if (this.isBetweenRounds()) {
            this.proceed();
        }
    }

    quitKeyPressed() {
        if (this.isBetweenRounds() && !this.isGameOver()) {
            this.quit();
        }
    }


    // RENDERER AND GUI CONTROLLER COMMUNICATION

    GUI_playerReady(id) {
        this.guiController.playerReady(id);
    }
    GUI_playerUnready(id) {
        this.guiController.playerUnready(id);
    }
    GUI_updateScoreOfPlayer(id, newScore) {
        this.guiController.updateScoreOfPlayer(id, newScore);
    }
    GUI_gameStarted() {
        this.guiController.gameStarted();
    }

    Render_clearHeads() {
        // TODO
    }
    Render_drawSquare(left, top, color) {
        this.renderer.drawSquare(left, top, color, this.config.thickness);
    }
    Render_clearSquare(left, top) {
        this.renderer.clearSquare(left, top, this.config.thickness);
    }
    Render_clearField() {
        this.renderer.clearRect(0, 0, this.config.width, this.config.height);
    }


    // MAIN LOOP



    updatePlayer(player, delta) {
        if (player.isAlive()) {
            // Debugging:
            const debugFieldID = "debug_" + player.getName().toLowerCase();
            const debugField = document.getElementById(debugFieldID);
            const angleChange = this.computeAngleChange();
            let direction = player.getDirection();
            if (isHTMLElement(debugField)) {
                debugField.textContent = "x ~ "+Math.round(player.x)+", y ~ "+Math.round(player.y)+", dir = "+round(radToDeg(player.direction), 2);
            }
            if (player.isPressingLeft()) {
                direction = direction + angleChange; // let compound assignment not optimizable in V8
            }
            if (player.isPressingRight()) {
                direction = direction - angleChange; // let compound assignment not optimizable in V8
            }
            // We use normalizeAngle so the angle stays in the interval -pi < dir <= pi:
            player.setDirection(normalizeAngle(direction));
            const theta = player.getVelocity() * delta / 1000;
            player.x += theta * Math.cos(player.direction);
            player.y -= theta * Math.sin(player.direction);
            if (this.totalNumberOfTicks % this.computeMaxTicksBeforeDraw() === 0) {
                player.enqueueDraw();
            }
        }
    }

    /**
     * Updates everything on each tick.
     * @param {Number} delta
     *   The amount of time since the last update, in seconds.
     */
    update(delta) {
        this.Render_clearHeads();
        this.players.forEach((player) => { this.updatePlayer(player, delta); });
        this.totalNumberOfTicks++;
        // Cycle players so the players take turns being prioritized:
        if (this.isLive()) {
            this.players.unshift(this.players.pop());
        }
    }

    /**
     * Draws all players.
     */
    draw() {
        this.players.forEach(this.drawPlayer, this);
    }

    /**
     * Updates the FPS counter etc.
     * @param {Number} framerate
     *   The smoothed frames per second.
     * @param {Boolean} panic
     *   Whether the main loop panicked because the simulation fell too far behind real time.
     */
    end(framerate, panic) {
        if (panic) {
            let discardedTime = Math.round(MainLoop.resetFrameDelta());
            console.warn("Main loop panicked. Discarding " + discardedTime + "ms.");
        }
    }


    /**
     * Initiates the main loop.
     */
    initMainLoop() {
        this.MainLoop = MainLoop;
        this.MainLoop
            .setUpdate(this.update.bind(this))
            .setDraw(this.draw.bind(this))
            .setEnd(this.end.bind(this))
            .setSimulationTimestep(1000/this.config.tickrate)
            .setMaxAllowedFPS(this.config.maxFramerate);
    }

}







