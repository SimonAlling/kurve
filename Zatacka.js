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
        keys: {
            "proceed": [KEY.SPACE, KEY.ENTER],
            "quit":    [KEY.ESCAPE]
        },
        defaultPlayers: Object.freeze([
            { id: 1, name: "Red"   , color: "#FF2800", keyL: KEY["1"]      , keyR: KEY.Q          },
            { id: 2, name: "Yellow", color: "#C3C300", keyL: KEY.CTRL      , keyR: KEY.ALT        },
            { id: 3, name: "Orange", color: "#FF7900", keyL: KEY.M         , keyR: KEY.COMMA      },
            { id: 4, name: "Green" , color: "#00CB00", keyL: KEY.LEFT_ARROW, keyR: KEY.DOWN_ARROW },
            { id: 5, name: "Pink"  , color: "#DF51B6", keyL: KEY.DIVIDE    , keyR: KEY.MULTIPLY   },
            { id: 6, name: "Blue"  , color: "#00A2CB", keyL: KEY.C         , keyR: KEY.V          }
        ])
    });

    function isProceedKey(key) {
        return config.keys.proceed.indexOf(key) !== -1;
    }

    function isQuitKey(key) {
        return config.keys.quit.indexOf(key) !== -1;
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
            removeLobbyEventListeners();
            addGameEventListeners();
            game.setMode(numberOfReadyPlayers === 1 ? Game.PRACTICE : Game.COMPETITIVE);
            game.start();
        }
    }

    function addOrRemovePlayer(playerData, pressedKey) {
        if (pressedKey === playerData.keyL) {
            game.addPlayer(defaultPlayer(playerData.id));
        } else if (pressedKey === playerData.keyR) {
            game.removePlayer(playerData.id);
        }
    }

    function keyPressedInLobby(pressedKey) {
        config.defaultPlayers.forEach((playerData) => {
            addOrRemovePlayer(playerData, pressedKey);
        });
    }

    function lobbyKeyHandler(event) {
        event.preventDefault();
        let pressedKey = event.keyCode;
        if (isProceedKey(pressedKey)) {
            proceedKeyPressedInLobby();
        } else {
            keyPressedInLobby(pressedKey);
        }
    }

    function lobbyMouseHandler() {

    }

    function gameKeyHandler(event) {
        event.preventDefault();
        let pressedKey = event.keyCode;
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

    const game = new Game(config, Renderer(config, canvas), GUIController(config));

    return {
        getConfig: () => config,
        getGame: () => game,
        addPlayer: (playerOrID) => {
            const player = Player.isPlayer(playerOrID) ? playerOrID : new Player(playerOrID);
            game.addPlayer(player);
        }
    };

})(window, document);
