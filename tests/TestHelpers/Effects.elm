module TestHelpers.Effects exposing
    ( clearsEverything
    , drawsBodySquares
    )

import Effect exposing (Effect(..))


drawsBodySquares : Effect -> Bool
drawsBodySquares effect =
    case effect of
        DrawSomething { bodyDrawing } ->
            not <| List.isEmpty bodyDrawing

        ClearAndThenDraw { bodyDrawing } ->
            not <| List.isEmpty bodyDrawing

        ClearEverything ->
            False

        ToggleFullscreen ->
            False

        SaveSettings _ ->
            False

        DoNothing ->
            False


clearsEverything : Effect -> Bool
clearsEverything effect =
    case effect of
        DrawSomething _ ->
            False

        ClearAndThenDraw _ ->
            True

        ClearEverything ->
            True

        ToggleFullscreen ->
            False

        SaveSettings _ ->
            False

        DoNothing ->
            False
