import { isString, log, logWarning, logError } from "./PreferencesUtilities.js";
import { Preference } from "./Preference.js";
import { PreferenceWithValue } from "./PreferenceWithValue.js";

export function PreferenceManager(preferencesData) {
    const LOCALSTORAGE_PREFIX = "pref_key_";

    // Parse and validate preferences:
    log("Validating preferences ...");
    const PREFERENCES = parsePreferences(preferencesData);
    log("Done.");

    // Initialize cached preference database:
    const CACHED_PREFERENCES_WITH_VALUES = getAllPreferencesWithDefaultValues();
    CACHED_PREFERENCES_WITH_VALUES.forEach((preferenceWithValue) => {
        const key = preferenceWithValue.preference.key;
        const defaultValue = preferenceWithValue.preference.getDefaultValue();
        try {
            const savedValue = getSaved(key);
            if (savedValue === null) {
                log(`Using default value '${defaultValue}' for preference '${key}' since there was no saved value.`);
            }
            preferenceWithValue.value = savedValue !== null ? savedValue : defaultValue;
        } catch(e) {
            if (e instanceof TypeError) {
                logWarning(`Using default value '${defaultValue}' for preference '${key}' since the saved value in localStorage was not a valid one.`);
            } else {
                logWarning(`Using default value '${defaultValue}' for preference '${key}' since no saved value could be loaded from localStorage.`);
            }
        }
    });

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

    function getCachedPreference(key) {
        return CACHED_PREFERENCES_WITH_VALUES.find((preferenceWithValue) => preferenceWithValue.preference.key === key);
    }

    function getAllPreferencesWithValues_saved() { // throws SecurityError etc
        return PREFERENCES.map((preference) => new PreferenceWithValue(preference, getSaved(preference.key)));
    }

    function getAllPreferencesWithValues_cached() {
        return PREFERENCES.map((preference) => new PreferenceWithValue(preference, getCached(preference.key)));
    }

    function getAllPreferencesWithDefaultValues() {
        return PREFERENCES.map((preference) => new PreferenceWithValue(preference, preference.getDefaultValue()));
    }

    function getKey(pref) {
        return pref.key;
    }

    function isValidPreferenceValue(key, value) {
        return getPreference(key).isValidValue(value);
    }

    function setToDefaultValue(key) { // throws SecurityError etc
        set(key, getDefaultValue(key));
    }

    function getDefaultValue(key) {
        if (!preferenceExists(key)) {
            throw new Error(`Preference '${key}' does not exist.`);
        }
        return getPreference(key).getDefaultValue();
    }

    function LS_prefix(key) {
        return LOCALSTORAGE_PREFIX + key;
    }

    function set(key, value) { // throws SecurityError etc
        if (!preferenceExists(key)) {
            throw new Error(`There is no preference with key '${key}'.`);
        }
        const pref = getPreference(key);
        if (!isValidPreferenceValue(key, value)) {
            pref.invalidValue(value);
        } else {
            log(`Setting preference '${key}' to '${value}'.`);
            getCachedPreference(key).value = value;
            try {
                localStorage.setItem(LS_prefix(key), pref.constructor.stringify(value));
            } catch(e) {
                logError(`Failed to save value for preference '${key}' to localStorage. The following error was thrown:\n${e}`);
                throw e; // likely a SecurityError, but could be others as well
            }
        }
    }

    function getSaved(key) { // throws SecurityError, TypeError etc
        if (!preferenceExists(key)) {
            throw new Error(`There is no preference with key '${key}'.`);
        }
        const pref = getPreference(key);
        let savedValue;
        try {
            savedValue = localStorage.getItem(LS_prefix(key));
        } catch(e) {
            logError(`Failed to load saved value for preference '${key}' from localStorage. The following error was thrown:\n${e}`);
            throw e; // likely a SecurityError, but could be others as well
        }
        if (savedValue === null) {
            // There was no saved value.
            return null;
        } else if (isValidPreferenceValue(key, pref.constructor.parse(savedValue))) {
            return pref.constructor.parse(savedValue);
        } else {
            throw new TypeError(`'${savedValue}' could not be parsed to a valid value for preference '${pref}'.`);
        }
    }

    function getCached(key) {
        if (!preferenceExists(key)) {
            throw new Error(`There is no preference with key '${key}'.`);
        }
        return getCachedPreference(key).value;
    }

    function setAllToDefault() {
        log("Resetting all preferences ...");
        PREFERENCES.map(getKey).forEach(setToDefaultValue);
        log("Done.");
    }

    return {
        isValidPreferenceValue,
        set,
        getSaved,
        getCached,
        setToDefaultValue,
        getDefaultValue,
        getAllPreferencesWithValues_saved,
        getAllPreferencesWithValues_cached,
        getAllPreferencesWithDefaultValues,
        setAllToDefault
    }
}
