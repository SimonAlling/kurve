port module Canvas exposing (bodyDrawingCmds, clearCanvasAndDrawSpawns, clearOverlay, headDrawingCmds)

import Color exposing (Color)
import Config
import Types.Player exposing (Player)
import Types.Thickness as Thickness exposing (Thickness(..))
import World exposing (DrawingPosition)


port render : { position : DrawingPosition, thickness : Int, color : String } -> Cmd msg


port clear : { width : Int, height : Int } -> Cmd msg


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


clearCanvasAndDrawSpawns : List Player -> Cmd msg
clearCanvasAndDrawSpawns thePlayers =
    clearOverlay { width = Config.worldWidth, height = Config.worldHeight }
        :: clear { width = Config.worldWidth, height = Config.worldHeight }
        :: (thePlayers
                |> List.map
                    (\player ->
                        render
                            { position = World.drawingPosition Config.thickness player.position
                            , thickness = Thickness.toInt Config.thickness
                            , color = Color.toCssString player.color
                            }
                    )
           )
        |> Cmd.batch
