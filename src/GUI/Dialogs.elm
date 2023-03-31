module GUI.Dialogs exposing (overlay)

import Color
import Cycle
import Dialog
import GUI.Text
import Game exposing (GameState(..))
import Html exposing (Attribute, Html, button, div, p)
import Html.Attributes as Attr
import Html.Events exposing (onClick)


overlay : (Dialog.Option -> msg) -> GameState -> Html msg
overlay makeMsg gameState =
    div [ Attr.class "overlay", Attr.class "dialogOverlay" ] <|
        case gameState of
            PostRound _ (Dialog.Open dialogOpenState) ->
                List.singleton <| confirm makeMsg "Really quit?" dialogOpenState

            _ ->
                []


confirm : (Dialog.Option -> msg) -> String -> Dialog.OpenState -> Html msg
confirm makeMsg question dialogOpenState =
    let
        optionButton : Bool -> Dialog.Option -> Html msg
        optionButton focused option =
            button (onClick (makeMsg option) :: focusedIf focused) (smallWhiteText (optionLabel option))
    in
    div [ Attr.class "dialog" ] <|
        p []
            (smallWhiteText question)
            :: (dialogOpenState
                    |> Cycle.map3
                        ( optionButton False
                        , optionButton True
                        , optionButton False
                        )
                    |> Cycle.toList
               )


optionLabel : Dialog.Option -> String
optionLabel option =
    case option of
        Dialog.Confirm ->
            "Yes"

        Dialog.Cancel ->
            "No"


focusedIf : Bool -> List (Attribute msg)
focusedIf focused =
    if focused then
        [ Attr.class "focused" ]

    else
        []


smallWhiteText : String -> List (Html msg)
smallWhiteText =
    GUI.Text.string (GUI.Text.Size 1) Color.white
