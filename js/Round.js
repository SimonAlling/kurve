"use strict";

class Round {
    constructor(players) {
        // A list of the players in the order they died (winner also included):
        this.results = [];
    }

    add(player) {
        this.results.push(player);
    }

    getSuccessOfPlayer(id) {
        for (let i = 0; i < this.results.length; i++) {
            if (this.results[i].hasID(id)) {
                return i;
            }
        }
        return this.results.length;
    }

    getResults() {
        return this.results;
    }
}
