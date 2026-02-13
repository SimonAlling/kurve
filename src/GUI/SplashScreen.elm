module GUI.SplashScreen exposing (splashScreen)

import Colors
import GUI.Text as Text
import Html exposing (Html, a, button, div, span)
import Html.Attributes as Attr
import Html.Events


splashScreen : msg -> Html msg
splashScreen fullscreenMsg =
    div
        [ Attr.id "splashScreen"
        ]
        [ span
            [ Attr.id "splashscreen-start-hint"
            ]
            (Text.string (Text.Size 1) Colors.white "Press Space to start")
        , button
            [ Attr.class "splashscreen-link"
            , Html.Events.onClick fullscreenMsg
            ]
            (Text.string (Text.Size 1) Colors.white "Fullscreen")
        , a
            [ Attr.class "splashscreen-link"
            , Attr.href "https://github.com/SimonAlling/kurve"
            ]
            (Text.string (Text.Size 1) Colors.white "Source")
        ]
