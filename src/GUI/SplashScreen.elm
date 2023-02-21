module GUI.SplashScreen exposing (splashScreen)

import Color
import GUI.Fonts exposing (Font(..))
import GUI.Text
import Html exposing (Html, div, span)
import Html.Attributes as Attr


splashScreen : Html msg
splashScreen =
    div
        [ Attr.id "splashScreen"
        ]
        [ span [] (GUI.Text.string BGIStroked 1 Color.white "HALL/OJ")
        ]
