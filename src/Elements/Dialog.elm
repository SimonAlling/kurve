module Elements.Dialog exposing (dialog, open)

import Html exposing (Attribute, Html)
import Html.Attributes


dialog : List (Attribute msg) -> List (Html msg) -> Html msg
dialog =
    Html.node "dialog"


open : Attribute msg
open =
    Html.Attributes.attribute "open" ""
