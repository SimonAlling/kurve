import { Preference } from "./Preference.js";

export class BooleanPreference extends Preference {
    constructor(data) {
        super(data);
        if (!(data.default === true || data.default === false)) {
            super.invalidValue(data.default);
        }
    }

    isValidValue(value) {
        return value === true || value === false;
    }

    static stringify(value) {
        return value.toString();
    }

    static parse(stringifiedValue) {
        return stringifiedValue === "true";
    }
}
