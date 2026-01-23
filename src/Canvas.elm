port module Canvas exposing (clearEverything, drawingCmd)

import Color exposing (Color)
import Drawing exposing (WhatToDraw)
import Thickness exposing (theThickness)
import World exposing (DrawingPosition)


port renderMain : { clearFirst : Bool, squares : List { position : DrawingPosition, thickness : Int, color : String } } -> Cmd msg


port clearMain : () -> Cmd msg


port renderOverlay : List { position : DrawingPosition, thickness : Int, color : String } -> Cmd msg


drawingCmd : Bool -> WhatToDraw -> Cmd msg
drawingCmd clearFirst whatToDraw =
    [ headDrawingCmd whatToDraw.headDrawing
    , bodyDrawingCmd clearFirst whatToDraw.bodyDrawing
    ]
        |> Cmd.batch


bodyDrawingCmd : Bool -> List ( Color, DrawingPosition ) -> Cmd msg
bodyDrawingCmd clearFirst coloredDrawingPositions =
    renderMain
        { clearFirst = clearFirst
        , squares =
            List.map
                (\( color, position ) ->
                    { position = position
                    , thickness = theThickness
                    , color = Color.toCssString color
                    }
                )
                coloredDrawingPositions
        }


headDrawingCmd : List ( Color, DrawingPosition ) -> Cmd msg
headDrawingCmd =
    renderOverlay
        << List.map
            (\( color, position ) ->
                { position = position
                , thickness = theThickness
                , color = Color.toCssString color
                }
            )


clearEverything : Cmd msg
clearEverything =
    Cmd.batch
        [ renderOverlay []
        , clearMain ()
        ]
