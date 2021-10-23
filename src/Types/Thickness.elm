module Types.Thickness exposing (Thickness(..), toInt)

{-| A thickness in Kurve is traditionally measured in whole pixels.
-}


type Thickness
    = Thickness Int


toInt : Thickness -> Int
toInt (Thickness t) =
    t
