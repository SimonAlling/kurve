"use strict";

class BooleanPreference extends MultichoicePreference {
    constructor(data) {
        super({
            key: data.key,
            values: ["true", "false"],
            label: data.label,
            default: data.default
        });
    }

    static stringify(value) {
        return value.toString();
    }

    static parse(stringifiedValue) {
        return stringifiedValue === "true";
    }
}
