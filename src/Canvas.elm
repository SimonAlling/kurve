port module Canvas exposing (clearEverything, drawingCmd)

import Color exposing (Color)
import Drawing exposing (WhatToDraw)
import Thickness exposing (theThickness)
import World exposing (DrawingPosition)


port renderMain : List { position : DrawingPosition, thickness : Int, color : String } -> Cmd msg


port clearMain : () -> Cmd msg


port renderOverlay : List { position : DrawingPosition, thickness : Int, color : String } -> Cmd msg


drawingCmd : WhatToDraw -> Cmd msg
drawingCmd whatToDraw =
    [ headDrawingCmd whatToDraw.headDrawing
    , bodyDrawingCmd whatToDraw.bodyDrawing
    ]
        |> Cmd.batch


bodyDrawingCmd : List ( Color, DrawingPosition ) -> Cmd msg
bodyDrawingCmd =
    renderMain
        << List.map
            (\( color, position ) ->
                { position = position
                , thickness = theThickness
                , color = Color.toCssString color
                }
            )


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
