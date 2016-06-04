// This needs to be in its own file; otherwise, browsers without ES6 support may
// fail to hide the JS enabled error message.

// Hide ES6 error message if browser passes ES6 support check:
((x = `x`, y = `${x}`) => {
	let a = "a";
	const b = "b";
	if (
			y === x &&
			Object.freeze &&
			Array.prototype.map &&
			Array.prototype.some &&
			Array.prototype.find &&
			Array.prototype.forEach
		) {
		const css = "#fatalError_ES6 { display: none; }";
		const styleElement = document.createElement("style");
		styleElement.textContent = css;
		document.head.appendChild(styleElement);
	}
})();
