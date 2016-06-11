"use strict";

const STRINGS = (() => {
    return Object.freeze({
        game_url: "ZATACKA.html",

        class_hidden: "hidden",
        class_active: "active",
        class_nocursor: "nocursor",

        id_start_hint: "start-hint",
        id_fullscreen_hint: "fullscreen-hint",

        pref_key_cursor: "cursor",
        pref_value_cursor_always_visible: "always_visible",
        pref_value_cursor_hidden_when_mouse_used_by_player: "hidden_when_mouse_used_by_player",
        pref_value_cursor_always_hidden: "always_hidden",

        pref_key_hints: "hints",
        pref_value_hints_all: "all",
        pref_value_hints_warnings_only: "warnings",
        pref_value_hints_none: "none",
    });
})();
