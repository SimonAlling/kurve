"use strict";

(() => {
    const PROCEED_KEYS = Object.freeze([KEY.SPACE, KEY.ENTER]);

    function isProceedKey(key) {
        return PROCEED_KEYS.some((proceedKey) => proceedKey === key);
    }

    function proceedToGame() {
        document.location.href = STRINGS.game_url;
    }

    function splashScreenKeyHandler(event) {
        const pressedKey = event.keyCode;
        if (isProceedKey(pressedKey)) {
            proceedToGame();
        }
    }

    function addEventListeners() {
        document.addEventListener("keydown", splashScreenKeyHandler);
    }

    addEventListeners();
})();
