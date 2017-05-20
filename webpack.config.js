const path = require("path");
const DIR_SOURCE = "/src";
const DIR_COMPILED = "/js";

module.exports = {
    devtool: "source-map",
    entry: {
        zatacka: `.${DIR_SOURCE}/js/Main.js`,
        splashscreen: `.${DIR_SOURCE}/js/SplashScreen.js`,
    },
    output: {
        path: path.resolve(__dirname, `.${DIR_COMPILED}`),
        publicPath: DIR_COMPILED,
        filename: "[name].min.js",
    },
    module: {
        loaders: [
            {
                loader: "babel-loader",
                // Skip any files outside of your project"s source directory:
                include: [
                    path.resolve(__dirname, `./${DIR_SOURCE}`),
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
