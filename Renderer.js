"use strict";

function Renderer(cfg, canvas) {

    const config = cfg;
    const context = canvas.getContext("2d");

    function drawSquare(left, top, color, size) {
        context.fillStyle = color;
        context.fillRect(left, top, size, size);
    }

    function clearSquare(left, top, size) {
        context.clearRect(left, top, size, size);
    }

    function clearRect(left, top, width, height) {
        context.clearRect(left, top, width, height);
    }

    return {
        drawSquare,
        clearSquare,
        clearRect
    };

}
