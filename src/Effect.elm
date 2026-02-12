module Effect exposing (Effect(..), maybeDrawSomething)

import Drawing exposing (WhatToDraw)
import Settings exposing (Settings)


type Effect
    = DrawSomething WhatToDraw
    | ClearAndThenDraw WhatToDraw
    | ClearEverything
    | ToggleFullscreen
    | SaveSettings Settings
    | DoNothing


maybeDrawSomething : Maybe WhatToDraw -> Effect
maybeDrawSomething maybeWhatToDraw =
    case maybeWhatToDraw of
        Nothing ->
            DoNothing

        Just whatToDraw ->
            DrawSomething whatToDraw
