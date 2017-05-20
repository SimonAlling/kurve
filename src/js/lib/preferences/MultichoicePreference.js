import { Preference } from "./Preference.js";
import { MultichoicePreferenceOption } from "./MultichoicePreferenceOption.js";

export class MultichoicePreference extends Preference {
    constructor(data) {
        if (!isArray(data.options)) {
            throw new TypeError(`options must be an array (found ${data.options} for preference '${data.key}').`);
        }
        if (!hasMultipleEntries(data.options)) {
            throw new TypeError(`options must have a length greater than 1 (was ${data.options.length} for preference '${data.key}').`);
        }
        super(data);

        try {
            this.options = data.options.map(option => new MultichoicePreferenceOption(option.key, option.label));
        } catch(e) {
            throw new TypeError(`The list of options for preference '${data.key}' was malformed: ${e.message}`);
        }

        if (!this.isValidValue(data.default)) {
            super.invalidValue(data.default);
        }

        function isArray(options) {
            return options instanceof Array;
        }

        function hasMultipleEntries(options) {
            return options.length > 1;
        }
    }

    isValidValue(value) {
        return this.options.some(option => option.key === value);
    }

    static stringify(value) {
        return value;
    }

    static parse(stringifiedValue) {
        return stringifiedValue;
    }
}
