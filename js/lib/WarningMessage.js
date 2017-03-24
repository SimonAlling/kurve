import { Message } from "./Message.js";

export class WarningMessage extends Message {
    constructor(text) {
        super(text, "warning");
    }
}
