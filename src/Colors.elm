module Colors exposing
    ( blue
    , green
    , orange
    , pink
    , red
    , white
    , yellow
    )

import Color exposing (Color)


{-| The color of the red player in the original game.
-}
red : Color
red =
    Color.rgb255 255 40 0


{-| The color of the yellow player in the original game.
-}
yellow : Color
yellow =
    Color.rgb255 195 195 0


{-| The color of the orange player in the original game.
-}
orange : Color
orange =
    Color.rgb255 255 121 0


{-| The color of the green player in the original game.
-}
green : Color
green =
    Color.rgb255 0 203 0


{-| The color of the pink player in the original game.
-}
pink : Color
pink =
    Color.rgb255 223 81 182


{-| The color of the blue player in the original game.
-}
blue : Color
blue =
    Color.rgb255 0 162 203


white : Color
white =
    Color.rgb255 255 255 255
