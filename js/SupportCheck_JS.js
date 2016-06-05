// Hide the JavaScript error message:
(function() {
    var css = "#fatalError_JS { display: none; }";
    var styleElement = document.createElement("style");
    styleElement.innerHTML = css;
    document.head.appendChild(styleElement);
})();



// Show the ES6 error message:
(function() {
    var css = "#fatalError_ES6 { display: table; }";
    var styleElement = document.createElement("style");
    styleElement.innerHTML = css;
    document.head.appendChild(styleElement);
})();
