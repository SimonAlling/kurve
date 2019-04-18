import { byID, KEY, MOUSE, Keyboard, Mouse, log, logWarning, logError } from "./lib/utilities.js";

import { Game } from "./Game.js";
import { Player } from "./Player.js";
import { Renderer } from "./Renderer.js";
import { GUIController } from "./GUIController.js";

import PREFERENCES from "./preferences.js";
import { PreferenceManager } from "./lib/preferences/PreferenceManager.js";

import { InfoMessage } from "./lib/InfoMessage.js";
import { WarningMessage } from "./lib/WarningMessage.js";
import { ConfirmationDialog } from "./lib/ConfirmationDialog.js";

import TEXT from "./locales/Zatacka.en_US.js";
import STRINGS from "./strings.js";

const Zatacka = (() => {

    const canvas_main = byID("canvas_main");
    const canvas_overlay = byID("canvas_overlay");
    const ORIGINAL_WIDTH = canvas_main.width;
    const ORIGINAL_HEIGHT = canvas_main.height;
    const TOTAL_BORDER_THICKNESS = 4;
    const KEY_RELOAD = KEY.F5;
    const KEY_FULLSCREEN = KEY.F11;
    const KEY_DEVTOOLS = KEY.F12;
    const ALLOWED_KEYS = [KEY_FULLSCREEN, KEY_DEVTOOLS]; // not to be intercepted by our event handler

    const config = Object.freeze({
        tickrate: 600, // Hz
        maxFramerate: 300, // Hz
        canvas: canvas_main,
        thickness: 3, // Kuxels
        speed: 60, // Kuxels per second
        turningRadius: 28.5, // Kuxels (NB: _radius_)
        minSpawnAngle: -Math.PI/2, // radians
        maxSpawnAngle:  Math.PI/2, // radians
        spawnMargin: 100, // Kuxels
        preventSpawnkill: false,
        flickerFrequency: 20, // Hz, when spawning
        flickerDuration: 830, // ms, when spawning
        minHoleInterval: 90, // Kuxels
        maxHoleInterval: 300, // Kuxels
        minHoleSize: 5, // Kuxels
        maxHoleSize: 9, // Kuxels
        hintDelay: 3000, // ms
        keys: {
            "proceed": [KEY.SPACE, KEY.ENTER],
            "quit":    [KEY.ESCAPE]
        },
        messages: Object.freeze({
            pick:    new InfoMessage(TEXT.hint_pick),
            proceed: new InfoMessage(TEXT.hint_proceed),
            next:    new InfoMessage(TEXT.hint_next),
            quit:    new InfoMessage(TEXT.hint_quit),
            popup:   new WarningMessage(`<a href="${STRINGS.game_url}" target="_blank">` + TEXT.hint_popup + `</a>`),
            alt:     new WarningMessage(TEXT.hint_alt),
            ctrl:    new WarningMessage(TEXT.hint_ctrl),
            mouse:   new WarningMessage(TEXT.hint_mouse),
            preferences_access_denied: new WarningMessage(TEXT.hint_preferences_access_denied),
            preferences_localstorage_failed: new WarningMessage(TEXT.hint_preferences_localstorage_failed),
        }),
        dialogs: Object.freeze({
            confirmation_quit: new ConfirmationDialog(TEXT.label_text_confirm_quit, quitGame),
            confirmation_reload: new ConfirmationDialog(TEXT.label_text_confirm_reload, reload),
        }),
        defaultPlayers: Object.freeze([
            { id: 1, name: "Red"   , color: "#FF2800", keyL: KEY["1"]                              , keyR: KEY.Q                         },
            { id: 2, name: "Yellow", color: "#C3C300", keyL: [ KEY.CTRL, KEY.Z ]                   , keyR: [ KEY.ALT, KEY.X ]            },
            { id: 3, name: "Orange", color: "#FF7900", keyL: KEY.M                                 , keyR: KEY.COMMA                     },
            { id: 4, name: "Green" , color: "#00CB00", keyL: KEY.LEFT_ARROW                        , keyR: KEY.DOWN_ARROW                },
            { id: 5, name: "Pink"  , color: "#DF51B6", keyL: [ KEY.DIVIDE, KEY.END, KEY.PAGE_DOWN ], keyR: [ KEY.MULTIPLY, KEY.PAGE_UP ] },
            { id: 6, name: "Blue"  , color: "#00A2CB", keyL: MOUSE.LEFT                            , keyR: MOUSE.RIGHT                   }
        ])
    });

    const preferenceManager = new PreferenceManager(PREFERENCES);

    function isProceedKey(key) {
        return config.keys.proceed.includes(key);
    }

    function isQuitKey(key) {
        return config.keys.quit.includes(key);
    }

    function shouldPreventDefault(key) {
        return !(ALLOWED_KEYS.includes(key));
    }

    function setEdgePadding(padding) {
        if (game.isStarted()) {
            throw new Error("Cannot change edge padding when the game is running.");
        } else {
            const newCanvasWidth = ORIGINAL_WIDTH - padding;
            const newCanvasHeight = ORIGINAL_HEIGHT - 2*padding;
            game.setSize(newCanvasWidth, newCanvasHeight);
            guiController.setEdgePadding(padding);
        }
    }

    function setEdgeMode(mode) {
        let padding = 0;
        if (mode === "minimal") {
            padding = 1;
        } else if (mode === "full") {
            padding = TOTAL_BORDER_THICKNESS;
        }
        try {
            setEdgePadding(padding);
        } catch(e) {
            logError(e);
        }
    }

    function setScalingMode(mode) {
        guiController.setBlurryScaling(mode === STRINGS.pref_value_scaling_prefer_size);
    }

    function setPreventSpawnkill(mode) {
        if (game.isStarted()) {
            throw new Error("Cannot change edge padding when the game is running.");
        } else {
            game.setPreventSpawnkill(mode);
        }
    }

    function getHoleConfig() {
        return {
            minHoleSize: config.minHoleSize,
            maxHoleSize: config.maxHoleSize,
            minHoleInterval: config.minHoleInterval,
            maxHoleInterval: config.maxHoleInterval
        };
    }

    function getPaddedHoleConfig() {
        const thickness = config.thickness;
        const holeConfig = getHoleConfig();
        const paddedHoleConfig = {};
        paddedHoleConfig.minPaddedHoleSize = holeConfig.minHoleSize + thickness;
        paddedHoleConfig.maxPaddedHoleSize = holeConfig.maxHoleSize + thickness;
        paddedHoleConfig.minPaddedHoleInterval = Math.max(0, holeConfig.minHoleInterval - thickness);
        paddedHoleConfig.maxPaddedHoleInterval = Math.max(0, holeConfig.maxHoleInterval - thickness);
        return paddedHoleConfig;
    }

    function defaultPlayerData(id) {
        return config.defaultPlayers.find(defaultPlayer => defaultPlayer.id === id);
    }

    function defaultPlayer(id) {
        const playerData = defaultPlayerData(id);
        if (playerData === undefined) {
            throw new TypeError(`There is no default player with ID ${id}.`);
        }
        return new Player(playerData.id,
                          playerData.name,
                          playerData.color,
                          playerData.keyL,
                          playerData.keyR,
                          getPaddedHoleConfig());
    }

    function applyCursorBehavior() {
        const mouseIsBeingUsed = game.getPlayers().some(hasMouseButton);
        let behavior;
        switch (preferenceManager.getCached(STRINGS.pref_key_cursor)) {
            case STRINGS.pref_value_cursor_hidden_when_mouse_used_by_player:
                behavior = mouseIsBeingUsed ? STRINGS.cursor_hidden : STRINGS.cursor_visible;
                break;
            case STRINGS.pref_value_cursor_always_hidden:
                behavior = STRINGS.cursor_hidden;
                break;
            default:
                behavior = STRINGS.cursor_visible;
        }
        log(`Setting cursor behavior to ${behavior}.`);
        guiController.setCursorBehavior(behavior);
    }

    function proceedKeyPressedInLobby() {
        const numberOfReadyPlayers = game.getNumberOfPlayers();
        if (numberOfReadyPlayers > 0) {
            clearMessages();
            applyCursorBehavior();
            game.setMode(numberOfReadyPlayers === 1 ? Game.PRACTICE : Game.COMPETITIVE);
            game.start();
        }
    }

    function hasMouseButton(player) {
        return player.usesAnyMouseButton();
    }

    function checkForDangerousInput() {
        if (game.getPlayers().some((player) => player.hasKey(KEY.CTRL))) {
            guiController.showMessage(config.messages.ctrl);
        } else {
            guiController.hideMessage(config.messages.ctrl);
        }

        if (game.getPlayers().some((player) => player.hasKey(KEY.ALT))) {
            guiController.showMessage(config.messages.alt);
        } else {
            guiController.hideMessage(config.messages.alt);
        }

        if (game.getPlayers().some(hasMouseButton)) {
            guiController.showMessage(config.messages.mouse);
        } else {
            guiController.hideMessage(config.messages.mouse);
        }
    }

    function addPlayer(id) {
        game.addPlayer(defaultPlayer(id));
        checkForDangerousInput();
        clearTimeout(hintPickTimer);
        guiController.hideMessage(config.messages.pick);
        clearTimeout(hintProceedTimer);
        hintProceedTimer = setTimeout(() => {
            guiController.showMessage(config.messages.proceed);
        }, config.hintDelay);
    }

    function removePlayer(id) {
        game.removePlayer(id);
        checkForDangerousInput();
        clearTimeout(hintProceedTimer);
        if (game.getNumberOfPlayers() === 0) {
            guiController.hideMessage(config.messages.proceed);
        } else {
            hintProceedTimer = setTimeout(() => {
                guiController.showMessage(config.messages.proceed);
            }, config.hintDelay);
        }
    }

    function defaultPlayerHasLeftKey(playerData, pressedKey) {
        return pressedKey === playerData.keyL || (playerData.keyL instanceof Array && playerData.keyL.includes(pressedKey));
    }

    function defaultPlayerHasRightKey(playerData, pressedKey) {
        return pressedKey === playerData.keyR || (playerData.keyR instanceof Array && playerData.keyR.includes(pressedKey));
    }

    function addOrRemovePlayer(playerData, pressedKey) {
        if (defaultPlayerHasLeftKey(playerData, pressedKey)) {
            addPlayer(playerData.id);
        } else if (defaultPlayerHasRightKey(playerData, pressedKey)) {
            removePlayer(playerData.id);
        }
    }

    function eventConsumer(event) {
        event.stopPropagation();
        event.preventDefault();
    }

    function keyPressedInLobby(pressedKey) {
        config.defaultPlayers.forEach((playerData) => {
            addOrRemovePlayer(playerData, pressedKey);
        });
    }

    function mouseClickedInLobby(button) {
        config.defaultPlayers.forEach((playerData) => {
            addOrRemovePlayer(playerData, MOUSE.pack(button));
        });
    }

    function keyHandler(event) {
        const callback = game.isStarted() ? gameKeyHandler
                                          : guiController.isShowingSettings() ? settingsKeyHandler
                                                                              : lobbyKeyHandler;
        guiController.keyPressed(event, callback);
    }

    function mouseHandler(event) {
        const handle = (
            game.isStarted() ? gameMouseHandler :
            guiController.isShowingSettings() ? settingsMouseHandler :
            guiController.isShowingDialog() ? eventConsumer :
            event.target instanceof HTMLAnchorElement ? () => {} :
            lobbyMouseHandler
        );
        handle(event);
    }

    function unloadHandler(event) {
        if (game.isStarted()) {
            gameUnloadHandler(event);
        }
    }

    function lobbyKeyHandler(event) {
        if (shouldPreventDefault(event.keyCode)) {
            event.preventDefault();
        }
        const pressedKey = event.keyCode;
        if (pressedKey === KEY_RELOAD) {
            reload();
        } else if (isProceedKey(pressedKey)) {
            proceedKeyPressedInLobby();
        } else {
            keyPressedInLobby(pressedKey);
        }
    }

    function lobbyMouseHandler(event) {
        mouseClickedInLobby(event.button);
    }

    function reload() {
        window.removeEventListener("beforeunload", unloadHandler);
        window.location.reload();
    }

    function quitGame() {
        game.quit();
        guiController.gameQuit();
        game = newGame();
        applySettings();
    }

    function gameKeyHandler(event) {
        if (shouldPreventDefault(event.keyCode)) {
            event.preventDefault();
        }
        const pressedKey = event.keyCode;
        if (isProceedKey(pressedKey)) {
            if (game.isPaused()) {
                game.resume();
            } else if (game.shouldQuitOnProceedKey()) {
                quitGame();
            } else {
                game.proceedKeyPressed();
            }
        } else if (isQuitKey(pressedKey) && game.shouldQuitOnQuitKey()) {
            if (preferenceManager.getCached(STRINGS.pref_key_confirm_quit) === true && !(guiController.isShowingDialog())) {
                guiController.showDialog(config.dialogs.confirmation_quit);
            } else {
                quitGame();
            }
        } else if (pressedKey === KEY_RELOAD) {
            if (preferenceManager.getCached(STRINGS.pref_key_confirm_quit) === true) {
                if (game.shouldShowReloadConfirmationOnReloadKey() && !(guiController.isShowingDialog())) {
                    guiController.showDialog(config.dialogs.confirmation_reload, reload);
                }
            } else {
                reload();
            }
        }
    }

    function gameMouseHandler(event) {
        event.preventDefault();
    }

    function gameUnloadHandler(event) {
        // A simple trick to prevent accidental unloading of the entire game.
        return event.returnValue = true;
    }

    function settingsKeyHandler(event) {
        const pressedKey = event.keyCode;
        if (isQuitKey(pressedKey)) {
            hideSettings();
        } else if (pressedKey === KEY_RELOAD) {
            reload();
        }
    }

    function settingsMouseHandler(event) {
        // Intentionally empty.
    }

    function showSettings() {
        clearTimeout(hintPickTimer);
        clearTimeout(hintProceedTimer);
        try {
            guiController.updateSettingsForm(preferenceManager.getAllPreferencesWithValues_saved());
        } catch(e) {
            logWarning("Could not load settings from localStorage. Using cached settings instead.");
            guiController.updateSettingsForm(preferenceManager.getAllPreferencesWithValues_cached());
            handleSettingsAccessError(e);
        }
        guiController.showSettings();
    }

    function hideSettings() {
        guiController.parseSettingsForm().forEach((newSetting) => {
            try {
                preferenceManager.set(newSetting.key, newSetting.value);
            } catch(e) {
                logWarning(`Could not save setting '${newSetting.key}' to localStorage.`);
                handleSettingsAccessError(e);
            }
        });
        applySettings();
        guiController.hideSettings();
    }

    function applySettings() {
        let preference_value_edge_fix;
        let preference_value_hints;
        let preference_value_prevent_spawnkill;
        let preference_value_scaling;
        try {
            preference_value_edge_fix = preferenceManager.getSaved(STRINGS.pref_key_edge_fix);
            preference_value_hints = preferenceManager.getSaved(STRINGS.pref_key_hints);
            preference_value_prevent_spawnkill = preferenceManager.getSaved(STRINGS.pref_key_prevent_spawnkill);
            preference_value_scaling = preferenceManager.getSaved(STRINGS.pref_key_scaling);
        } catch(e) {
            logWarning("Could not load settings from localStorage. Using cached settings instead.");
            preference_value_edge_fix = preferenceManager.getCached(STRINGS.pref_key_edge_fix);
            preference_value_hints = preferenceManager.getCached(STRINGS.pref_key_hints);
            preference_value_prevent_spawnkill = preferenceManager.getCached(STRINGS.pref_key_prevent_spawnkill);
            preference_value_scaling = preferenceManager.getCached(STRINGS.pref_key_scaling);
            handleSettingsAccessError(e);
        }

        // Edge fix:
        setEdgeMode(preference_value_edge_fix);
        // Hints:
        guiController.setMessageMode(preference_value_hints);
        // Prevent spawnkill:
        game.setPreventSpawnkill(preference_value_prevent_spawnkill);
        // Blurry scaling:
        setScalingMode(preference_value_scaling);
    }

    function handleSettingsAccessError(error) {
        if (error.name === STRINGS.error_name_security) {
            guiController.showMessage(config.messages.preferences_access_denied);
        } else {
            guiController.showMessage(config.messages.preferences_localstorage_failed);
        }
    }

    function clearMessages() {
        clearTimeout(hintPickTimer);
        clearTimeout(hintProceedTimer);
        guiController.clearMessages();
    }

    function blurHandler() {
        logWarning("Application lost focus.");
        if (game.isLive()) {
            game.pause();
        }
        Keyboard.reset();
        Mouse.reset();
    }

    function addShowSettingsButtonEventListener() {
        const showSettingsButton = byID(STRINGS.id_button_show_settings);
        if (showSettingsButton instanceof HTMLElement) {
            showSettingsButton.addEventListener("mousedown", eventConsumer);
            showSettingsButton.addEventListener("click", showSettings);
        }
    }

    function addHideSettingsButtonEventListener() {
        const hideSettingsButton = byID(STRINGS.id_button_hide_settings);
        if (hideSettingsButton instanceof HTMLElement) {
            hideSettingsButton.addEventListener("mousedown", eventConsumer);
            hideSettingsButton.addEventListener("click", hideSettings);
        }
    }

    function handleHistoryHazards() {
        if (history && history.length > 1) {
            guiController.showMessage(config.messages.popup);
        }
    }

    function addEventListeners() {
        log("Adding event listeners ...");

        // Hide/show settings:
        addShowSettingsButtonEventListener();
        addHideSettingsButtonEventListener();

        // General event handlers:
        document.addEventListener("keydown", keyHandler);
        document.addEventListener("mousedown", mouseHandler);
        document.addEventListener("contextmenu", eventConsumer);
        window.addEventListener("beforeunload", unloadHandler);
        window.addEventListener("blur", blurHandler);

        // Player input:
        document.addEventListener("keydown", Keyboard.onKeydown.bind(Keyboard));
        document.addEventListener("keyup", Keyboard.onKeyup.bind(Keyboard));
        document.addEventListener("mousedown", Mouse.onMousedown.bind(Mouse));
        document.addEventListener("mouseup", Mouse.onMouseup.bind(Mouse));

        log("Done.");
    }

    addEventListeners();

    function newGame() {
        return new Game(config, Renderer(canvas_main, canvas_overlay), guiController);
    }

    const guiController = GUIController(config);
    let game = newGame();

    let hintProceedTimer;
    let hintPickTimer = setTimeout(() => {
        guiController.showMessage(config.messages.pick);
    }, config.hintDelay);

    applySettings();
    handleHistoryHazards();

    return {
        getConfig: () => config,
        getGame: () => game,
        addPlayer: (playerOrID) => {
            const player = Player.isPlayer(playerOrID) ? playerOrID : new Player(playerOrID);
            game.addPlayer(player);
        }
    };

})();
