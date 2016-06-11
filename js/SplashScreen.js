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

    function showStartHint() {
        const startHintElement = byID(STRINGS.id_start_hint);
        if (isHTMLElement(startHintElement)) {
            startHintElement.textContent = TEXT.hint_start;
        }
    }

    function showFullscreenHint() {
        const fullscreenHintElement = byID(STRINGS.id_fullscreen_hint);
        if (isHTMLElement(fullscreenHintElement)) {
            fullscreenHintElement.textContent = TEXT.getFullscreenHint(PLATFORM.getFullscreenShortcut());
        }
    }

    function addEventListeners() {
        document.addEventListener("keydown", splashScreenKeyHandler);
        document.addEventListener("DOMContentLoaded", showStartHint);
        document.addEventListener("DOMContentLoaded", showFullscreenHint);
    }

    addEventListeners();
})();
