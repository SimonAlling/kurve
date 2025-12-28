module Drawing exposing (WhatToDraw, drawSpawnIfAndOnlyIf, drawSpawnsPermanently, mergeWhatToDraw)

import Color exposing (Color)
import Types.Kurve exposing (Kurve)
import World exposing (DrawingPosition)


type alias WhatToDraw =
    { headDrawing : List Kurve
    , bodyDrawing : List ( Color, DrawingPosition )
    }


mergeWhatToDraw : Maybe WhatToDraw -> WhatToDraw -> WhatToDraw
mergeWhatToDraw actionFirst whatToDrawThen =
    case ( actionFirst, whatToDrawThen ) of
        ( Nothing, whatToDraw ) ->
            whatToDraw

        ( Just whatFirst, whatThen ) ->
            { headDrawing = whatThen.headDrawing
            , bodyDrawing = whatFirst.bodyDrawing ++ whatThen.bodyDrawing
            }


drawSpawnsPermanently : List Kurve -> WhatToDraw
drawSpawnsPermanently kurves =
    { headDrawing = []
    , bodyDrawing =
        kurves
            |> List.map
                (\kurve ->
                    ( kurve.color, World.drawingPosition kurve.state.position )
                )
    }


drawSpawnIfAndOnlyIf : Bool -> Kurve -> List Kurve -> WhatToDraw
drawSpawnIfAndOnlyIf shouldBeVisible kurve alreadySpawnedKurves =
    if shouldBeVisible then
        { headDrawing = kurve :: alreadySpawnedKurves, bodyDrawing = [] }

    else
        { headDrawing = alreadySpawnedKurves, bodyDrawing = [] }
