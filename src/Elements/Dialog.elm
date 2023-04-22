module Elements.Dialog exposing (dialog, open)

import Html exposing (Attribute, Html)
import Html.Attributes as Attr


dialog : List (Attribute msg) -> List (Html msg) -> Html msg
dialog =
    Html.node "dialog"


open : Attribute msg
open =
    Attr.attribute "open" ""
