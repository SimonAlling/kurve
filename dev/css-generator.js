function cssForScale(scale, pixelRatio = 1, debug = false) {
    const defaultWidth = 640;
    const defaultHeight = 480;
    const leftWidth = 80;
    const HIDPI_SUFFIX_WDPR = `and (-webkit-device-pixel-ratio: ${pixelRatio})`;
    const HIDPI_SUFFIX_WRES = `and (-webkit-resolution: ${pixelRatio})`;
    const HIDPI_SUFFIX_RES  = `and (resolution: ${pixelRatio})`;
    const scaleSupportsPixelmapping = scale % 1 === 0;
    const SUFFIX = scaleSupportsPixelmapping ? ".body" : ".blurry"; // The body class is necessary for equal specificity.
    const SELECTOR_BODY = `body${SUFFIX}`;
    const SELECTOR_BODY_ZATACKA = `body#ZATACKA${SUFFIX}`;
    const MEDIA_QUERY_WIDTH_HEIGHT_LEFT = `(min-width: ${scale/pixelRatio * defaultWidth}px) and (min-height: ${scale/pixelRatio * defaultHeight}px) `;
    const MEDIA_QUERY_WIDTH_HEIGHT_CENTER = `(min-width: ${scale/pixelRatio * (defaultWidth+leftWidth)}px) and (min-height: ${scale/pixelRatio * defaultHeight}px) `;
    const MEDIA_QUERY_LEFT = pixelRatio === 1 ? MEDIA_QUERY_WIDTH_HEIGHT_LEFT : `
    ${MEDIA_QUERY_WIDTH_HEIGHT_CENTER}${HIDPI_SUFFIX_WDPR},
    ${MEDIA_QUERY_WIDTH_HEIGHT_CENTER}${HIDPI_SUFFIX_WRES},
    ${MEDIA_QUERY_WIDTH_HEIGHT_CENTER}${HIDPI_SUFFIX_RES}
`;
    const MEDIA_QUERY_CENTER = pixelRatio === 1 ? MEDIA_QUERY_WIDTH_HEIGHT_CENTER : `
    ${MEDIA_QUERY_WIDTH_HEIGHT_CENTER}${HIDPI_SUFFIX_WDPR},
    ${MEDIA_QUERY_WIDTH_HEIGHT_CENTER}${HIDPI_SUFFIX_WRES},
    ${MEDIA_QUERY_WIDTH_HEIGHT_CENTER}${HIDPI_SUFFIX_RES}
`;
    const CSS_IMAGE_RENDERING =
        scaleSupportsPixelmapping
        ? `
        image-rendering: -moz-crisp-edges;
        image-rendering: pixelated;`
        : `
        image-rendering: auto;`;

    return `/* ======== ${scale}x${pixelRatio === 1 ? "" : ` (${pixelRatio}dppx)`} ======== ${!scaleSupportsPixelmapping ? "(only used if pixelmapping is not enforced) " : ""}*/
@media ${MEDIA_QUERY_LEFT}{
    ${SELECTOR_BODY_ZATACKA} { justify-content: flex-end; }` + (debug ? `
    ${SELECTOR_BODY_ZATACKA}::before { content: "${scale}"; font-size: 32px; position: fixed; top: 0; left: 0; }` : "") + `
    ${SELECTOR_BODY_ZATACKA} { transform-origin: right; }
    ${SELECTOR_BODY} #wrapper {
        zoom: ${scale/pixelRatio};
        -moz-transform: scale(${scale/pixelRatio});
    }
    ${SELECTOR_BODY} * {${CSS_IMAGE_RENDERING}
    }
}

@media ${MEDIA_QUERY_CENTER}{
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
        css += cssForScale(scale, 1, debug) + cssForScale(scale, 2, debug);
    });

    return css;
}
