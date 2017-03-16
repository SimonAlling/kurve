"use strict";

class Game {
    constructor(config, renderer, guiController) {
        // Class variables:
        this.constructor.PRACTICE = "practice";
        this.constructor.COMPETITIVE = "competitive";
        this.constructor.DEFAULT_MODE = this.constructor.PRACTICE;
        this.constructor.DEFAULT_TARGET_SCORE = 10;
        this.constructor.MAX_TARGET_SCORE = 1000;
        this.constructor.MAX_PLAYERS = 255; // since we use a Uint8Array
        this.constructor.MAX_QUOTA_THAT_SPAWN_CIRCLES_MAY_FILL = 0.5; // out of available spawn area
        this.constructor.DESIRED_MINIMUM_SPAWN_DISTANCE_TURNING_RADIUS_FACTOR = 1;
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
        this.width = config.canvas.width;
        this.height = config.canvas.height;
        this.pixels = null; // The actual array is created in start(), because the canvas width and height may have changed by then.
        this.players = [];
        this.rounds = [];
        this.renderer = renderer;
        this.guiController = guiController;
        this.mode = this.constructor.DEFAULT_MODE;
        this.preventSpawnkill = config.preventSpawnkill;
        this.totalNumberOfTicks = 0;
        this.targetScore = null;
        this.initMainLoop();
        this.started = false;
        this.ended = false;
        this.proceedHintTimer = null;
        this.quitHintTimer = null;
    }

    static isRenderer(obj) {
        // TODO
        return obj !== undefined;
    }

    static isGUIController(obj) {
        // TODO
        return obj !== undefined;
    }

    static isAlive(player) {
        return player.isAlive();
    }

    static calculateTargetScore(numberOfPlayers) {
        // Default target score is (n-1) * 10 for n players:
        return (numberOfPlayers - 1) * 10;
    }

    edgeOfSquare(coordinate) {
        return Math.round(coordinate - this.config.thickness/2);
    }

    maxPlayers() {
        return this.constructor.MAX_PLAYERS;
    }

    maxTicksBetweenDraws() {
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
            x_max: this.width - this.config.spawnMargin,
            y_max: this.height - this.config.spawnMargin
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
        let lastPosition = player.getLastPosition();
        let dir_horizontal = left - lastPosition.left; // positive => going right; negative => going left
        let dir_vertical   = top  - lastPosition.top;  // positive => going down;  negative => going up
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

    desiredMinimumSpawnDistance() { // to closest opponent
        // This is calculated by multiplying the turning radius with a constant factor and then adding the Kurve thickness.
        const turningRadiusPart = this.config.turningRadius * this.constructor.DESIRED_MINIMUM_SPAWN_DISTANCE_TURNING_RADIUS_FACTOR;
        return round(this.config.thickness + turningRadiusPart, 2);
    }

    safeMinimumSpawnDistance() { // to closest opponent, without risking infinite or too much sampling
        const spawnAreaCoordinates = this.computeSpawnArea();
        const availableSpawnArea = (spawnAreaCoordinates.x_max - spawnAreaCoordinates.x_min) * (spawnAreaCoordinates.y_max - spawnAreaCoordinates.y_min);
        const maximumSafeDistance = Math.sqrt( this.constructor.MAX_QUOTA_THAT_SPAWN_CIRCLES_MAY_FILL * availableSpawnArea / (this.getNumberOfPlayers() * Math.PI) );
        return Math.min(
            this.desiredMinimumSpawnDistance(),
            round(maximumSafeDistance, 2)
        );
    }

    isSafeSpawnPosition(pos) {
        function distanceBetween(pos1, pos2) {
            return Math.sqrt(Math.pow(pos2.x - pos1.x, 2) + Math.pow(pos2.y - pos1.y, 2));
        }
        for (let i = 0; i < this.players.length; i++) {
            const playerPos = { x: this.players[i].x, y: this.players[i].y };
            if (distanceBetween(playerPos, pos) < this.safeMinimumSpawnDistance()) {
                return false;
            }
        }
        return true;
    }

    safeSpawnPosition() {
        let safePos;
        do {
            safePos = this.randomSpawnPosition();
        } while (!this.isSafeSpawnPosition(safePos));
        return safePos;
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
        return y*this.width + x;
    }

    pixelAddressToCoordinates(addr) {
        let x = addr % this.width;
        let y = (addr - x) / this.width;
        return "("+x+", "+y+")";
    }

    
    // GETTERS

    getMode() {
        return this.mode;
    }

    getTargetScore() {
        return this.targetScore;
    }

    getPlayers() {
        return this.players;
    }

    // Returns the player with the specified ID, or undefined if no such player exists:
    getPlayerByID(id) {
        return this.players.find((player) => player.hasID(id));
    }

    getLivePlayers() {
        const isAlive = this.constructor.isAlive;
        return this.players.filter(isAlive);
    }

    getNumberOfPlayers() {
        return this.players.length;
    }

    getNumberOfLivePlayers() {
        return this.getLivePlayers().length;
    }

    getScoreOfPlayer(id) {
        const accumulateScore = (sum, round) => sum + round.getSuccessOfPlayer(id);
        return this.rounds.reduce(accumulateScore, 0);
    }

    getCurrentRound() {
        return this.rounds[this.rounds.length - 1];
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

    setSize(width, height) {
        this.width = width;
        this.height = height;
        this.renderer.setSize(width, height);
    }

    setPreventSpawnkill(mode) {
        this.preventSpawnkill = mode;
    }


    // CHECKERS

    isStarted() {
        return this.started;
    }

    isEnded() {
        return this.ended;
    }

    /** Returns true if a round is over (including when KONEC HRY is being shown). */
    isPostRound() {
        return this.getCurrentRound().getResults().length === this.getNumberOfPlayers();
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
        const hasReachedTargetScore = player => this.getScoreOfPlayer(player.getID()) >= this.getTargetScore();
        return !this.isLive() && this.isCompetitive() && this.players.some(hasReachedTargetScore);
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
            && left+this.config.thickness <= this.width
            && top +this.config.thickness <= this.height;
    }

    /** 
     * Checks whether there is a player with a specific ID in the game.
     * @param {Number} id The ID to check for.
     */
    hasPlayer(id) {
        return Player.isPlayer(this.getPlayerByID(id));
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
        const playerToRemove = this.getPlayerByID(id);
        // Notify GUI iff the player exists:
        if (Player.isPlayer(playerToRemove)) {
            log(`${playerToRemove} unready!`);
            this.GUI_playerUnready(id);
        }
        // Update this.players:
        this.players = this.players.filter((player) => player !== playerToRemove);
    }

    /** Starts the game. */
    start() {
        if (this.isCompetitive()) {
            this.setTargetScore(this.constructor.calculateTargetScore(this.getNumberOfPlayers()));
            this.players.forEach((player) => {
                this.GUI_updateScoreOfPlayer(player.getID(), 0);
            });
        }
        log("Starting game!");
        this.GUI_gameStarted();
        MainLoop.start();
        this.started = true;
        this.pixels = new Uint8Array(this.width * this.height);
        this.beginNewRound();
    }

    /** Announce KONEC HRY, show results etc. */
    konecHry() {
        log(this.constructor.KONEC_HRY);
        this.ended = true;
        this.GUI_konecHry();
        this.quitHintTimer = setTimeout(this.showQuitHint.bind(this), this.config.hintDelay);
    }

    quit() {
        clearTimeout(this.quitHintTimer);
        clearTimeout(this.proceedHintTimer);
    }

    clearField() {
        this.pixels.fill(0);
        this.Render_clearField();
    }

    showProceedHint() {
        this.GUI_showMessage(this.config.messages.next);
    }

    hideProceedHint() {
        clearTimeout(this.proceedHintTimer);
        this.GUI_hideMessage(this.config.messages.next);
    }

    showQuitHint() {
        this.GUI_showMessage(this.config.messages.quit);
    }

    hideQuitHint() {
        clearTimeout(this.quitHintTimer);
        this.GUI_hideMessage(this.config.messages.quit);
    }

    beginNewRound() {
        this.rounds.push(new Round());
        log(`======== ROUND ${this.rounds.length} ========`);
        this.resetPlayers();
        this.clearField();
        // Sort the players by their IDs so they spawn in the correct order:
        this.sortPlayers();
        this.spawnAndStartPlayers();
    }

    endRound() {
        this.stopPlayers();
        this.proceedHintTimer = setTimeout(this.showProceedHint.bind(this), this.config.hintDelay);
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
        const left = this.edgeOfSquare(player.x);
        const top  = this.edgeOfSquare(player.y);
        player.beAt(left, top);
        this.occupy(player, left, top);
        this.flicker(player);
    }

    /** Spawns and then starts all players. */
    spawnAndStartPlayers() {
        const self = this;
        log(`Spawnkill prevention is ` + (this.preventSpawnkill
                                       ? `enabled. No two players will spawn within ${self.safeMinimumSpawnDistance()} Kuxels of each other.`
                                       : `disabled. Players may spawn arbitrarily close to each other.`));
        // Spawn each player, then wait for it to finish flickering before spawning the next one:
        (function spawnPlayer(i) {
            if (i < self.players.length) {
                const spawnPosition = self.preventSpawnkill ? self.safeSpawnPosition() : self.randomSpawnPosition();
                self.spawn(self.players[i], spawnPosition, self.randomSpawnAngle());
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
            let color = player.getColor();
            let lastPosition = player.getLastPosition();
            let currentDraw = player.queuedDraws.dequeue();
            let left = this.edgeOfSquare(currentDraw.x);
            let top  = this.edgeOfSquare(currentDraw.y);
            if (!player.justWasAt(left, top)) {
                // The new position is not identical to the last one.
                let diff_left = left - player.getLastPosition().left;
                let diff_top  = top  - player.getLastPosition().top;
                if (!this.isOnField(left, top)) {
                    // The player wants to draw outside the playing field => DIE.
                    this.death(player, "crashed into the wall");
                    this.occupy(player, lastPosition.left, lastPosition.top);
                } else if (this.isCrashing(player, left, top)) {
                    // The player wants to draw on a spot occupied by a Kurve => DIE.
                    this.death(player, "crashed");
                    this.occupy(player, lastPosition.left, lastPosition.top);
                } else {
                    // The player is not dying.
                    player.beAt(left, top);
                    if (!player.isHoly()) {
                        // The player is not holy, so it should draw.
                        this.occupy(player, left, top);
                    }
                }
            }
        }
    }

    drawHead(player) {
        if (player.isAlive()) {
            const lastPosition = player.getLastPosition();
            const left = lastPosition.left;
            const top  = lastPosition.top;
            const color = player.getColor();
            this.Render_drawHead(left, top, color);
        }
    }

    updateGUIScoreboard() {
        const updateScore = (player) => {
            const id = player.getID();
            this.GUI_updateScoreOfPlayer(id, this.getScoreOfPlayer(id));
        }
        this.getLivePlayers().forEach(updateScore);
    }

    death(player, cause) {
        player.die(cause);
        this.getCurrentRound().add(player);
        this.updateGUIScoreboard();
        if (this.isRoundOver()) {
            if (this.isCompetitive()) {
                const isAlive = this.constructor.isAlive;
                const winner = this.players.find(isAlive);
                this.winRound(winner);
            }
            this.endRound();
        }
    }

    winRound(player) {
        log(`${player} won the round.`);
        // Ugly fix for the bug where the winner's head disappears when the round ends:
        this.occupy(player, this.edgeOfSquare(player.x), this.edgeOfSquare(player.y));
        this.getCurrentRound().add(player);
    }

    proceedKeyPressed() {
        this.hideProceedHint();
        this.hideQuitHint();
        if (this.isGameOver()) {
            // The game is over, so we should show KONEC HRY:
            this.konecHry();
        } else if (this.isPostRound()) {
            // We are post round and the game is not over, so we should proceed to the next round:
            this.beginNewRound();
        }
    }

    shouldShowReloadConfirmationOnReloadKey() {
        return this.isPostRound();
    }

    shouldQuitOnQuitKey() {
        return this.isPostRound() && !this.isGameOver();
    }

    shouldQuitOnProceedKey() {
        return this.isEnded();
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
    GUI_konecHry() {
        this.guiController.konecHry();
    }
    GUI_showMessage(message) {
        this.guiController.showMessage(message);
    }
    GUI_hideMessage(message) {
        this.guiController.hideMessage(message);
    }

    Render_drawSquare(left, top, color) {
        this.renderer.drawSquare(left, top, this.config.thickness, color);
    }
    Render_drawHead(left, top, color) {
        this.renderer.drawSquare_overlay(left, top, this.config.thickness, color);
    }
    Render_clearSquare(left, top) {
        this.renderer.clearSquare(left, top, this.config.thickness);
    }
    Render_clearHeads() {
        this.renderer.clearRectangle_overlay(0, 0, this.width, this.height);
    }
    Render_clearField() {
        this.renderer.clearRectangle(0, 0, this.width, this.height);
        this.renderer.clearRectangle_overlay(0, 0, this.width, this.height);
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
        }
    }

    /**
     * Updates everything on each tick.
     * @param {Number} delta
     *   The amount of time since the last update, in seconds.
     */
    update(delta) {
        this.players.forEach((player) => { this.updatePlayer(player, delta); });
        if (this.totalNumberOfTicks % this.maxTicksBetweenDraws() === 0) {
            this.getLivePlayers().forEach((player) => {
                player.enqueueDraw();
            });
        }
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
        this.Render_clearHeads();
        this.players.forEach(this.drawPlayer, this);
        this.players.forEach(this.drawHead, this);
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







