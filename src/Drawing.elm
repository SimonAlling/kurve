module Drawing exposing (WhatToDraw, drawSpawnsPermanently, drawSpawnsTemporarily, getColorAndDrawingPosition, mergeWhatToDraw, mergeWhatToDraw_flipped)

import Color exposing (Color)
import Types.Kurve exposing (Kurve)
import World exposing (DrawingPosition)


type alias WhatToDraw =
    { headDrawing : List ( Color, DrawingPosition )
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


mergeWhatToDraw_flipped : WhatToDraw -> Maybe WhatToDraw -> WhatToDraw
mergeWhatToDraw_flipped whatToDrawFirst actionThen =
    case ( whatToDrawFirst, actionThen ) of
        ( whatToDraw, Nothing ) ->
            whatToDraw

        ( whatFirst, Just whatThen ) ->
            { headDrawing = whatThen.headDrawing
            , bodyDrawing = whatFirst.bodyDrawing ++ whatThen.bodyDrawing
            }


drawSpawnsPermanently : List Kurve -> WhatToDraw
drawSpawnsPermanently kurves =
    { headDrawing = []
    , bodyDrawing = kurves |> List.map getColorAndDrawingPosition
    }


drawSpawnsTemporarily : List Kurve -> WhatToDraw
drawSpawnsTemporarily kurves =
    { headDrawing = kurves |> List.map getColorAndDrawingPosition
    , bodyDrawing = []
    }


getColorAndDrawingPosition : Kurve -> ( Color, DrawingPosition )
getColorAndDrawingPosition kurve =
    ( kurve.color, World.drawingPosition kurve.state.position )
