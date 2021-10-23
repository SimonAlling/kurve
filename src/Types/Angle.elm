module Types.Angle exposing (Angle(..), toFloat)

{-| Angles are measured in radians.
-}


type Angle
    = Angle Float


toFloat : Angle -> Float
toFloat (Angle a) =
    a
