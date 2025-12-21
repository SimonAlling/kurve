port module Canvas exposing (RenderAction, clearEverything, draw, drawSpawnIfAndOnlyIf, drawSpawnsPermanently, drawingCmd, mergeRenderAction, nothingToDraw)

import Color exposing (Color)
import Config exposing (WorldConfig)
import Thickness exposing (theThickness)
import Types.Kurve exposing (Kurve)
import World exposing (DrawingPosition)


port render : List { position : DrawingPosition, thickness : Int, color : String } -> Cmd msg


port clear : { x : Int, y : Int, width : Int, height : Int } -> Cmd msg


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


drawSpawnsPermanently : List Kurve -> Cmd msg
drawSpawnsPermanently kurves =
    kurves
        |> List.map
            (\kurve ->
                ( kurve.color, World.drawingPosition kurve.state.position )
            )
        |> bodyDrawingCmd


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


drawSpawnIfAndOnlyIf : Bool -> Kurve -> List Kurve -> Cmd msg
drawSpawnIfAndOnlyIf shouldBeVisible kurve alreadySpawnedKurves =
    if shouldBeVisible then
        headDrawingCmd (kurve :: alreadySpawnedKurves)

    else
        headDrawingCmd alreadySpawnedKurves
