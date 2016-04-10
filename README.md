# Achtung, die Kurve! in JavaScript

The aim of this project is to create an HTML5/JS remake of the original *Achtung, die Kurve!* from 1995.


## Play

Open `ZATACKA.html` in a browser to run the game. It will automatically scale itself up as much as possible; fullscreen is recommended for the best experience.


## Contribute

All JavaScript files can be found in `js/`.

The main JS file is `Zatacka.js`. It is responsible for creating a `Game` and supplying a config, a `Renderer` and a `GUIController` to it. It also adds `Player`s to the `Game` and forwards key events to it.

`Game.js` controls the game logic. It knows which `Player`s are in the game and handles their interaction with eachother and the playing field, and it controls progress throughout the individual rounds. The `Game` constructor must be passed a config object, a `Renderer`, and a `GUIController`.

`Player.js` describes a single player. It knows whether it is alive, where it is, where and how fast it is going, its score, and what `Game` it is attached to.

`Renderer.js` does all the drawing on the actual playing field. `Game.js` does not draw anything; it just calls upon its `Renderer` to do that.

`GUIController.js` controls the scoreboard and additional GUI features, such as hiding the lobby and showing the results when the game ends. When a player's score is changed, the `Game` will tell its `GUIController` to update the scoreboard entry of that player.

`js/lib/` contains **general libraries** and help functions.

`dev/` may only contain **development tools** that are not needed at runtime, such as test suites or code generators.
