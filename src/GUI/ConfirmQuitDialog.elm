module GUI.ConfirmQuitDialog exposing (..)

import Elements.Dialog exposing (dialog, open)
import Game exposing (DialogOption(..), GameState(..), QuitDialogState(..))
import Html exposing (Html, button, text)
import Html.Attributes as Attr


confirmQuitDialog : GameState -> Html msg
confirmQuitDialog gameState =
    case gameState of
        PostRound _ DialogOpen ->
            dialog [ open ]
                [ text "Really quit?"
                , button [ Attr.autofocus True ] [ text "Yes" ]
                , button [] [ text "No" ]
                ]

        _ ->
            dialog [] []
