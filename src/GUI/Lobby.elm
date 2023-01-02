module GUI.Lobby exposing (lobby)

import Html exposing (Html, div)
import Html.Attributes as Attr


lobby : Html msg
lobby =
    div
        [ Attr.id "lobby"
        ]
        [ Html.text "Press Space to start" ]
