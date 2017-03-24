const typeOf = ((global) => {
    return function(obj) {
        if (obj === global) {
            return "global";
        }
        return ({}).toString.call(obj).match(/\s([a-z|A-Z]+)/)[1].toLowerCase();
    };
})(this);

export function isObject(obj) {
    return typeOf(obj) === "object";
}

export function isNumber(n) {
    return typeOf(n) === "number";
}

export function isPositiveNumber(n) {
    return isNumber(n) && n > 0;
}

export function isInt(n) {
    return isNumber(n) && n % 1 === 0;
}

export function isPositiveInt(n) {
    return isInt(n) && n > 0;
}

export function isString(s) {
    return typeOf(s) === "string";
}

export function isNonEmptyString(s) {
    return isString(s) && s.length > 0;
}

export function arePositiveNumbers(numbers) {
    return numbers.every(isPositiveNumber);
}

export function round(number, decimals) {
    return Math.round(number * (Math.pow(10, decimals))) / (Math.pow(10, decimals));
}
