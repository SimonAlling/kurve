port module Canvas exposing (bodyDrawingCmds, clearEverything, clearOverlay, drawSpawnIfAndOnlyIf, headDrawingCmds)

import Color exposing (Color)
import Config
import Types.Player exposing (Player)
import Types.Thickness as Thickness exposing (Thickness(..))
import World exposing (DrawingPosition)


port render : { position : DrawingPosition, thickness : Int, color : String } -> Cmd msg


port clear : { x : Int, y : Int, width : Int, height : Int } -> Cmd msg


port renderOverlay : { position : DrawingPosition, thickness : Int, color : String } -> Cmd msg


port clearOverlay : { width : Int, height : Int } -> Cmd msg


bodyDrawingCmds : List ( Color, DrawingPosition ) -> List (Cmd msg)
bodyDrawingCmds =
    List.map
        (\( color, position ) ->
            render
                { position = position
                , thickness = Thickness.toInt Config.thickness
                , color = Color.toCssString color
                }
        )


headDrawingCmds : List Player -> List (Cmd msg)
headDrawingCmds =
    List.map
        (\player ->
            renderOverlay
                { position = World.drawingPosition Config.thickness player.position
                , thickness = Thickness.toInt Config.thickness
                , color = Color.toCssString player.color
                }
        )


clearEverything : Cmd msg
clearEverything =
    Cmd.batch
        [ clearOverlay { width = Config.worldWidth, height = Config.worldHeight }
        , clear { x = 0, y = 0, width = Config.worldWidth, height = Config.worldHeight }
        ]


drawSpawnIfAndOnlyIf : Bool -> Player -> Cmd msg
drawSpawnIfAndOnlyIf shouldBeVisible player =
    let
        thicknessAsInt =
            Thickness.toInt Config.thickness

        drawingPosition =
            World.drawingPosition Config.thickness player.position
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
