"use strict";

class ConfirmationDialog extends Dialog {
    constructor(question, callback) {
        if (!(callback instanceof Function)) {
            throw new TypeError(`callback must be a function (found ${callback}).`);
        }
        super(question);
        this.callback = callback;
    }
}
