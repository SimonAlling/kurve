module Types.Tickrate exposing (Tickrate(..), toFloat)

{-| Kurve runs at a fixed tickrate measured in ticks per second (Hz).
-}


type Tickrate
    = Tickrate Float


toFloat : Tickrate -> Float
toFloat (Tickrate r) =
    r
