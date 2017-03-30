const path = require("path");
const DIR_SOURCE = "js";

module.exports = {
    devtool: "source-map",
    entry: {
        zatacka: "./" + DIR_SOURCE + "/Main.js",
        splashscreen: "./" + DIR_SOURCE + "/SplashScreen.js",
    },
    output: {
        path: path.resolve(__dirname, "."),
        filename: "[name].min.js"
    },
    module: {
        loaders: [
            {
                loader: "babel-loader",
                // Skip any files outside of your project"s source directory:
                include: [
                    path.resolve(__dirname, DIR_SOURCE),
                ],
                // Only run `.js` files through Babel:
                test: /\.js$/,
                // Options to configure babel with:
                query: {
                    presets: ["es2015"],
                }
            },
        ]
    }
};
