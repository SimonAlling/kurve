export default (() => {
    const KEY_SHIFT = "⇧";
    const KEY_CMD   = "⌘";
    const KEY_PROCEED = "Space or Enter";
    const KEY_QUIT = "Esc";

    return Object.freeze({
        hint_unload: `Are you sure you want to unload the page?`,
        hint_start: `Press <kbd>Space</kbd> to start`,
        hint_popup: `It is recommended to run Kurve in its own window without history (to avoid switching tabs or navigating back in history mid-game). To do that, please allow popups or <a href="ZATACKA.html" target="_blank">click here</a>.`,
        hint_pick: `Pick your desired color by pressing the corresponding LEFT key (e.g. M for Orange).`,
        hint_proceed: `Press ${KEY_PROCEED} to start!`,
        hint_next: `Press ${KEY_PROCEED} to proceed, or ${KEY_QUIT} to quit.`,
        hint_quit: `Press ${KEY_PROCEED} to start over.`,
        hint_alt: `Alt plus some other keys may cause undesired behavior (e.g. switching windows).`,
        hint_ctrl: `Ctrl plus some other keys may cause undesired behavior (e.g. closing the tab).`,
        hint_mouse: `Make sure to keep the mouse cursor inside the browser window.`,
        hint_preferences_access_denied: `Could not save/load settings because access to localStorage was denied by the browser. This might be caused by "third-party site data" being blocked or similar.`,
        hint_preferences_localstorage_failed: `Could not save/load settings because access to localStorage failed.`,

        keyboard_fullscreen_mac: `<kbd>${KEY_CMD} + Ctrl + F</kbd> and/or <kbd>${KEY_CMD} + ${KEY_SHIFT} + F</kbd>`,
        keyboard_fullscreen_standard: "<kbd>F11</kbd>",

        getFullscreenHint: (shortcut) => `Press ${shortcut} to toggle fullscreen`,

        label_button_alert_ok: `OK`,
        label_button_confirm_yes: `Yes`,
        label_button_confirm_no: `No`,

        label_text_confirm_quit: `Are you sure you want to quit?`,
        label_text_confirm_reload: `Are you sure you want to reload the application?`,

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
        pref_label_description_hints: `Hints may be redundant for experienced Kurve players.`,
        pref_label_hints_all: `All`,
        pref_label_hints_warnings_only: `Warnings only`,
        pref_label_hints_none: `None`,

        pref_label_prevent_spawnkill: `Prevent spawnkills`,
        pref_label_description_prevent_spawnkill: `Enforce a minimum distance between player spawns.`,

        pref_label_confirm_quit: `Confirm quit`,
        pref_label_description_confirm_quit: `Ask for confirmation before quitting to the main menu.`,

        pref_label_confirm_reload: `Confirm reload`,
        pref_label_description_confirm_reload: `Ask for confirmation before reloading the application.`,

        pref_label_allow_blurry_scaling: `Allow blurry scaling`,
        pref_label_description_allow_blurry_scaling: `Let the game use the available screen area more efficiently at the expense of visual quality. Can be useful if the game is very small on your screen.`,
    });
})();
