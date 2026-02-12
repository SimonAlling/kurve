"use strict";

customElements.define(
  "window-events-workaround",
  class extends HTMLElement {
    addEventListener(...args) {
      return window.addEventListener(...args);
    }

    removeEventListener(...args) {
      return window.removeEventListener(...args);
    }
  },
);

const THE_SETTINGS_KEY = "zatacka_settings";

const flags = {
    initialSeedValue: Math.floor(Math.random() * 0x100000000),
    settingsJsonFromLocalStorage: window.localStorage.getItem(THE_SETTINGS_KEY),
};

const app = Elm.Main.init({ node: document.getElementById("elm-node"), flags: flags });

function drawSquare(canvas, { position: { x, y }, thickness, color }) {
    const context = canvas.getContext("2d");
    context.fillStyle = color;
    context.fillRect(x, y, thickness, thickness);
}

function clearRectangleIfCanvasExists(canvas, { x, y, width, height }) {
    const context = canvas?.getContext("2d");
    context?.clearRect(x, y, width, height);
}

app.ports.renderBodies.subscribe(({ clearFirst, squares }) => {
    const bodyCanvas = document.getElementById("bodyCanvas");
    if (clearFirst) {
        clearRectangleIfCanvasExists(bodyCanvas, { x: 0, y: 0, width: bodyCanvas?.width, height: bodyCanvas?.height });
    }
    for (const square of squares) {
        drawSquare(bodyCanvas, square);
    }
});

app.ports.clearBodies.subscribe(() => {
    const bodyCanvas = document.getElementById("bodyCanvas");
    clearRectangleIfCanvasExists(bodyCanvas, { x: 0, y: 0, width: bodyCanvas?.width, height: bodyCanvas?.height });
});

app.ports.renderHeads.subscribe(squares => {
    const headCanvas = document.getElementById("headCanvas");
    clearRectangleIfCanvasExists(headCanvas, { x: 0, y: 0, width: headCanvas?.width, height: headCanvas?.height }); // Very large numbers don't work; see the commit that added this comment.
    for (const square of squares) {
        drawSquare(headCanvas, square);
    }
});

app.ports.toggleFullscreen.subscribe(toggleFullscreen);

app.ports.saveToLocalStorage.subscribe(saveToLocalStorage);

document.addEventListener("contextmenu", event => {
    event.preventDefault();
});
window.addEventListener("blur", () => {
    app.ports.focusLost.send(null);
});

window.addEventListener(
    "mousedown",
    (event) => {
        if (event.target.closest(".stop-propagation-on-mousedown") !== null) {
            event.stopPropagation();
        }
    },
    true,
);

window.addEventListener("beforeunload", event => {
    if (shouldPreventUnload()) {
        event.preventDefault();
    }
});

function toggleFullscreen() {
    if (document.fullscreenElement !== null) {
        document.exitFullscreen();
        return;
    }

    document.documentElement.requestFullscreen().catch((err) => {
        console.error(`Error enabling fullscreen: ${err.message}`);
    });
}

function saveToLocalStorage(jsonString) {
    window.localStorage.setItem(THE_SETTINGS_KEY, jsonString);
}

function shouldPreventUnload() {
    return document.getElementsByClassName("magic-class-name-to-prevent-unload").length > 0;
}
