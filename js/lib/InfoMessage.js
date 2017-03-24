import { Message } from "./Message.js";

export class InfoMessage extends Message {
    constructor(text) {
        super(text, "info");
    }
}
