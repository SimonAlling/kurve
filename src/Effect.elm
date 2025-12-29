module Effect exposing (Effect(..))

import Drawing exposing (WhatToDraw)


type Effect
    = DrawSomething WhatToDraw
    | ClearEverything
    | DoNothing
