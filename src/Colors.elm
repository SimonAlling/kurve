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
    rgb 255 40 0


{-| The color of the yellow player in the original game.
-}
yellow : Color
yellow =
    rgb 195 195 0


{-| The color of the orange player in the original game.
-}
orange : Color
orange =
    rgb 255 121 0


{-| The color of the green player in the original game.
-}
green : Color
green =
    rgb 0 203 0


{-| The color of the pink player in the original game.
-}
pink : Color
pink =
    rgb 223 81 182


{-| The color of the blue player in the original game.
-}
blue : Color
blue =
    rgb 0 162 203


white : Color
white =
    rgb 255 255 255


rgb : Int -> Int -> Int -> Color
rgb =
    Color.rgb255
