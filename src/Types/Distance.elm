module Types.Distance exposing
    ( Distance(..)
    , toFloat
    )

{-| A distance in Kurve is traditionally measured in pixels.
-}


type Distance
    = Distance Float


toFloat : Distance -> Float
toFloat (Distance r) =
    r
