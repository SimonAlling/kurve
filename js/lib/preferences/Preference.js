"use strict";

class Preference {
    constructor(data) {
        if (!isString(data.key)) {
            throw new TypeError(`key must be a string (found ${data.key}). More info: ${data}`);
        } else if (data.default === undefined) {
            throw new TypeError(`Preference '${data.key}' must have a default value.`);
        }
        this.key = data.key;
        this.label = data.label;
        this.default = data.default;
    }

    isValidValue(value) {
        return isString(value);
    }

    invalidValue(value) {
        throw new TypeError(`${value} is not a valid value for preference '${this.key}'.`);
    }

    static stringify(value) {
        return value.toString();
    }

    static parse(stringifiedValue) {
        return stringifiedValue;
    }

    getDefaultValue() {
        return this.default;
    }
}
