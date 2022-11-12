port module Canvas exposing (bodyDrawingCmds, clearEverything, clearOverlay, drawSpawnIfAndOnlyIf, headDrawingCmds)

import Color exposing (Color)
import Types.Player exposing (Player)
import Types.Thickness as Thickness exposing (Thickness(..))
import World exposing (DrawingPosition)


port render : { position : DrawingPosition, thickness : Int, color : String } -> Cmd msg


port clear : { x : Int, y : Int, width : Int, height : Int } -> Cmd msg


port renderOverlay : { position : DrawingPosition, thickness : Int, color : String } -> Cmd msg


port clearOverlay : { width : Int, height : Int } -> Cmd msg


bodyDrawingCmds : Thickness -> List ( Color, DrawingPosition ) -> List (Cmd msg)
bodyDrawingCmds thickness =
    List.map
        (\( color, position ) ->
            render
                { position = position
                , thickness = Thickness.toInt thickness
                , color = Color.toCssString color
                }
        )


headDrawingCmds : Thickness -> List Player -> List (Cmd msg)
headDrawingCmds thickness =
    List.map
        (\player ->
            renderOverlay
                { position = World.drawingPosition thickness player.state.position
                , thickness = Thickness.toInt thickness
                , color = Color.toCssString player.color
                }
        )


clearEverything : ( Int, Int ) -> Cmd msg
clearEverything ( worldWidth, worldHeight ) =
    Cmd.batch
        [ clearOverlay { width = worldWidth, height = worldHeight }
        , clear { x = 0, y = 0, width = worldWidth, height = worldHeight }
        ]


drawSpawnIfAndOnlyIf : Bool -> Player -> Thickness -> Cmd msg
drawSpawnIfAndOnlyIf shouldBeVisible player thickness =
    let
        thicknessAsInt =
            Thickness.toInt thickness

        drawingPosition =
            World.drawingPosition thickness player.state.position
    in
    if shouldBeVisible then
        render
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
