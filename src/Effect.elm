module Effect exposing (Effect(..), maybeDrawSomething)

import Drawing exposing (WhatToDraw)


type Effect
    = DrawSomething WhatToDraw
    | ClearEverything
    | DoNothing


maybeDrawSomething : Maybe WhatToDraw -> Effect
maybeDrawSomething maybeWhatToDraw =
    case maybeWhatToDraw of
        Nothing ->
            DoNothing

        Just whatToDraw ->
            DrawSomething whatToDraw
