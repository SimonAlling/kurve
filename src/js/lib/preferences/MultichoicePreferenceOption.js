import { isString, isNonEmptyString } from "./PreferencesUtilities.js";

export class MultichoicePreferenceOption {
    constructor(key, label) {
        const CLASS_MULTICHOICE_PREFERENCE = "MultichoicePreference";
        if (!isValidKey(key)) {
            throw new TypeError(`The key of a ${CLASS_MULTICHOICE_PREFERENCE} option must be a non-empty string (found ${key}).`);
        }
        if (!isValidLabel(label)) {
            throw new TypeError(`The label of a ${CLASS_MULTICHOICE_PREFERENCE} option must be a string (found ${label} for option '${key}').`);
        }

        this.key = key;
        this.label = label;

        function isValidKey(key) {
            return isNonEmptyString(key);
        }

        function isValidLabel(label) {
            return isString(label);
        }
    }
}
