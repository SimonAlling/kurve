module GUI.ReplayOverlay exposing (replayOverlay)

import Color
import GUI.Text as Text
import Game exposing (ActiveGameState(..), GameState(..), MidRoundStateVariant(..))
import Html exposing (Html)
import Html.Attributes as Attr


replayOverlay : GameState -> Html msg
replayOverlay gameState =
    Html.div
        [ Attr.class "overlay"
        , Attr.class "replayOverlay"
        ]
        [ content gameState ]


content : GameState -> Html msg
content gameState =
    case gameState of
        Active _ (Spawning _ ( Replay, _ )) ->
            fullTextInTheMiddle

        Active _ (Moving _ _ ( Replay, _ )) ->
            singleLetterInTheCorner

        _ ->
            nothing


fullTextInTheMiddle : Html msg
fullTextInTheMiddle =
    Html.div
        []
        (Text.string (Text.Size 3) Color.white "REPLAY")


singleLetterInTheCorner : Html msg
singleLetterInTheCorner =
    Html.div
        [ Attr.class "singleLetterInTheCorner"
        ]
        (Text.string (Text.Size 2) Color.white "R")


nothing : Html msg
nothing =
    Html.div [] []
