port module Canvas exposing (bodyDrawingCmd, clearEverything, drawSpawnIfAndOnlyIf, headDrawingCmd)

import Color exposing (Color)
import Types.Kurve exposing (Kurve)
import Types.Thickness as Thickness exposing (Thickness)
import Util exposing (maxSafeInteger)
import World exposing (DrawingPosition)


port render : List { position : DrawingPosition, thickness : Int, color : String } -> Cmd msg


port clear : { x : Int, y : Int, width : Int, height : Int } -> Cmd msg


port renderOverlay : List { position : DrawingPosition, thickness : Int, color : String } -> Cmd msg


bodyDrawingCmd : Thickness -> List ( Color, DrawingPosition ) -> Cmd msg
bodyDrawingCmd thickness =
    render
        << List.map
            (\( color, position ) ->
                { position = position
                , thickness = Thickness.toInt thickness
                , color = Color.toCssString color
                }
            )


headDrawingCmd : Thickness -> List Kurve -> Cmd msg
headDrawingCmd thickness =
    renderOverlay
        << List.map
            (\kurve ->
                { position = World.drawingPosition thickness kurve.state.position
                , thickness = Thickness.toInt thickness
                , color = Color.toCssString kurve.color
                }
            )


clearEverything : Cmd msg
clearEverything =
    Cmd.batch
        [ renderOverlay []
        , clear { x = 0, y = 0, width = maxSafeInteger, height = maxSafeInteger }
        ]


drawSpawnIfAndOnlyIf : Bool -> Kurve -> Thickness -> Cmd msg
drawSpawnIfAndOnlyIf shouldBeVisible kurve thickness =
    let
        thicknessAsInt : Int
        thicknessAsInt =
            Thickness.toInt thickness

        drawingPosition : DrawingPosition
        drawingPosition =
            World.drawingPosition thickness kurve.state.position
    in
    if shouldBeVisible then
        render <|
            List.singleton
                { position = drawingPosition
                , thickness = thicknessAsInt
                , color = Color.toCssString kurve.color
                }

    else
        clear
            { x = drawingPosition.leftEdge
            , y = drawingPosition.topEdge
            , width = thicknessAsInt
            , height = thicknessAsInt
            }
