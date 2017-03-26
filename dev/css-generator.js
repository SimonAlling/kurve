function cssForScale(scale, debug) {
    const defaultWidth = 640;
    const defaultHeight = 480;
    const leftWidth = 80;
    const scaleSupportsPixelmapping = scale % 1 === 0;
    const SUFFIX = scaleSupportsPixelmapping ? ".body" : ".blurry"; // The body class is necessary for equal specificity.
    const SELECTOR_BODY = `body${SUFFIX}`;
    const SELECTOR_BODY_ZATACKA = `body#ZATACKA${SUFFIX}`;
    const CSS_IMAGE_RENDERING =
        scaleSupportsPixelmapping
        ? `
        image-rendering: -moz-crisp-edges;
        image-rendering: pixelated;`
        : `
        image-rendering: auto;`;

    return `/* ======== ${scale}x ======== ${!scaleSupportsPixelmapping ? "(only used if pixelmapping is not enforced) " : ""}*/
@media screen and (min-width: ${scale*defaultWidth}px) and (min-height: ${scale*defaultHeight}px) {
    ${SELECTOR_BODY_ZATACKA} { justify-content: flex-end; }` + (debug ? `
    ${SELECTOR_BODY_ZATACKA}::before { content: "${scale}"; font-size: 32px; position: fixed; top: 0; left: 0; }` : "") + `
    ${SELECTOR_BODY_ZATACKA} { transform-origin: right; }
    ${SELECTOR_BODY} #wrapper {
        zoom: ${scale};
        -moz-transform: scale(${scale});
    }
    ${SELECTOR_BODY} * {${CSS_IMAGE_RENDERING}
    }
}

@media screen and (min-width: ${scale*(defaultWidth+leftWidth)}px) and (min-height: ${scale*defaultHeight}px) {
    ${SELECTOR_BODY_ZATACKA} { justify-content: center; }
    ${SELECTOR_BODY_ZATACKA} #wrapper { transform-origin: center; }
}


`;
}

function generateCSS(maxScaling, debug) {
    const FRACTION_SCALES = [1.25, 1.5, 1.75, 2.5];
    const defaultMaxScaling = 8;
    const safeMaxScaling = maxScaling || defaultMaxScaling;

    let scales = FRACTION_SCALES.slice();
    for (let i = 1; i <= safeMaxScaling; i++) {
        scales.push(i);
    }
    scales.sort();

    let css = "";
    scales.forEach((scale) => {
        css += cssForScale(scale, debug);
    });

    return css;
}
