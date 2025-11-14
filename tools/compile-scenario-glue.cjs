const { Elm } = require("./ScenarioInOriginalGame/ScenarioCLI.js");

const baseAddress = process.argv[2];

if (baseAddress === undefined) {
    console.error("Must specify base address.");
    process.exit(1);
}

try {
    const app = Elm.ScenarioCLI.init({
        flags: { elmFlag_baseAddress: baseAddress },
    });

    app.ports.outputToOutsideWorld.subscribe((outputFromElm) => {
        console.log(JSON.stringify(outputFromElm));
        process.exit(0);
    });
} catch (caught) {
    console.error("Elm initialization failed.");
    console.error(String(caught));
    process.exit(1);
}
