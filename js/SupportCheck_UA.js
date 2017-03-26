"use strict";

// Hide UA error message if browser passes support check:
(function() {
    var dummyElement = document.createElement("div");

    function userAgentSupportsFlex() {
        return dummyElement.style.flex !== undefined;
    }

    function userAgentSupportsPixelMapping() {
        return dummyElement.style.imageRendering !== undefined
    }

    if (Object.freeze && userAgentSupportsFlex() && userAgentSupportsPixelMapping()) {
        document.querySelector("#fatalError_UA").remove();
    }
})();
