// Show the UA error message if browser fails support check:
(function() {
    "use strict";
    function userAgentSupportsFlex() {
        return document.body.style.flex !== undefined;
    }

    function userAgentSupportsPixelMapping() {
        return document.body.style.imageRendering !== undefined
    }

    function userAgentIsSupported() {
        return Object.freeze && userAgentSupportsFlex() && userAgentSupportsPixelMapping();
    }

    if (!userAgentIsSupported()) {
        document.getElementById("fatalError_UA").style.display = "table";
    }
})();
