"use strict";

const STRINGS = (() => Object.freeze({
    game_url: "ZATACKA.html",

    error_name_security: "SecurityError",

    class_hidden: "hidden",
    class_active: "active",
    class_dialog: "dialog",
    class_dialog_alert: "alert",
    class_dialog_confirmation: "confirmation",
    class_description: "description",
    class_half_width: "half-width",
    class_right_hand_side: "right-hand-side",
    class_nocursor: "nocursor",
    class_tempcursor: "tempcursor",
    class_hints_warnings_only: "hints-warnings-only",
    class_hints_none: "hints-none",
    html_name_preference_prefix: "preference-",

    cursor_hidden: "hidden",
    cursor_visible: "visible",

    id_start_hint: "start-hint",
    id_fullscreen_hint: "fullscreen-hint",
    id_popup_hint: "popup-hint",

    pref_number_type_integer: "integer",
    pref_number_type_float: "float",

    pref_key_cursor: "cursor",
    pref_value_cursor_always_visible: "always_visible",
    pref_value_cursor_hidden_when_mouse_used_by_player: "hidden_when_mouse_used_by_player",
    pref_value_cursor_always_hidden: "always_hidden",

    pref_key_edge_fix: "edge_fix",
    pref_value_edge_fix_full: "full",
    pref_value_edge_fix_minimal: "minimal",
    pref_value_edge_fix_off: "off",

    pref_key_hints: "hints",
    pref_value_hints_all: "all",
    pref_value_hints_warnings_only: "warnings",
    pref_value_hints_none: "none",

    pref_key_confirm_quit: "confirm_quit",
    pref_key_prevent_spawnkill: "prevent_spawnkill",
}))();
