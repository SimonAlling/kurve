export default (() => {
    const KEY_SHIFT = "⇧";
    const KEY_CMD   = "⌘";
    const KEY_PROCEED = "Space or Enter";
    const KEY_QUIT = "Esc";

    return Object.freeze({
        hint_start: `Press <kbd>Space</kbd> to start`,
        hint_popup: `It is recommended to run Kurve in its own window without history (to avoid switching tabs or navigating back in history mid-game). Click here to do so.`,
        hint_pick: `Pick your desired color by pressing the corresponding LEFT key (e.g. M for Orange).`,
        hint_proceed: `Press ${KEY_PROCEED} to start!`,
        hint_next: `Press ${KEY_PROCEED} to proceed, or ${KEY_QUIT} to quit.`,
        hint_quit: `Press ${KEY_PROCEED} to start over.`,
        hint_alt: `Alt plus some other keys may cause undesired behavior (e.g. switching windows).`,
        hint_ctrl: `Ctrl plus some other keys may cause undesired behavior (e.g. closing the tab).`,
        hint_mouse: `Make sure to keep the mouse cursor inside the browser window.`,
        hint_preferences_access_denied: `Could not save/load settings because access to localStorage was denied by the browser. This might be caused by "third-party site data" being blocked or similar.`,

        keyboard_fullscreen_mac: `<kbd>${KEY_CMD} + Ctrl + F</kbd> and/or <kbd>${KEY_CMD} + ${KEY_SHIFT} + F</kbd>`,
        keyboard_fullscreen_standard: "<kbd>F11</kbd>",

        getFullscreenHint: (shortcut) => `Press ${shortcut} to toggle fullscreen`,

        label_button_alert_ok: `OK`,
        label_button_confirm_yes: `Yes`,
        label_button_confirm_no: `No`,

        label_text_confirm_quit: `Are you sure you want to quit?`,
        label_text_confirm_reload: `Are you sure you want to reload the application?`,

        pref_label_cursor: `Mouse pointer`,
        pref_label_description_cursor: `Control how the pointer behaves when the game is live. (It is always visible in the menu.) "Used by player" means that a player is using the mouse to control their Kurve.`,
        pref_label_cursor_always_visible: `Always visible`,
        pref_label_cursor_hidden_when_mouse_used_by_player: `Hidden when mouse used by player`,
        pref_label_cursor_always_hidden: `Always hidden`,

        pref_label_edge_fix: `Invisible border fix`,
        pref_label_description_edge_fix: `Shrink the playing field slightly to make the gray border visible if the monitor is exactly the same height and/or width as the game (in pixels).`,
        pref_label_edge_fix_off: `Off`,
        pref_label_edge_fix_minimal: `Minimal`,
        pref_label_edge_fix_full: `Full`,

        pref_label_hints: `Messages`,
        pref_label_description_hints: `Hints (white text) are unnecessary for experienced Kurve players. Warnings (yellow) can be useful for players new to playing Kurve in the browser.`,
        pref_label_hints_all: `Hints and warnings`,
        pref_label_hints_warnings_only: `Warnings only`,
        pref_label_hints_none: `None`,

        pref_label_prevent_spawnkill: `Prevent spawnkills`,
        pref_label_description_prevent_spawnkill: `Enforce a minimum distance between players at round start.`,

        pref_label_confirm_quit: `Confirm quit`,
        pref_label_description_confirm_quit: `Ask for confirmation before quitting to the main menu (Esc) or reloading the application (F5).`,

        pref_label_scaling: `Scaling`,
        pref_label_description_scaling: `Visual quality ensures a crisp, pixelmapped image. On-screen size may result in blurry graphics and other visual errors, but can be useful if the game is very small on your screen.`,
        pref_label_scaling_prefer_quality: `Prefer visual quality`,
        pref_label_scaling_prefer_size: `Prefer on-screen size`,
    });
})();
