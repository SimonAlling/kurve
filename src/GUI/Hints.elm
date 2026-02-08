module GUI.Hints exposing (Hint(..), Hints, dismiss, initial, render)

import Colors
import GUI.Text
import Html exposing (Html, button, span, text)
import Html.Attributes as Attr
import Html.Events exposing (onClick)


type Hints
    = Hints
        { showHowToReplay : Bool
        }


type Hint
    = ShowHowToReplay


initial : Hints
initial =
    Hints
        { showHowToReplay = True
        }


dismiss : Hint -> Hints -> Hints
dismiss hint (Hints hints) =
    case hint of
        ShowHowToReplay ->
            Hints { hints | showHowToReplay = False }


render : (Hint -> msg) -> Hints -> Hint -> Html msg
render makeHintDismissalMsg hints hint =
    if isActive hint hints then
        span
            [ Attr.class "hint"
            ]
            (GUI.Text.string (GUI.Text.Size 1) Colors.white (show hint ++ " ")
                ++ [ button
                        [ onClick (makeHintDismissalMsg ShowHowToReplay)
                        , Attr.class "dismissHint"
                        , Attr.title "Dismiss"
                        ]
                        []
                   ]
            )

    else
        text ""


isActive : Hint -> Hints -> Bool
isActive hint (Hints hints) =
    case hint of
        ShowHowToReplay ->
            hints.showHowToReplay


show : Hint -> String
show hint =
    case hint of
        ShowHowToReplay ->
            "Press R to replay"
