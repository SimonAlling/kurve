module Types.Angle exposing (Angle(..), add, cos, negate, sin)

{-| Angles are measured in radians.
-}


type Angle
    = Angle Float


toFloat : Angle -> Float
toFloat (Angle a) =
    a


add : Angle -> Angle -> Angle
add (Angle a) (Angle b) =
    Angle (a + b)


negate : Angle -> Angle
negate (Angle a) =
    Angle -a


cos : Angle -> Float
cos =
    toFloat >> Basics.cos


sin : Angle -> Float
sin =
    toFloat >> Basics.sin
