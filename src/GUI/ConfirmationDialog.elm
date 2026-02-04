module GUI.ConfirmationDialog exposing (confirmDialog)

import Colors
import Dialog
import GUI.DialogQuestion exposing (showQuestion)
import GUI.Text
import Game exposing (GameState(..))
import Html exposing (Attribute, Html, button, div, p)
import Html.Attributes as Attr
import Html.Events exposing (onClick)


confirmDialog : (Dialog.Option -> msg) -> GameState -> Html msg
confirmDialog makeMsg gameState =
    case gameState of
        RoundOver _ _ _ _ (Dialog.Open question selectedOption) ->
            div
                [ Attr.class "overlay"
                , Attr.class "dialogOverlay"
                ]
                [ dialogBox makeMsg (showQuestion question) selectedOption
                ]

        _ ->
            Html.text ""


dialogBox : (Dialog.Option -> msg) -> String -> Dialog.Option -> Html msg
dialogBox makeMsg question selectedOption =
    let
        optionButton : Dialog.Option -> String -> Html msg
        optionButton option label =
            button (onClick (makeMsg option) :: focusedIf selectedOption option) (smallWhiteText label)
    in
    div [ Attr.class "dialog" ]
        [ p [] (smallWhiteText question)
        , optionButton Dialog.Confirm "Yes"
        , optionButton Dialog.Cancel "No"
        ]


focusedIf : Dialog.Option -> Dialog.Option -> List (Attribute msg)
focusedIf a b =
    if a == b then
        [ Attr.class "focused" ]

    else
        []


smallWhiteText : String -> List (Html msg)
smallWhiteText =
    GUI.Text.string (GUI.Text.Size 1) Colors.white
