function generateCSS() {
	const defaultWidth = 640;
	const defaultHeight = 480;
	const leftWidth = 80;
	const maxScaling = 5;

	let css = "";
	for (let i = 1; i < maxScaling; i++) {
		css += `/* ======== ${i}x ======== */
		@media screen and (min-width: ${i*defaultWidth}px) and (min-height: ${i*defaultHeight}px) {
		    body { justify-content: flex-end; }
		    #wrapper {
		        transform: scale(${i});
		        transform-origin: right;
		    }
		}

		@media screen and (min-width: ${i*(defaultWidth+leftWidth)}px) and (min-height: ${i*defaultHeight}px) {
		    body { justify-content: center; }
		    #wrapper {
		        transform-origin: center;
		    }
		}


		`;
	}

	return css;
}