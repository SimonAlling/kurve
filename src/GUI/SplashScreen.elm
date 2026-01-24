module GUI.SplashScreen exposing (splashScreen)

import Colors
import GUI.Text as Text
import Html exposing (Html, a, div)
import Html.Attributes as Attr


splashScreen : Html msg
splashScreen =
    div
        [ Attr.id "splashScreen"
        ]
        [ a
            [ Attr.class "source-link"
            , Attr.href "https://github.com/SimonAlling/kurve"
            ]
            (Text.string (Text.Size 1) Colors.white "Source")
        ]
