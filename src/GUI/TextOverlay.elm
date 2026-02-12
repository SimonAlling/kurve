module GUI.TextOverlay exposing (textOverlay)

import Colors
import GUI.Hints exposing (Hint(..), Hints)
import GUI.Navigation.Replay
import GUI.Text
import Game exposing (GameState(..), LiveOrReplay(..), PausedOrNot(..))
import Html exposing (Html, div, p)
import Html.Attributes as Attr
import Overlay


textOverlay : (Hint -> msg) -> Hints -> GameState -> Html msg
textOverlay makeHintDismissalMsg hints gameState =
    div
        [ Attr.class "overlay"
        , Attr.class "textOverlay"
        ]
        (content makeHintDismissalMsg hints gameState)


content : (Hint -> msg) -> Hints -> GameState -> List (Html msg)
content makeHintDismissalMsg hints gameState =
    case gameState of
        Active (Live _) Paused _ ->
            [ pressSpaceToContinue ]

        Active (Live _) NotPaused _ ->
            []

        Active (Replay overlayState _) Paused _ ->
            -- Hint on how to continue deliberately omitted here. See the PR/commit that added this comment for details.
            Overlay.ifVisible overlayState [ replayIndicator, GUI.Navigation.Replay.replayNavigation ]

        Active (Replay overlayState _) NotPaused _ ->
            Overlay.ifVisible overlayState [ replayIndicator, GUI.Navigation.Replay.replayNavigation ]

        RoundOver (Live _) _ _ _ ->
            [ GUI.Hints.render makeHintDismissalMsg hints HowToReplay
            ]

        RoundOver (Replay overlayState _) _ _ _ ->
            Overlay.ifVisible overlayState [ replayIndicator, GUI.Navigation.Replay.replayNavigation ]


pressSpaceToContinue : Html msg
pressSpaceToContinue =
    p [] <| GUI.Text.string (GUI.Text.Size 2) Colors.white "Press Space to continue"


replayIndicator : Html msg
replayIndicator =
    p
        [ Attr.class "textInUpperLeftCorner"
        ]
        (GUI.Text.string (GUI.Text.Size 2) Colors.white "R")
