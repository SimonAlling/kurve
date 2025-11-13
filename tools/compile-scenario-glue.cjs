const { Elm } = require("./ScenarioInOriginalGame/ScenarioCLI.js");

const baseAddress = process.argv[2];

if (baseAddress === undefined) {
    console.error("Must specify base address.");
    process.exit(1);
}

const app = Elm.ScenarioCLI.init({
    flags: { baseAddress },
});

app.ports.outputToOutsideWorld.subscribe((outputFromElm) => {
    console.log(JSON.stringify(outputFromElm));
    process.exit(0);
});
