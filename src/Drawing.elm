module Drawing exposing (WhatToDraw, drawSpawnsPermanently, drawSpawnsTemporarily, getColorAndDrawingPosition, mergeWhatToDraw)

import Color exposing (Color)
import Types.Kurve exposing (Kurve)
import World exposing (DrawingPosition)


type alias WhatToDraw =
    { headDrawing : List ( Color, DrawingPosition )
    , bodyDrawing : List ( Color, DrawingPosition )
    }


mergeWhatToDraw : WhatToDraw -> WhatToDraw -> WhatToDraw
mergeWhatToDraw whatFirst whatThen =
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
