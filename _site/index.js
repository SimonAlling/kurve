"use strict";

const app = Elm.Main.init({ node: document.getElementById("elm-node") });

function drawSquare(canvas, { position: { x, y }, thickness, color }) {
    const context = canvas.getContext("2d");
    context.fillStyle = color;
    context.fillRect(x, y, thickness, thickness);
}

function clearRectangleIfCanvasExists(canvas, { x, y, width, height }) {
    const context = canvas?.getContext("2d");
    context?.clearRect(x, y, width, height);
}

app.ports.renderMain.subscribe(({ clearFirst, squares }) => {
    const canvas_main = document.getElementById("canvas_main");
    if (clearFirst) {
        clearRectangleIfCanvasExists(canvas_main, { x: 0, y: 0, width: canvas_main?.width, height: canvas_main?.height });
    }
    for (const square of squares) {
        drawSquare(canvas_main, square);
    }
});

app.ports.clearMain.subscribe(() => {
    const canvas_main = document.getElementById("canvas_main");
    clearRectangleIfCanvasExists(canvas_main, { x: 0, y: 0, width: canvas_main?.width, height: canvas_main?.height });
});

app.ports.renderOverlay.subscribe(squares => {
    const canvas_overlay = document.getElementById("canvas_overlay");
    clearRectangleIfCanvasExists(canvas_overlay, { x: 0, y: 0, width: canvas_overlay?.width, height: canvas_overlay?.height }); // Very large numbers don't work; see the commit that added this comment.
    for (const square of squares) {
        drawSquare(canvas_overlay, square);
    }
});

document.addEventListener("keydown", event => {
    const isDeveloperCommand = (
        ["F5", "F12"].includes(event.key)
        ||
        (event.ctrlKey && event.key === "r") // Ctrl + R
        ||
        (event.metaKey && event.key === "r") // Cmd + R on macOS 👀
    );
    if (!isDeveloperCommand) {
        event.preventDefault();
    }
    if (!event.repeat) {
        app.ports.onKeydown.send(event.code);
    }
});
document.addEventListener("keyup", event => {
    // Traditionally we never prevented default on keyup.
    app.ports.onKeyup.send(event.code);
});
document.addEventListener("mousedown", event => {
    app.ports.onMousedown.send(event.button);
});
document.addEventListener("mouseup", event => {
    app.ports.onMouseup.send(event.button);
});
document.addEventListener("contextmenu", event => {
    event.preventDefault();
});
window.addEventListener("blur", () => {
    app.ports.focusLost.send(null);
});
