"use strict";

const typeOf = ((global) => {
    return function(obj) {
        if (obj === global) {
            return "global";
        }
        return ({}).toString.call(obj).match(/\s([a-z|A-Z]+)/)[1].toLowerCase();
    };
})(this);

const KEY = Object.freeze({ BACKSPACE: 8, TAB: 9, ENTER: 13, SHIFT: 16, CTRL: 17, ALT: 18, PAUSE: 19, CAPS_LOCK: 20, ESCAPE: 27, SPACE: 32, PAGE_UP: 33, PAGE_DOWN: 34, END: 35, HOME: 36, LEFT_ARROW: 37, UP_ARROW: 38, RIGHT_ARROW: 39, DOWN_ARROW: 40, INSERT: 45, DELETE: 46, "0": 48, "1": 49, "2": 50, "3": 51, "4": 52, "5": 53, "6": 54, "7": 55, "8": 56, "9": 57, A: 65, B: 66, C: 67, D: 68, E: 69, F: 70, G: 71, H: 72, I: 73, J: 74, K: 75, L: 76, M: 77, N: 78, O: 79, P: 80, Q: 81, R: 82, S: 83, T: 84, U: 85, V: 86, W: 87, X: 88, Y: 89, Z: 90, LEFT_META: 91, RIGHT_META: 92, SELECT: 93, NUMPAD_0: 96, NUMPAD_1: 97, NUMPAD_2: 98, NUMPAD_3: 99, NUMPAD_4: 100, NUMPAD_5: 101, NUMPAD_6: 102, NUMPAD_7: 103, NUMPAD_8: 104, NUMPAD_9: 105, MULTIPLY: 106, ADD: 107, SUBTRACT: 109, DECIMAL: 110, DIVIDE: 111, F1: 112, F2: 113, F3: 114, F4: 115, F5: 116, F6: 117, F7: 118, F8: 119, F9: 120, F10: 121, F11: 122, F12: 123, NUM_LOCK: 144, SCROLL_LOCK: 145, SEMICOLON: 186, EQUALS: 187, COMMA: 188, DASH: 189, PERIOD: 190, FORWARD_SLASH: 191, GRAVE_ACCENT: 192, OPEN_BRACKET: 219, BACK_SLASH: 220, CLOSE_BRACKET: 221, SINGLE_QUOTE: 222 });

const MOUSE = Object.freeze((() => {
    const offset = 1000;
    return Object.freeze({
        unpack: (offseted) => offseted - offset,
        pack:   (standard) => standard + offset,
        LEFT:   offset+0,
        RIGHT:  offset+2,
        MIDDLE: offset+1,
        MOUSE4: offset+3,
        MOUSE5: offset+4
    });
})());

const F_KEYS = Object.freeze([
    KEY.F1, KEY.F2, KEY.F3, KEY.F4, KEY.F5, KEY.F6, KEY.F7, KEY.F8, KEY.F9, KEY.F10, KEY.F11, KEY.F12
]);

const MOUSE_BUTTONS = Object.freeze([
    MOUSE.LEFT, MOUSE.RIGHT, MOUSE.MIDDLE, MOUSE.MOUSE4, MOUSE.MOUSE5
]);

function isObject(obj) {
    return typeOf(obj) === "object";
}

function isNumber(n) {
    return typeOf(n) === "number";
}

function isPositiveNumber(n) {
    return isNumber(n) && n > 0;
}

function isInt(n) {
    return isNumber(n) && n % 1 === 0;
}

function isPositiveInt(n) {
    return isInt(n) && n > 0;
}

function isString(s) {
    return typeOf(s) === "string";
}

function isNonEmptyString(s) {
    return isString(s) && s.length > 0;
}

function arePositiveNumbers(numbers) {
    return numbers.every(isPositiveNumber);
}

function round(number, decimals) {
    return Math.round(number * (Math.pow(10, decimals))) / (Math.pow(10, decimals));
}

function sameAbs(a, b) {
    return Math.abs(a) === Math.abs(b);
}

/**
 * Generates a random float between min (inclusive) and max (exclusive).
 *
 * @param {Number} min
 *   Minimum value (inclusive).
 * @param {Number} max
 *   Maximum value (exclusive).
 */
function randomFloat(min, max) {
    return Math.random() * (max - min) + min;
}

function normalizeAngle(a) {
    const pi = Math.PI;
    let angle = a % (2*pi);
    angle = (angle + 2*pi) % (2*pi);
    if (angle > pi) {
        angle = angle - 2*pi;
    }
    return angle;
}

function radToDeg(radians) {
    return (180/Math.PI) * radians;
}

function distanceToDuration(distance, velocity) {
    return (distance / velocity) * 1000; // milliseconds
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

function byID(id) {
    return document.getElementById(id);
}

function isHTMLElement(elem) {
    return elem instanceof HTMLElement;
}

function flush(node) {
    if (isHTMLElement(node)) {
        node.textContent = "";
    } else {
        throw new TypeError(`${node} is not a DOM node.`);
    }
}

function forfor(y_start, y_end, x_start, x_end, func, arg) {
    for (let y = y_start; y < y_end; y++) {
        for (let x = x_start; x < x_end; x++) {
            func.call(this, x, y, arg);
        }
    }
}

const Keyboard = {
    pressed: {},
    isDown: function(keyCode) {
        return !!this.pressed[keyCode];
    },
    onKeydown: function(event) {
        this.pressed[event.keyCode] = true;
    },
    onKeyup: function(event) {
        delete this.pressed[event.keyCode];
    }
};

const Mouse = {
    pressed: {},
    isDown: function(mouseButtonNumber) {
        return this.pressed[mouseButtonNumber];
    },
    onMousedown: function(event) {
        this.pressed[event.button] = true;
    },
    onMouseup: function(event) {
        delete this.pressed[event.button];
    }
};

function anyKeyBeingPressed(keyCodes) {
    return Array.isArray(keyCodes) && keyCodes.some(Keyboard.isDown, Keyboard);
}

function anyMouseButtonBeingPressed(mouseButtons) {
    return Array.isArray(mouseButtons) && mouseButtons.map(MOUSE.unpack).some(Mouse.isDown, Mouse);
}

function anyInputBeingPressed(keysOrMouseButtons) {
    return anyKeyBeingPressed(keysOrMouseButtons) || anyMouseButtonBeingPressed(keysOrMouseButtons);
}

function isMouseButton(button) {
    return isPositiveInt(button) && Object.keys(MOUSE).some((buttonName) => MOUSE.hasOwnProperty(buttonName));
}

function isKeyList(keys) {
    return Array.isArray(keys)
        && keys.length > 0
        && keys.every(isPositiveInt); 
}

function isFKey(key) {
    return F_KEYS.includes(key);
}

const PLATFORM = (() => {
    const strings = {
        os_id_windows: "Win",
        os_id_mac: "Mac",
        os_id_linux: "Linux",
        os_id_unix: "X11",

        os_name_windows: "Windows",
        os_name_mac: "Mac",
        os_name_linux: "Linux",
        os_name_unix: "UNIX",
        os_name_unknown: "Unknown",
    };

    return {
        getOS: () => {
            const ua = window.navigator.userAgent || window.navigator.appVersion;
            if (isNonEmptyString(ua)) {
                if (ua.indexOf(strings.os_id_windows) > -1) { return strings.os_name_windows; }
                if (ua.indexOf(strings.os_id_mac)     > -1) { return strings.os_name_mac;     }
                if (ua.indexOf(strings.os_id_linux)   > -1) { return strings.os_name_linux;   }
                if (ua.indexOf(strings.os_id_unix)    > -1) { return strings.os_name_unix;    }
            }
            return strings.os_name_unknown;
        },
        getFullscreenShortcut: () => {
            switch (PLATFORM.getOS()) {
                case strings.os_name_mac:
                    return TEXT.keyboard_fullscreen_mac;
                    break;
                default:
                    return TEXT.keyboard_fullscreen_standard;
            }
        },
    };
})();
