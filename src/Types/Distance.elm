module Types.Distance exposing
    ( Distance(..)
    , generate
    , toFloat
    )

import Random


{-| A distance in Kurve is traditionally measured in pixels.
-}
type Distance
    = Distance Float


toFloat : Distance -> Float
toFloat (Distance r) =
    r


generate : Distance -> Distance -> Random.Generator Distance
generate min max =
    Random.float (toFloat min) (toFloat max) |> Random.map Distance
