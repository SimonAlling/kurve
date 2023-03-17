module GUI.ConfirmQuitDialog exposing (..)

import Game exposing (DialogOption(..), GameState(..), QuitDialogState(..))
import Html exposing (Html, button, div, text)


confirmQuitDialog : GameState -> Html msg
confirmQuitDialog gameState =
    case gameState of
        PostRound _ DialogOpen ->
            div []
                [ text "Really quit?"
                , button [] [ text "Yes" ]
                , button [] [ text "No" ]
                ]

        _ ->
            div [] []
