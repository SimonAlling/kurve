port module Canvas exposing (BodyDraw(..), WhatToDraw, clearEverything, drawSpawnIfAndOnlyIf, drawingCmd, mergeWhatToDraw, nothingToDraw)

import Color exposing (Color)
import Config exposing (WorldConfig)
import Thickness exposing (theThickness)
import Types.Kurve exposing (Kurve)
import World exposing (DrawingPosition)


port render : List { position : DrawingPosition, thickness : Int, color : String } -> Cmd msg


port clear : { x : Int, y : Int, width : Int, height : Int } -> Cmd msg


port renderOverlay : List { position : DrawingPosition, thickness : Int, color : String } -> Cmd msg


type BodyDraw
    = Draw ( Color, DrawingPosition )
    | Clear DrawingPosition { width : Int, height : Int }


type alias WhatToDraw =
    { headDrawing : List Kurve
    , bodyDrawing : List BodyDraw
    }


nothingToDraw : WhatToDraw
nothingToDraw =
    { headDrawing = []
    , bodyDrawing = []
    }


mergeWhatToDraw : WhatToDraw -> WhatToDraw -> WhatToDraw
mergeWhatToDraw whatFirst whatThen =
    { headDrawing = whatThen.headDrawing
    , bodyDrawing = whatFirst.bodyDrawing ++ whatThen.bodyDrawing
    }


drawingCmd : WhatToDraw -> Cmd msg
drawingCmd whatToDraw =
    [ headDrawingCmd whatToDraw.headDrawing
    , bodyDrawingCmd whatToDraw.bodyDrawing
    ]
        |> Cmd.batch


bodyDrawingCmd : List BodyDraw -> Cmd msg
bodyDrawingCmd =
    Cmd.batch
        << List.map
            (\bodyDraw ->
                case bodyDraw of
                    Draw ( color, position ) ->
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


clearEverything : WorldConfig -> WhatToDraw
clearEverything { width, height } =
    { headDrawing = []
    , bodyDrawing = List.singleton (Clear { leftEdge = 0, topEdge = 0 } { width = width, height = height })
    }


drawSpawnIfAndOnlyIf : Bool -> Kurve -> WhatToDraw
drawSpawnIfAndOnlyIf shouldBeVisible kurve =
    let
        drawingPosition : DrawingPosition
        drawingPosition =
            World.drawingPosition kurve.state.position
    in
    if shouldBeVisible then
        { headDrawing = []
        , bodyDrawing = List.singleton (Draw ( kurve.color, drawingPosition ))
        }

    else
        { headDrawing = []
        , bodyDrawing = List.singleton (Clear drawingPosition { width = theThickness, height = theThickness })
        }
