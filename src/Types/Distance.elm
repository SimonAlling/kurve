module Types.Distance exposing
    ( Distance(..)
    , computeDistanceBetweenCenters
    , generate
    , toFloat
    )

import Random
import Thickness exposing (theThickness)


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


{-| Takes the distance between the _edges_ of two drawn squares and returns the distance between their _centers_.
-}
computeDistanceBetweenCenters : Distance -> Distance
computeDistanceBetweenCenters distanceBetweenEdges =
    Distance <| toFloat distanceBetweenEdges + theThickness
