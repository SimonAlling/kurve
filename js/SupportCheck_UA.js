"use strict";

// Hide UA error message if browser passes support check:
(function() {
    var dummyElement = document.createElement("div");
    if (
            Object.freeze &&
            dummyElement.style.flex !== undefined &&
            dummyElement.style.imageRendering !== undefined
        ) {
        var css = "#fatalError_UA { display: none; }";
        var styleElement = document.createElement("style");
        styleElement.textContent = css;
        document.head.appendChild(styleElement);
    }
})();
