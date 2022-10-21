# Achtung, die Kurve! in JavaScript

The aim of this project is to create an HTML5/JS remake of the original *Achtung, die Kurve!* from 1995.


## Play

* **Online:**  Go to [kurve.se](http://kurve.se).
* **Locally:** [Download the game](/SimonAlling/kurve/archive/master.zip) and open `ZATACKA.html` in your browser.

The game will automatically scale itself up as much as possible; fullscreen is recommended for the best experience.


## Contribute

### Preparations

To install the necessary software, first install [Node](https://nodejs.org) and then run

    npm install

in the root directory of this repo. This will install all the Node packages you need.



### Build

To build, run

    npm run build

in the root of this repo.

To run a development server:

    npm run watch

The difference is that `build` will write compiled JS files to disk, and you can see your changes simply by opening `ZATACKA.html` or `index.html`.

`watch`, on the other hand, does not write to disk, and you must visit `localhost:8080` in your browser to see your changes. The advantage is that everything (both JS and CSS) is recompiled automatically when a file is modified.



### Code structure

All JavaScript source files can be found in `src/js/`; SASS in `src/css/`.

`js/` (in the root) contains _compiled_ JS.

The main JS file is `Main.js`. It is responsible for creating a `Game` and supplying a config, a `Renderer` and a `GUIController` to it. It also adds `Player`s to the `Game` and forwards key events to it.

`Game.js` controls the game logic. It knows which `Player`s are in the game and handles their interaction with eachother and the playing field, and it controls progress throughout the individual rounds. The `Game` constructor must be passed a config object, a `Renderer`, and a `GUIController`.

`Player.js` describes a single player. It knows whether it is alive, where it is, where and how fast it is going, its score, and what `Game` it is attached to.

`Renderer.js` does all the drawing on the actual playing field. `Game.js` does not draw anything; it just calls upon its `Renderer` to do that.

`GUIController.js` controls the scoreboard and additional GUI features, such as hiding the lobby and showing the results when the game ends. When a player's score is changed, the `Game` will tell its `GUIController` to update the scoreboard entry of that player.

`src/js/lib/` contains **general libraries** and help functions.

`dev/` may only contain **development tools** that are not needed at runtime, such as test suites or code generators.
