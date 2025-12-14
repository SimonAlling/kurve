module GUI.TextOverlay exposing (textOverlay)

import Color
import GUI.Text
import Game exposing (GameState(..), LiveOrReplay(..), PausedOrNot(..))
import Html exposing (Html, div, p)
import Html.Attributes as Attr


textOverlay : GameState -> Html msg
textOverlay gameState =
    div
        [ Attr.class "overlay"
        , Attr.class "textOverlay"
        ]
        (content gameState)


content : GameState -> List (Html msg)
content gameState =
    case gameState of
        Active Live NotPaused _ ->
            []

        Active Live Paused _ ->
            [ pressSpaceToContinue ]

        Active Replay NotPaused _ ->
            [ replayIndicator ]

        Active Replay Paused _ ->
            [ replayIndicator, pressSpaceToContinue ]

        RoundOver _ _ ->
            []


pressSpaceToContinue : Html msg
pressSpaceToContinue =
    p [] <| GUI.Text.string (GUI.Text.Size 2) Color.white "Press Space to continue"


replayIndicator : Html msg
replayIndicator =
    p
        [ Attr.class "textInUpperLeftCorner"
        ]
        (GUI.Text.string (GUI.Text.Size 2) Color.white "R")
