module Types.Radius exposing (Radius(..), toFloat)

{-| A (turning) radius in Kurve is traditionally measured in kuxels.
-}


type Radius
    = Radius Float


toFloat : Radius -> Float
toFloat (Radius r) =
    r
