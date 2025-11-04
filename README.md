# Achtung, die Kurve! in Elm

The classic MS-DOS game *Achtung, die Kurve!* from 1995 in the browser!

## Play

* **Online:** Go to [kurve.se](http://kurve.se) (legacy JavaScript version) or [kurve.se/elm](http://kurve.se/elm) (Elm version).
* **Locally:** [Download the game](/SimonAlling/kurve/archive/master.zip) (legacy JavaScript version) and open `ZATACKA.html` in your browser.

Fullscreen is recommended for the best experience.

## Contribute

```shell
npm ci
npm start
```

Then visit <http://localhost:8000> in your browser.

The original MS-DOS game (whose author I haven't been able to determine; see #136) is included for reference.
To launch it, install [DOSBox](https://www.dosbox.com) and then run `dosbox docs/original-game/ZATACKA.EXE`.
