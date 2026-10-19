module Types.Radius exposing
    ( Radius(..)
    , toFloat
    )

{-| A (turning) radius in Kurve is traditionally measured in pixels.
-}


type Radius
    = Radius Float


toFloat : Radius -> Float
toFloat (Radius r) =
    r
