function generateCSS(maxScaling) {
	const defaultWidth = 640;
	const defaultHeight = 480;
	const leftWidth = 80;
	const defaultMaxScaling = 8;
	const safeMaxScaling = maxScaling || defaultMaxScaling;

	let css = "";
	for (let i = 1; i <= safeMaxScaling; i++) {
		css += `/* ======== ${i}x ======== */
@media screen and (min-width: ${i*defaultWidth}px) and (min-height: ${i*defaultHeight}px) {
    body#ZATACKA { justify-content: flex-end; }
    #wrapper {
        zoom: ${i};
        -moz-transform: scale(${i});
        transform-origin: right;
    }
}

@media screen and (min-width: ${i*(defaultWidth+leftWidth)}px) and (min-height: ${i*defaultHeight}px) {
    body#ZATACKA { justify-content: center; }
    #wrapper {
        transform-origin: center;
    }
}


`;
	}

	return css;
}