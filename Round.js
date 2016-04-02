"use strict";

class Round {
    constructor(players) {
        // A list of the players in the order they died (winner also included):
        this.results = [];
    }

    add(player) {
        this.results.push(player);
    }

    getResults() {
        return this.results;
    }
}
