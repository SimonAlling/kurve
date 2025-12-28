module Drawing exposing (RenderAction(..), WhatToDraw, draw, drawSpawnIfAndOnlyIf, drawSpawnsPermanently, mergeRenderActionAndWhatToDraw, nothingToDraw)

import Color exposing (Color)
import Types.Kurve exposing (Kurve)
import World exposing (DrawingPosition)


type RenderAction
    = LeaveAsIs
    | Draw WhatToDraw


type alias WhatToDraw =
    { headDrawing : List Kurve
    , bodyDrawing : List ( Color, DrawingPosition )
    }


draw : WhatToDraw -> RenderAction
draw =
    Draw


nothingToDraw : RenderAction
nothingToDraw =
    LeaveAsIs


mergeRenderActionAndWhatToDraw : RenderAction -> WhatToDraw -> WhatToDraw
mergeRenderActionAndWhatToDraw actionFirst whatToDrawThen =
    case ( actionFirst, whatToDrawThen ) of
        ( LeaveAsIs, whatToDraw ) ->
            whatToDraw

        ( Draw whatFirst, whatThen ) ->
            mergeWhatToDraw whatFirst whatThen


mergeWhatToDraw : WhatToDraw -> WhatToDraw -> WhatToDraw
mergeWhatToDraw whatFirst whatThen =
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
