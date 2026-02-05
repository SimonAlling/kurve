module GUI.Hints exposing (Hint(..), render)

import Colors
import GUI.Text
import Html exposing (Html, span)
import Html.Attributes as Attr


type Hint
    = ShowHowToReplay


render : Hint -> Html msg
render hint =
    span
        [ Attr.class "hint"
        ]
        (GUI.Text.string (GUI.Text.Size 1) Colors.white (show hint))


show : Hint -> String
show hint =
    case hint of
        ShowHowToReplay ->
            "Press R to replay"
