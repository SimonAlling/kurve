"use strict";

function Renderer(mainCanvas, overlayCanvas) {

    const context_main = mainCanvas.getContext("2d");
    const context_overlay = overlayCanvas.getContext("2d");


    // PRIVATE FUNCTIONS:

    function _drawRectangle(context, left, top, width, height, color) {
        context.fillStyle = color;
        context.fillRect(left, top, width, height);
    }

    function _clearRectangle(context, left, top, width, height) {
        context.clearRect(left, top, width, height);
    }

    function _setSize(canvas, width, height) {
        canvas.width = width;
        canvas.height = height;
    }


    // PUBLIC API:

    function setSize(width, height) {
        _setSize(mainCanvas   , width, height);
        _setSize(overlayCanvas, width, height);
    }

    // Main canvas:

    function drawSquare(left, top, size, color) {
        _drawRectangle(context_main, left, top, size, size, color);
    }

    function clearSquare(left, top, size) {
        _clearRectangle(context_main, left, top, size, size);
    }

    function clearRectangle(left, top, width, height) {
        _clearRectangle(context_main, left, top, width, height);
    }

    // Overlay canvas:

    function drawSquare_overlay(left, top, size, color) {
        _drawRectangle(context_overlay, left, top, size, size, color);
    }

    function clearSquare_overlay(left, top, size) {
        _clearRectangle(context_overlay, left, top, size, size);
    }

    function clearRectangle_overlay(left, top, width, height) {
        _clearRectangle(context_overlay, left, top, width, height);
    }

    return {
        drawSquare,
        clearSquare,
        clearRectangle,
        drawSquare_overlay,
        clearSquare_overlay,
        clearRectangle_overlay,
        setSize
    };

}
