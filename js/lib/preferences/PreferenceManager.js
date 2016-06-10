"use strict";

function PreferenceManager(preferencesData) {
    const LOCALSTORAGE_PREFIX = "pref_key_";

    // Parse and validate preferences:
    log("Validating preferences ...");
    const PREFERENCES = parsePreferences(preferencesData);
    log("Done.");

    function parsePreferences(preferencesData) {
        return preferencesData.map(parsePreference);
    }

    function parsePreference(pref, index) {
        if (!isString(pref.key)) {
            throw new TypeError(`'The preference at index ${index} does not have a valid key (found ${pref.key}).`);
        } else if (pref.type === undefined || !(pref.type.prototype instanceof Preference)) {
            throw new TypeError(`Preference '${pref.key}' does not use a valid preference type (found ${pref.type}).`);
        } else if (pref.default === undefined) {
            throw new TypeError(`Preference '${pref.key}' has no default value.`);
        }
        return new (pref.type)(pref);
    }

    function preferenceExists(key) {
        return getPreference(key) !== undefined;
    }

    function getPreference(key) {
        return PREFERENCES.find((pref) => pref.key === key);
    }

    function getKey(pref) {
        return pref.key;
    }

    function isValidPreferenceValue(key, value) {
        return getPreference(key).isValidValue(value);
    }

    function setToDefaultValue(key) {
        set(key, getDefaultValue(key));
    }

    function getDefaultValue(key) {
        if (!preferenceExists(key)) {
            throw new Error(`Preference ${key} does not exist.`);
        }
        return getPreference(key).getDefaultValue();
    }

    function LS_prefix(key) {
        return LOCALSTORAGE_PREFIX + key;
    }

    function set(key, value) {
        if (!preferenceExists(key)) {
            throw new Error(`There is no preference with key '${key}'.`);
        }
        const pref = getPreference(key);
        if (!isValidPreferenceValue(key, value)) {
            pref.invalidValue(value);
        } else {
            log(`Setting preference ${key} to ${value}.`);
            localStorage.setItem(LS_prefix(key), pref.stringify(value));
        }
    }

    function get(key) {
        if (!preferenceExists(key)) {
            throw new Error(`There is no preference with key '${key}'.`);
        }
        const pref = getPreference(key);
        const savedValue = localStorage.getItem(LS_prefix(key));
        return isValidPreferenceValue(key, savedValue) ? pref.parse(savedValue) : getDefaultValue(key);
    }

    function setAllToDefault() {
        log("Resetting all preferences ...");
        PREFERENCES.map(getKey).forEach(setToDefaultValue);
        log("Done.");
    }

    return {
        isValidPreferenceValue,
        set,
        get,
        setToDefaultValue,
        getDefaultValue,
        setAllToDefault
    }
}