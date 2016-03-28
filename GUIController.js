"use strict";

function GUIController(cfg) {

    const CLASS_ACTIVE = "active";
    const CLASS_HIDDEN = "hidden";

    const config = cfg;
    const lobby = byID("lobby");
    const controls = byID("controls");
    const scoreboard = byID("scoreboard");
    const results = byID("results");
    const konecHry = byID("KONEC_HRY");



    // PRIVATE FUNCTIONS

    function hideLobby() {
        log("Hiding lobby.");
        lobby.classList.add(CLASS_HIDDEN);
    }

    function isLobbyEntry(element) {
        return isHTMLElement(element) && element.children.length >= 2;
    }


    // PUBLIC API

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

    function gameStarted() {
        hideLobby();
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
        updateScoreOfPlayer
    };

}