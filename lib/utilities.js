Object.typeOf = (function typeOf(global) {
    return function(obj) {
        if (obj === global) {
            return "global";
        }
        return ({}).toString.call(obj).match(/\s([a-z|A-Z]+)/)[1].toLowerCase();
    };
})(this);

function isInt(n) {
    return Object.typeOf(n) === 'number' && n % 1 === 0;
}

function log(str) {
    console.log("Zatacka: " + str);
}

function logWarning(str) {
    console.warn("Zatacka: " + str);
}

function logError(str) {
    console.error("Zatacka: " + str);
}
