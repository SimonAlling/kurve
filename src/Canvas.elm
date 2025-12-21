port module Canvas exposing (BodyDraw(..), RenderAction(..), clearEverything, drawSpawnIfAndOnlyIf, drawingCmd, mergeRenderAction)

import Color exposing (Color)
import Config exposing (WorldConfig)
import Round exposing (Round)
import Thickness exposing (theThickness)
import Types.Kurve exposing (Kurve)
import World exposing (DrawingPosition)


port render : List { position : DrawingPosition, thickness : Int, color : String } -> Cmd msg


port clear : { x : Int, y : Int, width : Int, height : Int } -> Cmd msg


port renderOverlay : List { position : DrawingPosition, thickness : Int, color : String } -> Cmd msg


type RenderAction
    = LeaveAsIs
    | Tell WhatToDraw


type alias WhatToDraw =
    { headDrawing : List Kurve
    , bodyDrawing : List BodyDraw
    }


type BodyDraw
    = DrawOne ( Color, DrawingPosition )
    | Clear DrawingPosition { width : Int, height : Int }


mergeRenderAction : RenderAction -> RenderAction -> RenderAction
mergeRenderAction whatFirst whatThen =
    case ( whatFirst, whatThen ) of
        ( LeaveAsIs, LeaveAsIs ) ->
            LeaveAsIs

        ( LeaveAsIs, Tell told ) ->
            Tell told

        ( Tell told, LeaveAsIs ) ->
            Tell told

        ( Tell toldFirst, Tell toldThen ) ->
            Tell <| mergeWhatToDraw toldFirst toldThen


mergeWhatToDraw : WhatToDraw -> WhatToDraw -> WhatToDraw
mergeWhatToDraw toldFirst toldThen =
    { headDrawing = toldThen.headDrawing
    , bodyDrawing = toldFirst.bodyDrawing ++ toldThen.bodyDrawing
    }


drawingCmd : RenderAction -> Cmd msg
drawingCmd whatToDraw =
    case whatToDraw of
        LeaveAsIs ->
            Cmd.none

        Tell told ->
            [ headDrawingCmd told.headDrawing
            , bodyDrawingCmd told.bodyDrawing
            ]
                |> Cmd.batch


bodyDrawingCmd : List BodyDraw -> Cmd msg
bodyDrawingCmd =
    Cmd.batch
        << List.map
            (\bodyDraw ->
                case bodyDraw of
                    DrawOne ( color, position ) ->
                        render <|
                            List.singleton
                                { position = position
                                , thickness = theThickness
                                , color = Color.toCssString color
                                }

                    Clear position size ->
                        clear { x = position.leftEdge, y = position.topEdge, width = size.width, height = size.height }
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


clearEverything : WorldConfig -> RenderAction
clearEverything { width, height } =
    Tell
        { headDrawing = []
        , bodyDrawing = List.singleton (Clear { leftEdge = 0, topEdge = 0 } { width = width, height = height })
        }


drawSpawnIfAndOnlyIf : Bool -> Kurve -> RenderAction
drawSpawnIfAndOnlyIf shouldBeVisible kurve =
    let
        drawingPosition : DrawingPosition
        drawingPosition =
            World.drawingPosition kurve.state.position
    in
    if shouldBeVisible then
        Tell
            { headDrawing = []
            , bodyDrawing = List.singleton (DrawOne ( kurve.color, drawingPosition ))
            }

    else
        Tell
            { headDrawing = []
            , bodyDrawing = List.singleton (Clear drawingPosition { width = theThickness, height = theThickness })
            }
