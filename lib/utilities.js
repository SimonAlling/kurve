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

function round(number, decimals) {
    return Math.round(number * (Math.pow(10, decimals))) / (Math.pow(10, decimals));
}

function normalizeAngle(a) {
	var pi = Math.PI;
	var angle = a % (2*pi);
	angle = (angle + 2*pi) % (2*pi);
	if (angle > pi) {
		angle -= 2*pi;
	}
	return angle;
}

function radToDeg(r) {
	return (180/Math.PI) * r;
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
