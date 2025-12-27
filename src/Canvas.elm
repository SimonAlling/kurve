port module Canvas exposing (RenderAction, clearEverything, draw, drawSpawnIfAndOnlyIf, drawSpawnsPermanently, drawingCmd, mergeRenderAction, nothingToDraw)

import Color exposing (Color)
import Thickness exposing (theThickness)
import Types.Kurve exposing (Kurve)
import World exposing (DrawingPosition)


port renderMain : List { position : DrawingPosition, thickness : Int, color : String } -> Cmd msg


port clearMain : () -> Cmd msg


port renderOverlay : List { position : DrawingPosition, thickness : Int, color : String } -> Cmd msg


type RenderAction
    = LeaveAsIs
    | Draw WhatToDraw


type alias WhatToDraw =
    { headDrawing : List Kurve
    , bodyDrawing : List ( Color, DrawingPosition )
    }


draw : List Kurve -> List ( Color, DrawingPosition ) -> RenderAction
draw aliveKurves newColoredDrawingPositions =
    Draw
        { headDrawing = aliveKurves
        , bodyDrawing = newColoredDrawingPositions
        }


nothingToDraw : RenderAction
nothingToDraw =
    LeaveAsIs


mergeRenderAction : RenderAction -> RenderAction -> RenderAction
mergeRenderAction actionFirst actionThen =
    case ( actionFirst, actionThen ) of
        ( LeaveAsIs, LeaveAsIs ) ->
            LeaveAsIs

        ( LeaveAsIs, Draw whatToDraw ) ->
            Draw whatToDraw

        ( Draw whatToDraw, LeaveAsIs ) ->
            Draw whatToDraw

        ( Draw whatFirst, Draw whatThen ) ->
            Draw <| mergeWhatToDraw whatFirst whatThen


mergeWhatToDraw : WhatToDraw -> WhatToDraw -> WhatToDraw
mergeWhatToDraw whatFirst whatThen =
    { headDrawing = whatThen.headDrawing
    , bodyDrawing = whatFirst.bodyDrawing ++ whatThen.bodyDrawing
    }


drawSpawnsPermanently : List Kurve -> RenderAction
drawSpawnsPermanently kurves =
    Draw
        { headDrawing = []
        , bodyDrawing =
            kurves
                |> List.map
                    (\kurve ->
                        ( kurve.color, World.drawingPosition kurve.state.position )
                    )
        }


drawingCmd : RenderAction -> Cmd msg
drawingCmd renderAction =
    case renderAction of
        LeaveAsIs ->
            Cmd.none

        Draw whatToDraw ->
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


drawSpawnIfAndOnlyIf : Bool -> Kurve -> List Kurve -> RenderAction
drawSpawnIfAndOnlyIf shouldBeVisible kurve alreadySpawnedKurves =
    if shouldBeVisible then
        Draw { headDrawing = kurve :: alreadySpawnedKurves, bodyDrawing = [] }

    else
        Draw { headDrawing = alreadySpawnedKurves, bodyDrawing = [] }
