module Drawing exposing (RenderAction(..), WhatToDraw, draw, drawSpawnIfAndOnlyIf, drawSpawnsPermanently, mergeRenderAction, nothingToDraw)

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


mergeRenderAction : RenderAction -> RenderAction -> RenderAction
mergeRenderAction actionFirst actionThen =
    case ( actionFirst, actionThen ) of
        ( LeaveAsIs, LeaveAsIs ) ->
            LeaveAsIs

        ( LeaveAsIs, Draw whatToDraw ) ->
            Draw whatToDraw

        ( Draw whatToDraw, LeaveAsIs ) ->
            Draw whatToDraw

        ( Draw whatFirst, Draw whatThen ) ->
            Draw <| mergeWhatToDraw whatFirst whatThen


mergeWhatToDraw : WhatToDraw -> WhatToDraw -> WhatToDraw
mergeWhatToDraw whatFirst whatThen =
    { headDrawing = whatThen.headDrawing
    , bodyDrawing = whatFirst.bodyDrawing ++ whatThen.bodyDrawing
    }


drawSpawnsPermanently : List Kurve -> RenderAction
drawSpawnsPermanently kurves =
    Draw
        { headDrawing = []
        , bodyDrawing =
            kurves
                |> List.map
                    (\kurve ->
                        ( kurve.color, World.drawingPosition kurve.state.position )
                    )
        }


drawSpawnIfAndOnlyIf : Bool -> Kurve -> List Kurve -> RenderAction
drawSpawnIfAndOnlyIf shouldBeVisible kurve alreadySpawnedKurves =
    if shouldBeVisible then
        Draw { headDrawing = kurve :: alreadySpawnedKurves, bodyDrawing = [] }

    else
        Draw { headDrawing = alreadySpawnedKurves, bodyDrawing = [] }
