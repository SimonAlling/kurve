"use strict";

function GUIController(cfg) {

    const CLASS_ACTIVE = "active";
    const CLASS_HIDDEN = "hidden";

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

    const ORIGINAL_LEFT_WIDTH = left.offsetWidth;

    let currentMessages = [];


    // PRIVATE FUNCTIONS

    function hideLobby() {
        log("Hiding lobby.");
        lobby.classList.add(CLASS_HIDDEN);
    }

    function showLobby() {
        log("Showing lobby.");
        lobby.classList.remove(CLASS_HIDDEN);
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
            entry.children[1].classList.add(CLASS_ACTIVE);
        }
    }

    function playerUnready(id) {
        const index = id - 1;
        const entry = controls.children[index];
        if (!isLobbyEntry(entry)) {
            logWarning(`Cannot mark player ${id} as unready because controls.children[${index}] (${controls.children[index]}) is not a valid lobby entry.`);
        } else {
            entry.children[1].classList.remove(CLASS_ACTIVE);
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
    }

    function konecHry() {
        showKonecHry();
        resetScoreboard();
    }

    function showKonecHry() {
        KONEC_HRY.classList.remove(CLASS_HIDDEN);
    }

    function hideKonecHry() {
        KONEC_HRY.classList.add(CLASS_HIDDEN);
    }

    function showMessage(message) {
        if (!currentMessages.includes(message)) {
            currentMessages.push(message);
        }
        updateMessages(currentMessages);
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
        updateScoreOfPlayer,
        updateMessages,
        showMessage,
        hideMessage,
        clearMessages,
        setEdgePadding
    };

}