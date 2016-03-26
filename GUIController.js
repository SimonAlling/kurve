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

    function showScoreOfPlayer(id) {
        var index = id - 1;
        if (isHTMLElement(scoreboard)) {
            var scoreboardEntry = scoreboard.children[index];
            if (isHTMLElement(scoreboardEntry)) {
                scoreboardEntry.classList.add("active");
            }
        }
        if (isHTMLElement(results)) {
            var resultsEntry = results.children[index];
            if (isHTMLElement(resultsEntry)) {
                resultsEntry.classList.add("active");
            }
        }
    }


    // PUBLIC API

    function playerReady(id) {
    	var index = id - 1;
    	try {
    		controls.children[index].children[1].classList.add(CLASS_ACTIVE);
    	} catch (error) {
    		console.error(error);
    	}
    }

    function playerUnready(id) {
    	var index = id - 1;
    	try {
    		controls.children[index].children[1].classList.remove(CLASS_ACTIVE);
    	} catch (error) {
    		console.error(error);
    	}
    }

    function gameStarted() {
    	hideLobby();
    }

    function initScoreOfPlayer(id) {
    	updateScoreOfPlayer(id, 0);
    	showScoreOfPlayer(id);
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
    	playerReady: playerReady,
    	playerUnready: playerUnready,
    	gameStarted: gameStarted,
    	initScoreOfPlayer: initScoreOfPlayer,
    	updateScoreOfPlayer: updateScoreOfPlayer
    };

}