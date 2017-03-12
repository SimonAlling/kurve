"use strict";

class PreferenceWithValue {
    constructor(preference, value) {
        if (!preference.isValidValue(value)) {
            throw new TypeError(`${value} is not a valid value for preference ${preference.key}.`);
        }
        this.preference = preference;
        this.value = value;
    }
}
