port module Canvas exposing (WhatToDraw, clearEverything, drawSpawnIfAndOnlyIf, drawingCmd)

import Color exposing (Color)
import Config exposing (WorldConfig)
import Thickness exposing (theThickness)
import Types.Kurve exposing (Kurve)
import World exposing (DrawingPosition)


port render : List { position : DrawingPosition, thickness : Int, color : String } -> Cmd msg


port clear : { x : Int, y : Int, width : Int, height : Int } -> Cmd msg


port renderOverlay : List { position : DrawingPosition, thickness : Int, color : String } -> Cmd msg


type alias WhatToDraw =
    { headDrawing : List Kurve
    , bodyDrawing : List ( Color, DrawingPosition )
    }


drawingCmd : WhatToDraw -> Cmd msg
drawingCmd whatToDraw =
    [ headDrawingCmd whatToDraw.headDrawing
    , bodyDrawingCmd whatToDraw.bodyDrawing
    ]
        |> Cmd.batch


bodyDrawingCmd : List ( Color, DrawingPosition ) -> Cmd msg
bodyDrawingCmd =
    render
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


clearEverything : WorldConfig -> Cmd msg
clearEverything { width, height } =
    Cmd.batch
        [ renderOverlay []
        , clear { x = 0, y = 0, width = width, height = height }
        ]


drawSpawnIfAndOnlyIf : Bool -> Kurve -> Cmd msg
drawSpawnIfAndOnlyIf shouldBeVisible kurve =
    let
        drawingPosition : DrawingPosition
        drawingPosition =
            World.drawingPosition kurve.state.position
    in
    if shouldBeVisible then
        render <|
            List.singleton
                { position = drawingPosition
                , thickness = theThickness
                , color = Color.toCssString kurve.color
                }

    else
        clear
            { x = drawingPosition.leftEdge
            , y = drawingPosition.topEdge
            , width = theThickness
            , height = theThickness
            }
