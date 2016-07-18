"use strict";

function GUIController(cfg) {

    const config = cfg;
    const lobby = byID("lobby");
    const controls = byID("controls");
    const canvas_main = byID("canvas_main");
    const canvas_overlay = byID("canvas_overlay");
    const left = byID("left");
    const scoreboard = byID("scoreboard");
    const results = byID("results");
    const KONEC_HRY = byID("KONEC_HRY");
    const messagesContainer = byID("messages");
    const settingsContainer = byID("settings");
    const settingsForm = byID("settings-form");

    const ORIGINAL_LEFT_WIDTH = left.offsetWidth;

    let currentMessages = [];


    // PRIVATE FUNCTIONS

    function hideLobby() {
        log("Hiding lobby.");
        lobby.classList.add(STRINGS.class_hidden);
    }

    function showLobby() {
        log("Showing lobby.");
        lobby.classList.remove(STRINGS.class_hidden);
    }

    function isLobbyEntry(element) {
        return isHTMLElement(element) && element.children.length >= 2;
    }

    function resetScoreboardEntry(entry) {
        entry.classList.remove("active");
    }

    function resetScoreboard() {
        Array.from(scoreboard.children).forEach(resetScoreboardEntry);
    }

    function resetResults() {
        Array.from(results.children).forEach(resetScoreboardEntry);
    }

    function setCursorBehavior(behavior) {
        switch (behavior) {
            case STRINGS.cursor_visible:
                document.body.classList.remove(STRINGS.class_nocursor);
                break;
            case STRINGS.cursor_hidden:
                document.body.classList.add(STRINGS.class_nocursor);
                break;
            default:
                logError(`Cannot set cursor behavior to '${behavior}'.`);
        }
    }

    function settingsEntryHTMLElement(preference, preferenceValue) {
        if (!preference instanceof Preference) {
            throw new TypeError(`${preference} is not a preference.`);
        }

        // Common
        const div = document.createElement("div");
        const label = document.createElement("label");
        label.textContent = preference.label;
        label.setAttribute("for", `${STRINGS.html_name_preference_prefix}${preference.key}`);
        const description = document.createElement("aside");
        description.textContent = preference.description;
        description.classList.add(STRINGS.class_description);

        // Boolean
        if (preference instanceof BooleanPreference) {
            const input = document.createElement("input");
            input.type = "checkbox";
            input.dataset.key = preference.key;
            input.id = STRINGS.html_name_preference_prefix + preference.key;
            input.checked = preferenceValue === true;
            div.appendChild(input);
            div.appendChild(label);
        }

        // Multichoice
        else if (preference instanceof MultichoicePreference) {
            const fieldset = document.createElement("fieldset");
            const legend = document.createElement("legend");
            legend.textContent = preference.label;
            fieldset.appendChild(legend);
            preference.values.forEach((value, index) => {
                const id = STRINGS.html_name_preference_prefix + preference.key + "-" + preference.values[index];
                const radioButton = document.createElement("input");
                radioButton.type = "radio";
                radioButton.id = id;
                radioButton.name = STRINGS.html_name_preference_prefix + preference.key;
                radioButton.value = value;
                radioButton.dataset.key = preference.key;
                radioButton.checked = preferenceValue === value;
                const radioButtonLabel = document.createElement("label");
                radioButtonLabel.textContent = preference.labels[index];
                radioButtonLabel.setAttribute("for", id);
                fieldset.appendChild(radioButton);
                fieldset.appendChild(radioButtonLabel);
            });
            div.appendChild(fieldset);
        }

        // Range
        else if (preference instanceof RangePreference) {
            div.appendChild(label);
            const input = document.createElement("input");
            input.type = "number";
            input.name = STRINGS.html_name_preference_prefix + preference.key;
            div.appendChild(input);
        }

        div.appendChild(description);
        return div;
    }


    // PUBLIC API

    function setEdgePadding(padding) {
        left.style.width = `${ORIGINAL_LEFT_WIDTH + padding}px`;
    }

    function playerReady(id) {
        const index = id - 1;
        const entry = controls.children[index];
        if (!isLobbyEntry(entry)) {
            logWarning(`Cannot mark player ${id} as ready because controls.children[${index}] (${controls.children[index]}) is not a valid lobby entry.`);
        } else {
            entry.children[1].classList.add(STRINGS.class_active);
        }
    }

    function playerUnready(id) {
        const index = id - 1;
        const entry = controls.children[index];
        if (!isLobbyEntry(entry)) {
            logWarning(`Cannot mark player ${id} as unready because controls.children[${index}] (${controls.children[index]}) is not a valid lobby entry.`);
        } else {
            entry.children[1].classList.remove(STRINGS.class_active);
        }
    }

    function allPlayersUnready() {
        for (let id = 1; id <= controls.children.length; id++) {
            playerUnready(id);
        }
    }

    function gameStarted() {
        hideLobby();
    }

    function gameQuit() {
        hideKonecHry();
        showLobby();
        clearMessages();
        resetScoreboard();
        resetResults();
        allPlayersUnready();
        setCursorBehavior(STRINGS.cursor_visible);
    }

    function konecHry() {
        showKonecHry();
        resetScoreboard();
    }

    function showKonecHry() {
        KONEC_HRY.classList.remove(STRINGS.class_hidden);
    }

    function hideKonecHry() {
        KONEC_HRY.classList.add(STRINGS.class_hidden);
    }

    function showMessage(message) {
        if (!currentMessages.includes(message)) {
            currentMessages.push(message);
        }
        updateMessages(currentMessages);
    }

    function showSettings() {
        settings.classList.remove(STRINGS.class_hidden);
    }

    function hideSettings() {
        settings.classList.add(STRINGS.class_hidden);
    }

    function updateSettingsForm(preferencesWithData) {
        flush(settingsForm);
        preferencesWithData.forEach((preferenceWithData) => {
            settingsForm.appendChild(settingsEntryHTMLElement(preferenceWithData.preference, preferenceWithData.value));
        });
    }

    function parseSettingsForm() {
        const newSettings = [];
        // <input> elements:
        const inputs = settingsForm.querySelectorAll("input");
        inputs.forEach((input) => {
            if (input.type === "checkbox") {
                // checkbox
                newSettings.push({ key: input.dataset.key, value: input.checked });
            } else if (input.type === "radio") {
                // radio
                if (input.checked === true) {
                    newSettings.push({ key: input.dataset.key, value: input.value });
                }
            } else {
                // text, number etc
                newSettings.push({ key: input.dataset.key, value: input.value.toString() });
            }
        });
        // <select> elements:
        const selects = settingsForm.querySelectorAll("select");
        selects.forEach((select) => {
            newSettings.push({ key: select.dataset.key, value: select.options[select.selectedIndex].value });
        });
        return newSettings;
    }

    function hideMessage(message) {
        currentMessages = currentMessages.filter(msg => msg !== message);
        updateMessages(currentMessages);
    }

    function updateMessages(messages) {
        if (!isHTMLElement(messagesContainer)) {
            logWarning(`Cannot update messages because ${messagesContainer} is not an HTML element.`);
        } else {
            flush(messagesContainer);
            messages.forEach((message) => {
                messagesContainer.insertBefore(message.toHTMLElement(), null);
            });
        }
    }

    function clearMessages() {
        currentMessages = [];
        updateMessages(currentMessages);
    }

    function setMessageMode(mode) {
        log(`Setting message mode to ${mode}.`);
        switch (mode) {
            case STRINGS.pref_value_hints_warnings_only:
                messagesContainer.classList.remove(STRINGS.class_hints_none);
                messagesContainer.classList.add(STRINGS.class_hints_warnings_only);
                break;
            case STRINGS.pref_value_hints_none:
                messagesContainer.classList.remove(STRINGS.class_hints_warnings_only);
                messagesContainer.classList.add(STRINGS.class_hints_none);
                break;
            default:
                messagesContainer.classList.remove(STRINGS.class_hints_warnings_only);
                messagesContainer.classList.remove(STRINGS.class_hints_none);
        }
    }

    function updateBoard(board, id, newScore) {
        if (!isHTMLElement(board)) {
            logWarning(`Cannot update any entry in ${board} because it is not an HTML element.`);
        } else {
            const entry = board.children[id-1];
            if (!isHTMLElement(entry)) {
                logWarning(`Cannot update score of player ${id} because ${entry} is not an HTML element.`);
            } else {
                // The entry is an HTML element; let's update it!
                const digitClassFactory = digit => "d"+digit;
                const createDigit = () => document.createElement("div");
                // Turn 528 into ["d5", "d2", "d8"]:
                const newScoreDigitClasses = newScore.toString().split("").map(digitClassFactory);
                // Remove everything from the entry element before we insert new digits:
                flush(entry);
                entry.classList.add("active");
                newScoreDigitClasses.forEach((digitClass, index) => {
                    let digitElement = createDigit(); // A completely clean element ...
                    digitElement.classList.add(newScoreDigitClasses[index]); // ... that now has a digit class.
                    entry.appendChild(digitElement);
                });
            }
        }
    }

    function updateScoreOfPlayer(id, newScore) {
        updateBoard(scoreboard, id, newScore);
        updateBoard(results, id, newScore);
    }

    return {
        playerReady,
        playerUnready,
        gameStarted,
        gameQuit,
        konecHry,
        showSettings,
        hideSettings,
        updateSettingsForm,
        parseSettingsForm,
        updateScoreOfPlayer,
        updateMessages,
        showMessage,
        hideMessage,
        clearMessages,
        setMessageMode,
        setCursorBehavior,
        setEdgePadding
    };

}