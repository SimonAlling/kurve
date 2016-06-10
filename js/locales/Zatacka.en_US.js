"use strict";

const TEXT = (() => {
    const KEY_SHIFT = "⇧";
    const KEY_CMD   = "⌘";

    return Object.freeze({
        hint_start: `Press Space to start`,
        hint_pick: `Pick your desired color by pressing the corresponding LEFT key (e.g. M for Orange).`,
        hint_proceed: `Press Space or Enter to start!`,
        hint_next: `Press Space or Enter to proceed, or Esc to quit.`,
        hint_quit: `Press Space or Enter to start over.`,
        hint_alt: `Alt plus some other keys (e.g. Tab) may cause undesired behavior (e.g. switching windows).`,
        hint_ctrl: `Ctrl plus some other keys (e.g. W) may cause undesired behavior (e.g. closing the tab).`,
        hint_mouse: `Make sure to keep the mouse cursor inside the browser window.`,

        keyboard_fullscreen_mac: `${KEY_CMD} + ${KEY_SHIFT} + F`,
        keyboard_fullscreen_standard: "F11",

        getFullscreenHint: (shortcut) => `Press ${shortcut} to toggle fullscreen`,
    });
})();
