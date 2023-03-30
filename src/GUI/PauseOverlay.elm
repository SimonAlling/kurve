module GUI.PauseOverlay exposing (pauseOverlay)

import Color
import GUI.Text
import Game exposing (GameState(..), Paused(..))
import Html exposing (Html, div, p)
import Html.Attributes as Attr


pauseOverlay : GameState -> Html msg
pauseOverlay gameState =
    div
        [ Attr.class "overlay"
        , Attr.class "pauseOverlay"
        , Attr.style "visibility" (visibility gameState)
        ]
        [ p [] <| GUI.Text.string (GUI.Text.Size 2) Color.white "Press Space to continue"
        ]


visibility : GameState -> String
visibility gameState =
    case gameState of
        Active Paused _ ->
            "visible"

        _ ->
            "hidden"
