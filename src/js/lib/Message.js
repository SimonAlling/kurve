export class Message {
    constructor(text, styleClass) {
        this.text = text;
        this.class = styleClass;
    }

    toHTMLElement() {
    	const p = document.createElement("p");
    	p.innerHTML = this.text;
    	p.classList.add(this.class);
    	p.classList.add("message");
    	return p;
    }
}
