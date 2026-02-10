module Overlay exposing (State(..), ifVisible, toggle)

import Html exposing (Html)


type State
    = Visible
    | Hidden


ifVisible : State -> List (Html msg) -> List (Html msg)
ifVisible state content =
    case state of
        Visible ->
            content

        Hidden ->
            []


toggle : State -> State
toggle state =
    case state of
        Visible ->
            Hidden

        Hidden ->
            Visible
