"use strict";

customElements.define(
  "window-events-workaround",
  class extends HTMLElement {
    override addEventListener(...args: Parameters<HTMLElement["addEventListener"]>) {
      return window.addEventListener(...args);
    }

    override removeEventListener(...args: Parameters<HTMLElement["removeEventListener"]>) {
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

function drawSquare(canvas: HTMLCanvasElement, { position: { x, y }, thickness, color }: { position: { x: number; y: number }; thickness: number; color: string }) {
    const context = canvas.getContext("2d");
    context.fillStyle = color;
    context.fillRect(x, y, thickness, thickness);
}

function clearRectangleIfCanvasExists(canvas: HTMLCanvasElement | null, { x, y, width, height }: { x: number, y: number, width: number, height: number }) {
    const context = canvas?.getContext("2d");
    context?.clearRect(x, y, width, height);
}

app.ports.renderBodies.subscribe(async ({ clearFirst, squares }) => {
    const bodyCanvas = document.getElementById("bodyCanvas") as HTMLCanvasElement | null;
    if (clearFirst) {
        clearRectangleIfCanvasExists(bodyCanvas, { x: 0, y: 0, width: bodyCanvas?.width, height: bodyCanvas?.height });
    }
    for (const square of squares) {
        drawSquare(bodyCanvas, square);
    }
});

app.ports.clearBodies.subscribe(async () => {
    const bodyCanvas = document.getElementById("bodyCanvas") as HTMLCanvasElement | null;
    clearRectangleIfCanvasExists(bodyCanvas, { x: 0, y: 0, width: bodyCanvas?.width, height: bodyCanvas?.height });
});

app.ports.renderHeads.subscribe(async squares => {
    const headCanvas = document.getElementById("headCanvas") as HTMLCanvasElement | null;
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
        if ((event.target as Element).closest(".stop-propagation-on-mousedown") !== null) {
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

async function toggleFullscreen() {
    if (document.fullscreenElement !== null) {
        document.exitFullscreen();
        return;
    }

    document.documentElement.requestFullscreen().catch((err) => {
        console.error(`Error enabling fullscreen: ${err.message}`);
    });
}

async function saveToLocalStorage(jsonString: string) {
    window.localStorage.setItem(THE_SETTINGS_KEY, jsonString);
}

function shouldPreventUnload() {
    return document.getElementsByClassName("magic-class-name-to-prevent-unload").length > 0;
}
