port module Canvas exposing (clearEverything, drawingCmd, maybeDrawingCmd)

import Color exposing (Color)
import Drawing exposing (WhatToDraw)
import Thickness exposing (theThickness)
import Types.Kurve exposing (Kurve)
import World exposing (DrawingPosition)


port renderMain : List { position : DrawingPosition, thickness : Int, color : String } -> Cmd msg


port clearMain : () -> Cmd msg


port renderOverlay : List { position : DrawingPosition, thickness : Int, color : String } -> Cmd msg


maybeDrawingCmd : Maybe WhatToDraw -> Cmd msg
maybeDrawingCmd maybeWhatToDraw =
    case maybeWhatToDraw of
        Nothing ->
            Cmd.none

        Just whatToDraw ->
            drawingCmd whatToDraw


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


headDrawingCmd : List Kurve -> Cmd msg
headDrawingCmd =
    renderOverlay
        << List.map
            (\kurve ->
                { position = World.drawingPosition kurve.state.position
                , thickness = theThickness
                , color = Color.toCssString kurve.color
                }
            )


clearEverything : Cmd msg
clearEverything =
    Cmd.batch
        [ renderOverlay []
        , clearMain ()
        ]
