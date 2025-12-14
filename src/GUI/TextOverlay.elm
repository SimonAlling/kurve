module GUI.TextOverlay exposing (textOverlay)

import Color
import GUI.Text
import Game exposing (ActiveGameState(..), GameState(..), MidRoundStateVariant(..), Paused(..))
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
        Active Paused (Spawning _ ( Live, _ )) ->
            [ pressSpaceToContinue ]

        Active Paused (Moving _ _ ( Live, _ )) ->
            [ pressSpaceToContinue ]

        Active NotPaused (Spawning _ ( Replay, _ )) ->
            [ replayIndicator ]

        Active NotPaused (Moving _ _ ( Replay, _ )) ->
            [ replayIndicator ]

        Active Paused (Spawning _ ( Replay, _ )) ->
            [ replayIndicator, pressSpaceToContinue ]

        Active Paused (Moving _ _ ( Replay, _ )) ->
            [ replayIndicator, pressSpaceToContinue ]

        _ ->
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
