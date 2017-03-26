// Hide the JavaScript error message:
(function() {
    "use strict";
    document.querySelector("#fatalError_JS").remove();
})();

// Hide the UA error message if browser passes support check:
(function() {
    "use strict";
    function userAgentSupportsFlex() {
        return document.body.style.flex !== undefined;
    }

    function userAgentSupportsPixelMapping() {
        return document.body.style.imageRendering !== undefined
    }

    if (Object.freeze && userAgentSupportsFlex() && userAgentSupportsPixelMapping()) {
        document.querySelector("#fatalError_UA").remove();
    }
})();
