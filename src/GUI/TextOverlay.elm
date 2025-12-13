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
        [ content gameState
        ]


content : GameState -> Html msg
content gameState =
    case gameState of
        Active Paused (Spawning _ ( Live, _ )) ->
            pressSpaceToContinue

        Active Paused (Moving _ _ ( Live, _ )) ->
            pressSpaceToContinue

        Active _ (Spawning _ ( Replay, _ )) ->
            fullReplayTextInTheMiddle

        Active _ (Moving _ _ ( Replay, _ )) ->
            singleReplayLetterInTheCorner

        _ ->
            nothing


pressSpaceToContinue : Html msg
pressSpaceToContinue =
    p [] <| GUI.Text.string (GUI.Text.Size 2) Color.white "Press Space to continue"


fullReplayTextInTheMiddle : Html msg
fullReplayTextInTheMiddle =
    p [] <| GUI.Text.string (GUI.Text.Size 3) Color.white "REPLAY"


singleReplayLetterInTheCorner : Html msg
singleReplayLetterInTheCorner =
    div
        [ Attr.class "textInUpperLeftCorner"
        ]
        (GUI.Text.string (GUI.Text.Size 2) Color.white "R")


nothing : Html msg
nothing =
    Html.div [] []
