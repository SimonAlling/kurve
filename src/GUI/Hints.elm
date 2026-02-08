module GUI.Hints exposing (Hint(..), Hints, dismiss, initial, render)

import Colors
import GUI.Text
import Html exposing (Html, button, span, text)
import Html.Attributes as Attr
import Html.Events exposing (onClick)


type Hints
    = Hints
        { howToReplay : HintState
        }


type Hint
    = HowToReplay


type HintState
    = Active
    | Dismissed


initial : Hints
initial =
    Hints
        { howToReplay = Active
        }


dismiss : Hint -> Hints -> Hints
dismiss hint (Hints hints) =
    case hint of
        HowToReplay ->
            Hints { hints | howToReplay = Dismissed }


render : (Hint -> msg) -> Hints -> Hint -> Html msg
render makeHintDismissalMsg hints hint =
    if isActive hint hints then
        span
            [ Attr.class "hint"
            ]
            [ span
                [ Attr.class "hintText"
                ]
                (GUI.Text.string (GUI.Text.Size 1) Colors.white (show hint))
            , dismissButton makeHintDismissalMsg
            ]

    else
        text ""


isActive : Hint -> Hints -> Bool
isActive hint hints =
    case getState hint hints of
        Active ->
            True

        Dismissed ->
            False


getState : Hint -> Hints -> HintState
getState hint (Hints hints) =
    case hint of
        HowToReplay ->
            hints.howToReplay


dismissButton : (Hint -> msg) -> Html msg
dismissButton makeHintDismissalMsg =
    button
        [ onClick (makeHintDismissalMsg HowToReplay)
        , Attr.class "dismissHint"
        , Attr.title "Dismiss"
        ]
        []


show : Hint -> String
show hint =
    case hint of
        HowToReplay ->
            "Press R to replay"
