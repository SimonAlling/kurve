import { BooleanPreference } from "./lib/preferences/BooleanPreference.js";
import { MultichoicePreference } from "./lib/preferences/MultichoicePreference.js";

import TEXT from "./locales/Zatacka.en_US.js";
import STRINGS from "./strings.js";

export default [
    {
        type: BooleanPreference,
        key: STRINGS.pref_key_prevent_spawnkill,
        label: TEXT.pref_label_prevent_spawnkill,
        description: TEXT.pref_label_description_prevent_spawnkill,
        default: false,
    },
    {
        type: BooleanPreference,
        key: STRINGS.pref_key_confirm_quit,
        label: TEXT.pref_label_confirm_quit,
        description: TEXT.pref_label_description_confirm_quit,
        default: true,
    },
    {
        type: MultichoicePreference,
        key: STRINGS.pref_key_scaling,
        label: TEXT.pref_label_scaling,
        description: TEXT.pref_label_description_scaling,
        options: [
            {
                key: STRINGS.pref_value_scaling_prefer_quality,
                label: TEXT.pref_label_scaling_prefer_quality,
            },
            {
                key: STRINGS.pref_value_scaling_prefer_size,
                label: TEXT.pref_label_scaling_prefer_size,
            },
        ],
        default: STRINGS.pref_value_scaling_prefer_quality,
    },
    {
        type: MultichoicePreference,
        key: STRINGS.pref_key_cursor,
        label: TEXT.pref_label_cursor,
        description: TEXT.pref_label_description_cursor,
        options: [
            {
                key: STRINGS.pref_value_cursor_always_visible,
                label: TEXT.pref_label_cursor_always_visible,
            },
            {
                key: STRINGS.pref_value_cursor_hidden_when_mouse_used_by_player,
                label: TEXT.pref_label_cursor_hidden_when_mouse_used_by_player,
            },
            {
                key: STRINGS.pref_value_cursor_always_hidden,
                label: TEXT.pref_label_cursor_always_hidden,
            },
        ],
        default: STRINGS.pref_value_cursor_hidden_when_mouse_used_by_player,
    },
    {
        type: MultichoicePreference,
        key: STRINGS.pref_key_edge_fix,
        label: TEXT.pref_label_edge_fix,
        description: TEXT.pref_label_description_edge_fix,
        options: [
            {
                key: STRINGS.pref_value_edge_fix_off,
                label: TEXT.pref_label_edge_fix_off,
            },
            {
                key: STRINGS.pref_value_edge_fix_minimal,
                label: TEXT.pref_label_edge_fix_minimal,
            },
            {
                key: STRINGS.pref_value_edge_fix_full,
                label: TEXT.pref_label_edge_fix_full,
            },
        ],
        default: STRINGS.pref_value_edge_fix_off,
    },
    {
        type: MultichoicePreference,
        key: STRINGS.pref_key_hints,
        label: TEXT.pref_label_hints,
        description: TEXT.pref_label_description_hints,
        options: [
            {
                key: STRINGS.pref_value_hints_all,
                label: TEXT.pref_label_hints_all,
            },
            {
                key: STRINGS.pref_value_hints_warnings_only,
                label: TEXT.pref_label_hints_warnings_only,
            },
            {
                key: STRINGS.pref_value_hints_none,
                label: TEXT.pref_label_hints_none,
            },
        ],
        default: STRINGS.pref_value_hints_all,
    },
];
