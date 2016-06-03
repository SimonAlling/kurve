"use strict";

class RangePreference extends Preference {
	constructor(data) {
		if (!isNumber(data.min) || !isNumber(data.max)) {
			throw new TypeError(`min and max must be numbers (found ${data.min} and ${data.max} for preference '${data.key}').`);
		} else if (data.min > data.max) {
			throw new TypeError(`min cannot be greater than max (found ${data.min} and ${data.max} for preference '${data.key}', respectively).`);
		}
		super(data);
		this.min = data.min;
		this.max = data.max;
		if (!this.isValidValue(data.default)) {
			super.invalidValue(data.default)
		}
	}

	isValidValue(value) {
		return isNumber(value) && value >= this.min && value <= this.max;
	}

	static stringify(value) {
		return value.toString();
	}

	static parse(stringifiedValue) {
		return parseFloat(stringifiedValue);
	}
}
