module GUI.ConfirmQuitDialog exposing (..)

import Browser.Dom
import Elements.Dialog exposing (dialog, open)
import Game exposing (DialogOption(..), GameState(..), QuitDialogState(..))
import Html exposing (Html, button, text)
import Html.Attributes as Attr
import Html.Events exposing (onClick)
import Task


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
        , button [ onClick (f Confirm) ] [ text "Yes" ]
        , button [ onClick (f Cancel), Attr.id confirmButtonID ] [ text "No" ]
        ]


confirmButtonID : String
confirmButtonID =
    "confirm-quit-button-cancel"


focusCancelButton : (Result Browser.Dom.Error () -> msg) -> Cmd msg
focusCancelButton f =
    Task.attempt f (Browser.Dom.focus confirmButtonID)
