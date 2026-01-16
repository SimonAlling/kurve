module GUI.TextOverlay exposing (textOverlay)

import Colors
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
        Active Live Paused _ ->
            [ pressSpaceToContinue ]

        Active Live NotPaused _ ->
            []

        Active Replay Paused _ ->
            -- Hint on how to continue deliberately omitted here. See the PR/commit that added this comment for details.
            [ replayIndicator ]

        Active Replay NotPaused _ ->
            [ replayIndicator ]

        RoundOver _ _ ->
            []


pressSpaceToContinue : Html msg
pressSpaceToContinue =
    p [] <| GUI.Text.string (GUI.Text.Size 2) Colors.white "Press Space to continue"


replayIndicator : Html msg
replayIndicator =
    p
        [ Attr.class "textInUpperLeftCorner"
        ]
        (GUI.Text.string (GUI.Text.Size 2) Colors.white "R")
