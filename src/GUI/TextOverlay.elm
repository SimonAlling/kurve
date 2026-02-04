module GUI.TextOverlay exposing (textOverlay)

import Colors
import GUI.Navigation.Replay
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
            [ replayIndicator, GUI.Navigation.Replay.whenActive ]

        Active Replay NotPaused _ ->
            [ replayIndicator, GUI.Navigation.Replay.whenActive ]

        RoundOver Live _ _ _ _ ->
            [ pressRToReplay ]

        RoundOver Replay _ _ _ _ ->
            [ replayIndicator, GUI.Navigation.Replay.whenRoundOver ]


pressSpaceToContinue : Html msg
pressSpaceToContinue =
    p [] <| GUI.Text.string (GUI.Text.Size 2) Colors.white "Press Space to continue"


replayIndicator : Html msg
replayIndicator =
    p
        [ Attr.class "textInUpperLeftCorner"
        ]
        (GUI.Text.string (GUI.Text.Size 2) Colors.white "R")


pressRToReplay : Html msg
pressRToReplay =
    p
        [ Attr.id "roundOverReplayHint"
        ]
        (GUI.Text.string (GUI.Text.Size 1) Colors.white "Press R to replay")
