import { Preference } from "./lib/preferences/Preference.js";
import { BooleanPreference } from "./lib/preferences/BooleanPreference.js";
import { RangePreference } from "./lib/preferences/RangePreference.js";
import { IntegerRangePreference } from "./lib/preferences/IntegerRangePreference.js";
import { MultichoicePreference } from "./lib/preferences/MultichoicePreference.js";

import { Dialog } from "./lib/Dialog.js";
import { ConfirmationDialog } from "./lib/ConfirmationDialog.js";

import { byID, flush, isHTMLElement, log, logWarning, logError, KEY, Keyboard } from "./lib/Utilities.js";
import TEXT from "./locales/Zatacka.en_US.js";
import STRINGS from "./strings.js";

export function GUIController(cfg) {

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
    // const settingsContainer = byID("settings");
    const dialogsOverlay = byID("dialogs");
    const settingsForm = byID("settings-form");

    const ORIGINAL_LEFT_WIDTH = left.offsetWidth;
    const MULTICHOICE_LABEL_MAX_LENGTH_FOR_HALFWIDTH_FIELDSET = 22; // More characters than this will result in a full-width div/fieldset.
    const FLOAT_RANGE_PREFERENCE_STEP = 0.01;

    const BUTTON_TAG_NAME = "button";
    const BUTTON_NODE_CLASS = HTMLButtonElement;

    const LABEL_ALERT_OK = TEXT.label_button_alert_ok;
    const LABEL_CONFIRM_YES = TEXT.label_button_confirm_yes;
    const LABEL_CONFIRM_NO = TEXT.label_button_confirm_no;

    let showingSettings = false;
    let currentMessages = [];
    let queuedDialogs = [];
    let currentDialogWithBox = null;

    class DialogWithBox {
        constructor(dialog, box) {
            this.dialog = dialog;
            this.box = box;
        }
    }


    // PRIVATE FUNCTIONS

    function hideLobby() {
        log("Hiding lobby.");
        lobby.classList.add(STRINGS.class_hidden);
    }

    function showLobby() {
        log("Showing lobby.");
        lobby.classList.remove(STRINGS.class_hidden);
    }

    function showDialogsOverlay() {
        dialogsOverlay.classList.remove(STRINGS.class_hidden);
    }

    function hideDialogsOverlay() {
        dialogsOverlay.classList.add(STRINGS.class_hidden);
    }

    function isLobbyEntry(element) {
        return isHTMLElement(element) && element.children.length >= 2;
    }

    function isButton(element) {
        return element instanceof BUTTON_NODE_CLASS;
    }

    function showDialogRightAway(dialog) {
        const dialogBox = dialogHTMLElement(dialog);
        currentDialogWithBox = new DialogWithBox(dialog, dialogBox);
        setTemporaryCursorVisibility(true);
        showDialogsOverlay();
        dialogsOverlay.appendChild(dialogBox);
        // A dialog should have its last button focused:
        dialogBox.querySelector("button:last-of-type").focus();
    }

    function currentDialogClosed() {
        currentDialogWithBox.box.remove();
        currentDialogWithBox = null;
        if (anyQueuedDialogs()) {
            // There is at least one dialog waiting. Show it:
            showDialogRightAway(queuedDialogs.shift());
        } else {
            // No more dialogs. Restore:
            setTemporaryCursorVisibility(false);
            hideDialogsOverlay();
        }
    }

    function anyQueuedDialogs() {
        return queuedDialogs.length > 0;
    }

    function escapeShouldCloseCurrentDialog() {
        return currentDialogWithBox.dialog instanceof ConfirmationDialog;
    }

    function dialogHTMLElementBoilerplate(text) {
        const dialogBox = document.createElement("div");
        dialogBox.classList.add(STRINGS.class_dialog);
        const label = document.createElement("p");
        label.textContent = text;
        dialogBox.appendChild(label);
        return dialogBox;
    }

    function alertDialogHTMLElement(dialog) {
        const alertDialogBox = dialogHTMLElementBoilerplate(dialog.text);
        alertDialogBox.classList.add(STRINGS.class_dialog_alert);
        const buttonOK = document.createElement("button");
        buttonOK.textContent = LABEL_ALERT_OK;
        alertDialogBox.appendChild(buttonOK);

        function alertDialogEventHandler() {
            currentDialogClosed();
        }
        // Event listener:
        buttonOK.addEventListener("click", alertDialogEventHandler);

        return alertDialogBox;
    }

    function confirmationDialogHTMLElement(confirmationDialog) {
        const confirmationDialogBox = dialogHTMLElementBoilerplate(confirmationDialog.text);
        confirmationDialogBox.classList.add(STRINGS.class_dialog_confirmation);
        const buttonYes = document.createElement("button");
        buttonYes.textContent = LABEL_CONFIRM_YES;
        const buttonNo  = document.createElement("button");
        buttonNo.textContent = LABEL_CONFIRM_NO;
        confirmationDialogBox.appendChild(buttonYes);
        confirmationDialogBox.appendChild(buttonNo);

        function confirmationDialogEventHandler(response) {
            return () => {
                currentDialogClosed();
                if (response === true) {
                    confirmationDialog.callback();
                }
            };
        }
        // Event listeners:
        buttonYes.addEventListener("click", confirmationDialogEventHandler(true));
        buttonNo.addEventListener("click", confirmationDialogEventHandler(false));

        return confirmationDialogBox;
    }

    function dialogHTMLElement(dialog) {
        if (dialog instanceof ConfirmationDialog) {
            return confirmationDialogHTMLElement(dialog);
        } else if (dialog instanceof Dialog) {
            return alertDialogHTMLElement(dialog);
        }
        throw new TypeError(`${dialog} is not a valid dialog.`);
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

    function setTemporaryCursorVisibility(tempCursorActive) {
        if (tempCursorActive) {
            document.body.classList.add(STRINGS.class_tempcursor);
        } else {
            document.body.classList.remove(STRINGS.class_tempcursor);
        }
    }

    function settingsEntryShouldBeHalfWidth(preference) {
        if (preference instanceof MultichoicePreference) {
            const longestValueLabel = preference.labels.reduce((acc, current) => current.length > acc.length ? current : acc);
            return longestValueLabel.length <= MULTICHOICE_LABEL_MAX_LENGTH_FOR_HALFWIDTH_FIELDSET;
        } else {
            return false;
        }
    }

    function settingsEntryHTMLElement(preference, preferenceValue) {
        if (!(preference instanceof Preference)) {
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
            if (settingsEntryShouldBeHalfWidth(preference)) {
                div.classList.add(STRINGS.class_half_width);
            }
        }

        // Range
        else if (preference instanceof RangePreference) {
            const isIntegerRange = preference instanceof IntegerRangePreference;
            div.appendChild(label);
            const input = document.createElement("input");
            input.type = "number";
            input.dataset.key = preference.key;
            input.dataset.numberType = isIntegerRange ? STRINGS.pref_number_type_integer : STRINGS.pref_number_type_float;
            input.name = STRINGS.html_name_preference_prefix + preference.key;
            input.setAttribute("step", isIntegerRange ? 1 : FLOAT_RANGE_PREFERENCE_STEP);
            input.setAttribute("min", preference.min);
            input.setAttribute("max", preference.max);
            input.value = preferenceValue;
            div.appendChild(input);
        }

        div.appendChild(description);
        return div;
    }


    // PUBLIC API

    function keyPressed(event, callback) {
        if (isShowingDialog()) {
            const currentlyFocusedButton = currentDialogWithBox.box.querySelector(`${BUTTON_TAG_NAME}:focus`);
            let previousButton, nextButton;
            if (isButton(currentlyFocusedButton)) {
                previousButton = isButton(currentlyFocusedButton.previousSibling) ? currentlyFocusedButton.previousSibling : null;
                nextButton = isButton(currentlyFocusedButton.nextSibling) ? currentlyFocusedButton.nextSibling : null;
            }
            switch (event.keyCode) {
                case KEY.SPACE:
                case KEY.ENTER:
                    // Necessary because buttons do not automatically react to Space until keyup, making them feel sluggish compared to when Enter is used.
                    if (isButton(currentlyFocusedButton)) {
                        currentlyFocusedButton.click();
                    }
                    break;
                case KEY.ESCAPE:
                    if (escapeShouldCloseCurrentDialog()) {
                        currentDialogClosed();
                    }
                    break;
                case KEY.TAB:
                    if (Keyboard.isDown(KEY.SHIFT)) {
                        if (isButton(previousButton)) {
                            previousButton.focus();
                        }
                    } else if (isButton(nextButton)) {
                        nextButton.focus();
                    }
                    break;
                case KEY.LEFT_ARROW:
                    if (isButton(previousButton)) {
                        previousButton.focus();
                    }
                    break;
                case KEY.RIGHT_ARROW:
                    if (isButton(nextButton)) {
                        nextButton.focus();
                    }
                    break;
                default:
                    callback(event);
            }
        } else {
            callback(event);
        }
    }

    function mouseClicked(event, callback) {
        if (isShowingDialog()) {
            // Do nothing particular, but consume the event.
        } else {
            callback(event);
        }
    }

    function showDialog(dialog) {
        if (isShowingDialog()) {
            queuedDialogs.push(dialog);
        } else {
            showDialogRightAway(dialog);
        }
    }

    function isShowingDialog() {
        return currentDialogWithBox !== null;
    }

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
        showingSettings = true;
        settings.classList.remove(STRINGS.class_hidden);
    }

    function hideSettings() {
        showingSettings = false;
        settings.classList.add(STRINGS.class_hidden);
    }

    function isShowingSettings() {
        return showingSettings;
    }

    function updateSettingsForm(preferencesWithData) {
        flush(settingsForm);
        let settingsEntries = preferencesWithData.map((preferenceWithData) => settingsEntryHTMLElement(preferenceWithData.preference, preferenceWithData.value));
        // Add special class to half-width divs on the right hand side:
        let consecutiveHalfWidthDivs = 0;
        for (let i = 0; i < settingsEntries.length; i++) {
            const currentEntry = settingsEntries[i];
            if (currentEntry.classList.contains(STRINGS.class_half_width)) {
                consecutiveHalfWidthDivs++;
                if (consecutiveHalfWidthDivs % 2 === 0) {
                    // Even number of consecutive half-width divs, so this one will be on the right hand side.
                    currentEntry.classList.add(STRINGS.class_right_hand_side);
                }
            } else {
                consecutiveHalfWidthDivs = 0;
            }
        }
        settingsEntries.forEach((settingsEntry) => {
            settingsForm.appendChild(settingsEntry);
        });
    }

    function parseSettingsForm() {
        const newSettings = [];
        // <input> elements:
        const inputs = settingsForm.querySelectorAll("input");
        Array.from(inputs).forEach((input) => {
            if (input.type === "checkbox") {
                // checkbox
                newSettings.push({ key: input.dataset.key, value: input.checked });
            } else if (input.type === "radio") {
                // radio
                if (input.checked === true) {
                    newSettings.push({ key: input.dataset.key, value: input.value });
                }
            } else if (input.type === "number") {
                // number
                newSettings.push({ key: input.dataset.key, value: (input.dataset.numberType === STRINGS.pref_number_type_integer ? parseInt : parseFloat)(input.value) });
            } else {
                // text
                newSettings.push({ key: input.dataset.key, value: input.value.toString() });
            }
        });
        // <select> elements:
        const selects = settingsForm.querySelectorAll("select");
        Array.from(selects).forEach((select) => {
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
        keyPressed,
        mouseClicked,
        playerReady,
        playerUnready,
        gameStarted,
        gameQuit,
        konecHry,
        showDialog,
        isShowingDialog,
        showSettings,
        hideSettings,
        isShowingSettings,
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