module GUI.ConfirmQuitDialog exposing (..)

import Elements.Dialog exposing (dialog, open)
import Game exposing (DialogOption(..), GameState(..), QuitDialogState(..))
import Html exposing (Html, button, text)
import Html.Attributes as Attr
import Html.Events exposing (onClick)


confirmQuitDialog : (DialogOption -> msg) -> GameState -> Html msg
confirmQuitDialog f gameState =
    let
        op =
            case gameState of
                PostRound _ DialogOpen ->
                    [ open ]

                _ ->
                    []
    in
    dialog op
        [ text "Really quit?"
        , button [ onClick (f Confirm), Attr.autofocus True ] [ text "Yes" ]
        , button [ onClick (f Cancel) ] [ text "No" ]
        ]
