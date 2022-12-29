port module Canvas exposing (bodyDrawingCmd, clearEverything, clearOverlay, drawSpawnIfAndOnlyIf, headDrawingCmd)

import Color exposing (Color)
import Types.Player exposing (Player)
import Types.Thickness as Thickness exposing (Thickness)
import World exposing (DrawingPosition)


port render : List { position : DrawingPosition, thickness : Int, color : String } -> Cmd msg


port clear : { x : Int, y : Int, width : Int, height : Int } -> Cmd msg


port renderOverlay : List { position : DrawingPosition, thickness : Int, color : String } -> Cmd msg


port clearOverlay : { x : Int, y : Int, width : Int, height : Int } -> Cmd msg


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


headDrawingCmd : Thickness -> List Player -> Cmd msg
headDrawingCmd thickness =
    renderOverlay
        << List.map
            (\player ->
                { position = World.drawingPosition thickness player.state.position
                , thickness = Thickness.toInt thickness
                , color = Color.toCssString player.color
                }
            )


clearEverything : ( Int, Int ) -> Cmd msg
clearEverything ( worldWidth, worldHeight ) =
    Cmd.batch
        [ clearOverlay { x = 0, y = 0, width = worldWidth, height = worldHeight }
        , clear { x = 0, y = 0, width = worldWidth, height = worldHeight }
        ]


drawSpawnIfAndOnlyIf : Bool -> Player -> Thickness -> Cmd msg
drawSpawnIfAndOnlyIf shouldBeVisible player thickness =
    let
        thicknessAsInt : Int
        thicknessAsInt =
            Thickness.toInt thickness

        drawingPosition : DrawingPosition
        drawingPosition =
            World.drawingPosition thickness player.state.position
    in
    if shouldBeVisible then
        render <|
            List.singleton
                { position = drawingPosition
                , thickness = thicknessAsInt
                , color = Color.toCssString player.color
                }

    else
        clear
            { x = drawingPosition.leftEdge
            , y = drawingPosition.topEdge
            , width = thicknessAsInt
            , height = thicknessAsInt
            }
