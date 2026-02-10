module GUI.TextOverlay exposing (textOverlay)

import Colors
import GUI.Hints exposing (Hint(..))
import GUI.Navigation.Replay
import GUI.Text
import Game exposing (GameState(..), LiveOrReplay(..), PausedOrNot(..))
import Html exposing (Html, div, p)
import Html.Attributes as Attr
import Overlay


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
        Active (Live _) Paused _ ->
            [ pressSpaceToContinue ]

        Active (Live _) NotPaused _ ->
            []

        Active (Replay overlayState _) Paused _ ->
            Overlay.ifVisible
                overlayState
                -- Hint on how to continue deliberately omitted here. See the PR/commit that added this comment for details.
                [ replayIndicator, GUI.Navigation.Replay.replayNavigation ]

        Active (Replay overlayState _) NotPaused _ ->
            Overlay.ifVisible
                overlayState
                [ replayIndicator, GUI.Navigation.Replay.replayNavigation ]

        RoundOver (Live _) _ _ _ ->
            [ GUI.Hints.render HowToReplay
            ]

        RoundOver (Replay overlayState _) _ _ _ ->
            Overlay.ifVisible
                overlayState
                [ replayIndicator, GUI.Navigation.Replay.replayNavigation ]


pressSpaceToContinue : Html msg
pressSpaceToContinue =
    p [] <| GUI.Text.string (GUI.Text.Size 2) Colors.white "Press Space to continue"


replayIndicator : Html msg
replayIndicator =
    p
        [ Attr.class "textInUpperLeftCorner"
        ]
        (GUI.Text.string (GUI.Text.Size 2) Colors.white "R")
