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
        hint_alt: `Alt plus some other keys may cause undesired behavior (e.g. switching windows).`,
        hint_ctrl: `Ctrl plus some other keys may cause undesired behavior (e.g. closing the tab).`,
        hint_mouse: `Make sure to keep the mouse cursor inside the browser window.`,

        keyboard_fullscreen_mac: `${KEY_CMD} + ${KEY_SHIFT} + F`,
        keyboard_fullscreen_standard: "F11",

        getFullscreenHint: (shortcut) => `Press ${shortcut} to toggle fullscreen`,

        pref_label_cursor: `Cursor`,
        pref_label_description_cursor: `Control how the cursor behaves when the game is running.`,
        pref_label_cursor_always_visible: `Always visible`,
        pref_label_cursor_hidden_when_mouse_used_by_player: `Hidden when mouse used by player`,
        pref_label_cursor_always_hidden: `Always hidden`,

        pref_label_edge_fix: `Edge fix`,
        pref_label_description_edge_fix: `Shrink the playing field slightly to make the edge visible if the monitor is exactly the same height or width as the game.`,
        pref_label_edge_fix_full: `Full`,
        pref_label_edge_fix_minimal: `Minimal`,
        pref_label_edge_fix_off: `Off`,

        pref_label_hints: `Hints`,
        pref_label_description_hints: `Hints, except for warnings, are redundant for experienced Kurve players.`,
        pref_label_hints_all: `All`,
        pref_label_hints_warnings_only: `Warnings only`,
        pref_label_hints_none: `None`,

        pref_label_prevent_spawnkill: `Prevent spawnkills`,
        pref_label_description_prevent_spawnkill: `Enforce a minimum distance between player spawns.`,
    });
})();
