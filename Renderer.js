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

    return {
        drawSquare,
        clearSquare
    };

}
