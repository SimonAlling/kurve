port module Canvas exposing (bodyDrawingCmd, clearEverything, drawSpawnIfAndOnlyIf, encodeSquare, headDrawingCmd)

import Color exposing (Color)
import Config exposing (WorldConfig)
import Json.Encode as Encode
import Thickness exposing (theThickness)
import Types.Kurve exposing (Kurve)
import World exposing (DrawingPosition)


port render : List Square -> Cmd msg


type alias Square =
    { position : DrawingPosition, thickness : Int, color : String }


encodeSquare : Square -> Encode.Value
encodeSquare square =
    Encode.object
        [ ( "position", encodeDrawingPosition square.position )
        , ( "thickness", Encode.int square.thickness )
        , ( "color", Encode.string square.color )
        ]


encodeDrawingPosition : DrawingPosition -> Encode.Value
encodeDrawingPosition drawingPosition =
    Encode.object
        [ ( "leftEdge", Encode.int drawingPosition.leftEdge )
        , ( "topEdge", Encode.int drawingPosition.topEdge )
        ]


port clear : { x : Int, y : Int, width : Int, height : Int } -> Cmd msg


port renderOverlay : List Square -> Cmd msg


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
