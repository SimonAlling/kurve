"use strict";

class MultichoicePreference extends Preference {
    constructor(data) {
        if (!isNonEmptyStringArray(data.values)) {
            throw new TypeError(`values must be a non-empty string array (found ${data.values} for preference '${data.key}').`);
        }
        super(data);
        this.values = data.values;
        this.labels = data.labels;
        if (!this.isValidValue(data.default)) {
            super.invalidValue(data.default);
        }

        function isNonEmptyStringArray(strings) {
            return strings instanceof Array && strings.length > 0 && strings.every(isString);
        }
    }

    isValidValue(value) {
        return this.values.indexOf(value) > -1;
    }

    static stringify(value) {
        return value;
    }

    static parse(stringifiedValue) {
        return stringifiedValue;
    }
}
