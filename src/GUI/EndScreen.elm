module GUI.EndScreen exposing (endScreen)

import Html exposing (Html, div)
import Html.Attributes as Attr


endScreen : Html msg
endScreen =
    div
        [ Attr.id "endScreen"
        ]
        [ Html.text "KONEC HRY"
        ]
