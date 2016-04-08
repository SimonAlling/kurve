"use strict";

const Zatacka = ((window, document) => {

    const canvas = byID("canvas");

    const config = Object.freeze({
        tickrate: 600, // Hz
        maxFramerate: 60, // Hz
        width: canvas.width, // Kuxels
        height: canvas.height, // Kuxels
        thickness: 3, // Kuxels
        speed: 60, // Kuxels per second
        turningRadius: 27, // Kuxels (NB: _radius_)
        minSpawnAngle: -Math.PI/2, // radians
        maxSpawnAngle:  Math.PI/2, // radians
        spawnMargin: 100, // Kuxels
        flickerFrequency: 20, // Hz, when spawning
        flickerDuration: 830, // ms, when spawning
        minHoleDistance: 90, // Kuxels
        maxHoleDistance: 300, // Kuxels
        minHoleLength: 8, // Kuxels
        maxHoleLength: 12, // Kuxels
        hintDelay: 3000, // ms
        keys: {
            "proceed": [KEY.SPACE, KEY.ENTER],
            "quit":    [KEY.ESCAPE]
        },
        messages: Object.freeze({
            pick:    new InfoMessage(`Pick your desired color by pressing the corresponding LEFT key (e.g. M for Orange).`),
            proceed: new InfoMessage(`Press Space or Enter to start!`),
            alt:     new WarningMessage(`Alt combined with some other keys (such as Tab) may cause undesired behavior (such as switching windows).`),
            ctrl:    new WarningMessage(`Ctrl combined with some other keys (such as W or T) may cause undesired behavior (such as closing the tab or opening a new one).`)
        }),
        defaultPlayers: Object.freeze([
            { id: 1, name: "Red"   , color: "#FF2800", keyL: KEY["1"]      , keyR: KEY.Q          },
            { id: 2, name: "Yellow", color: "#C3C300", keyL: KEY.CTRL      , keyR: KEY.ALT        },
            { id: 3, name: "Orange", color: "#FF7900", keyL: KEY.M         , keyR: KEY.COMMA      },
            { id: 4, name: "Green" , color: "#00CB00", keyL: KEY.LEFT_ARROW, keyR: KEY.DOWN_ARROW },
            { id: 5, name: "Pink"  , color: "#DF51B6", keyL: KEY.DIVIDE    , keyR: KEY.MULTIPLY   },
            { id: 6, name: "Blue"  , color: "#00A2CB", keyL: KEY.C         , keyR: KEY.V          }
        ])
    });

    let currentMessages = [];

    function isProceedKey(key) {
        return config.keys.proceed.indexOf(key) !== -1;
    }

    function isQuitKey(key) {
        return config.keys.quit.indexOf(key) !== -1;
    }

    function shouldPreventDefault(key) {
        return !isFKey(key);
    }

    function showMessage(message) {
        if (currentMessages.indexOf(message) === -1) {
            currentMessages.push(message);
        }
        guiController.updateMessages(currentMessages);
    }

    function hideMessage(message) {
        currentMessages = currentMessages.filter(msg => msg !== message);
        guiController.updateMessages(currentMessages);
    }

    function clearMessages() {
        currentMessages = [];
        guiController.clearMessages();
    }

    function defaultPlayerData(id) {
        return config.defaultPlayers.find(defaultPlayer => defaultPlayer.id === id);
    }

    function defaultPlayer(id) {
        const playerData = defaultPlayerData(id);
        if (playerData === undefined) {
            throw new TypeError(`There is no default player with ID ${id}.`);
        }
        return new Player(playerData.id, playerData.name, playerData.color, playerData.keyL, playerData.keyR);
    }

    function proceedKeyPressedInLobby() {
        const numberOfReadyPlayers = game.getNumberOfPlayers();
        if (numberOfReadyPlayers > 0) {
            clearMessages();
            removeLobbyEventListeners();
            addGameEventListeners();
            game.setMode(numberOfReadyPlayers === 1 ? Game.PRACTICE : Game.COMPETITIVE);
            game.start();
        }
    }

    function checkForDangerousKeys() {
        if (game.getPlayers().some((player) => player.hasKey(KEY.CTRL))) {
            showMessage(config.messages.ctrl);
        } else {
            hideMessage(config.messages.ctrl);
        }

        if (game.getPlayers().some((player) => player.hasKey(KEY.ALT))) {
            showMessage(config.messages.alt);
        } else {
            hideMessage(config.messages.alt);
        }
    }

    function addPlayer(id) {
        game.addPlayer(defaultPlayer(id));
        checkForDangerousKeys();
        clearTimeout(hintPickTimer);
        hideMessage(config.messages.pick);
        clearTimeout(hintProceedTimer);
        hintProceedTimer = setTimeout(() => {
            showMessage(config.messages.proceed);
        }, config.hintDelay);
    }

    function removePlayer(id) {
        game.removePlayer(id);
        checkForDangerousKeys();
        clearTimeout(hintProceedTimer);
        if (game.getNumberOfPlayers() === 0) {
            hideMessage(config.messages.proceed);
        } else {
            hintProceedTimer = setTimeout(() => {
                showMessage(config.messages.proceed);
            }, config.hintDelay);
        }
    }

    function addOrRemovePlayer(playerData, pressedKey) {
        if (pressedKey === playerData.keyL) {
            addPlayer(playerData.id);
        } else if (pressedKey === playerData.keyR) {
            removePlayer(playerData.id);
        }
    }

    function keyPressedInLobby(pressedKey) {
        config.defaultPlayers.forEach((playerData) => {
            addOrRemovePlayer(playerData, pressedKey);
        });
    }

    function lobbyKeyHandler(event) {
        const pressedKey = event.keyCode;
        if (shouldPreventDefault(pressedKey)) {
            event.preventDefault();
        }
        if (isProceedKey(pressedKey)) {
            proceedKeyPressedInLobby();
        } else {
            keyPressedInLobby(pressedKey);
        }
    }

    function lobbyMouseHandler() {

    }

    function gameKeyHandler(event) {
        const pressedKey = event.keyCode;
        if (shouldPreventDefault(pressedKey)) {
            event.preventDefault();
        }
        if (isProceedKey(pressedKey)) {
            game.proceedKeyPressed();
        } else if (isQuitKey(pressedKey)) {
            game.quitKeyPressed();
        }
    }

    function gameMouseHandler() {

    }

    function addLobbyEventListeners() {
        log("Adding lobby event listeners ...");
        document.addEventListener("keydown", lobbyKeyHandler);
        document.addEventListener("mousedown", lobbyMouseHandler);
        log("Done.");
    }

    function removeLobbyEventListeners() {
        log("Removing lobby event listeners ...");
        document.removeEventListener("keydown", lobbyKeyHandler);
        document.removeEventListener("mousedown", lobbyMouseHandler);
        log("Done.");
    }

    function addGameEventListeners() {
        log("Adding game event listeners ...");
        document.addEventListener("keydown", Keyboard.onKeydown.bind(Keyboard));
        document.addEventListener("keyup", Keyboard.onKeyup.bind(Keyboard));
        document.addEventListener("keydown", gameKeyHandler);
        document.addEventListener("mousedown", gameMouseHandler);
        log("Done.");
    }

    function removeGameEventListeners() {
        log("Removing game event listeners ...");
        document.removeEventListener("keydown", gameKeyHandler);
        document.removeEventListener("mousedown", gameMouseHandler);
        log("Done.");
    }

    addLobbyEventListeners();

    const guiController = GUIController(config);
    const game = new Game(config, Renderer(config, canvas), guiController);

    let hintProceedTimer;
    let hintPickTimer = setTimeout(() => {
        showMessage(config.messages.pick);
    }, config.hintDelay);

    return {
        getConfig: () => config,
        getGame: () => game,
        addPlayer: (playerOrID) => {
            const player = Player.isPlayer(playerOrID) ? playerOrID : new Player(playerOrID);
            game.addPlayer(player);
        }
    };

})(window, document);
