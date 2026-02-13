module Drawing exposing (DrawingAccumulator, WhatToDraw, accumulate, drawSpawnsPermanently, drawSpawnsTemporarily, finalize, getColorAndDrawingPosition, initialize, mergeWhatToDraw)

import Color exposing (Color)
import Types.Kurve exposing (Kurve, isSolid)
import World exposing (DrawingPosition)


type alias WhatToDraw =
    { headDrawing : List ( Color, DrawingPosition )
    , bodyDrawing : List ( Color, DrawingPosition )
    }


{-| Used to efficiently accumulate what to draw, even in extremely long frames (such as when fast-forwarding/rewinding a replay).
-}
type DrawingAccumulator
    = Empty
    | Accum
        { headDrawing : List ( Color, DrawingPosition )
        , reversedBodyDrawings : List (List ( Color, DrawingPosition ))
        }


initialize : DrawingAccumulator
initialize =
    Empty


accumulate : DrawingAccumulator -> WhatToDraw -> DrawingAccumulator
accumulate acc new =
    Accum
        { headDrawing = new.headDrawing
        , reversedBodyDrawings =
            case acc of
                Empty ->
                    [ new.bodyDrawing ]

                Accum accumulated ->
                    new.bodyDrawing :: accumulated.reversedBodyDrawings
        }


finalize : DrawingAccumulator -> Maybe WhatToDraw
finalize acc =
    case acc of
        Empty ->
            Nothing

        Accum accumulated ->
            Just
                { headDrawing = accumulated.headDrawing
                , bodyDrawing = accumulated.reversedBodyDrawings |> List.reverse |> List.concat
                }


mergeWhatToDraw : WhatToDraw -> WhatToDraw -> WhatToDraw
mergeWhatToDraw whatFirst whatThen =
    { headDrawing = whatThen.headDrawing
    , bodyDrawing = whatFirst.bodyDrawing ++ whatThen.bodyDrawing
    }


drawSpawnsPermanently : List Kurve -> WhatToDraw
drawSpawnsPermanently kurves =
    { headDrawing = []
    , bodyDrawing = kurves |> List.filter isSolid |> List.map getColorAndDrawingPosition
    }


drawSpawnsTemporarily : List Kurve -> WhatToDraw
drawSpawnsTemporarily kurves =
    { headDrawing = kurves |> List.map getColorAndDrawingPosition
    , bodyDrawing = []
    }


getColorAndDrawingPosition : Kurve -> ( Color, DrawingPosition )
getColorAndDrawingPosition kurve =
    ( kurve.color, World.drawingPosition kurve.state.position )
