module GUI.TextOverlay exposing (textOverlay)

import Color
import GUI.Text
import Game exposing (GameState(..), Paused(..))
import Html exposing (Html, div, p)
import Html.Attributes as Attr


textOverlay : GameState -> Html msg
textOverlay gameState =
    div
        [ Attr.class "overlay"
        , Attr.class "textOverlay"
        ]
        [ content gameState
        ]


content : GameState -> Html msg
content gameState =
    case gameState of
        Active Paused _ ->
            pressSpaceToContinue

        _ ->
            nothing


pressSpaceToContinue : Html msg
pressSpaceToContinue =
    p [] <| GUI.Text.string (GUI.Text.Size 2) Color.white "Press Space to continue"


nothing : Html msg
nothing =
    Html.div [] []
