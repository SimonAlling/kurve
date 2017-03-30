import { Preference } from "./Preference.js";
import { RangePreference } from "./RangePreference.js";

import { isInt } from "./PreferencesUtilities.js";

export class IntegerRangePreference extends RangePreference {
    constructor(data) {
        if (!isInt(data.min) || !isInt(data.max)) {
            throw new TypeError(`min and max must be integers (found ${data.min} and ${data.max} for preference '${data.key}').`);
        }
        super(data);
        this.min = data.min;
        this.max = data.max;
        if (!this.isValidValue(data.default)) {
            super.invalidValue(data.default);
        }
    }

    isValidValue(value) {
        return isInt(value) && value >= this.min && value <= this.max;
    }

    static stringify(value) {
        return value.toString();
    }

    static parse(stringifiedValue) {
        return parseInt(stringifiedValue);
    }
}
