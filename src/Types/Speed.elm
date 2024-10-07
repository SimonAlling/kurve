module Types.Speed exposing
    ( Speed(..)
    , toFloat
    )

{-| Speeds in Kurve are traditionally measured in pixels per second.
-}


type Speed
    = Speed Float


toFloat : Speed -> Float
toFloat (Speed s) =
    s
