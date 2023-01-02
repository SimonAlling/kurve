module Types.Player exposing (Player)

import Color exposing (Color)
import Input exposing (Button)


type alias Player =
    { color : Color
    , controls : ( List Button, List Button )
    }
