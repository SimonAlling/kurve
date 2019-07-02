import { byID, KEY, isProceedKey, isHTMLElement, PLATFORM } from "./lib/utilities.js";
import STRINGS from "./strings.js";
import TEXT from "./locales/Zatacka.en_US.js";

(() => {
    const PROCEED_KEYS = [KEY.SPACE, KEY.ENTER];

    function isProceedKey(key) {
        return PROCEED_KEYS.some(proceedKey => proceedKey === key);
    }

    function proceedToGame() {
        const newWindow = window.open(STRINGS.game_url);
        if (!newWindow || newWindow.closed || typeof newWindow.closed === "undefined") {
            // Browser is blocking popups.
            window.location.href = STRINGS.game_url;
        }
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
            startHintElement.innerHTML = TEXT.hint_start;
        }
    }

    function showFullscreenHint() {
        const fullscreenHintElement = byID(STRINGS.id_fullscreen_hint);
        if (isHTMLElement(fullscreenHintElement)) {
            const fullscreenShortcut = PLATFORM.getFullscreenShortcut() === "mac" ? TEXT.keyboard_fullscreen_mac : TEXT.keyboard_fullscreen_standard;
            fullscreenHintElement.innerHTML = TEXT.getFullscreenHint(fullscreenShortcut);
        }
    }

    function addEventListeners() {
        document.addEventListener("keydown", splashScreenKeyHandler);
        document.addEventListener("DOMContentLoaded", showStartHint);
        document.addEventListener("DOMContentLoaded", showFullscreenHint);
    }

    addEventListeners();
})();
