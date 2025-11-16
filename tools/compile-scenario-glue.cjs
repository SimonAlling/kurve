const { Elm } = require("./ScenarioInOriginalGame/ScenarioAPI.js");


try {
    const app = Elm.ScenarioAPI.init({
        flags: { elmFlag_commandLineArgs: process.argv.slice(2) },
    });

    app.ports.outputToOutsideWorld.subscribe((outputFromElm) => {
        console.log(outputFromElm);
        process.exit(0);
    });
} catch (caught) {
    console.error("Elm initialization failed.");
    console.error(String(caught));
    process.exit(1);
}
