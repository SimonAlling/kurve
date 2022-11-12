module Types.PlayerId exposing (PlayerId(..), toInt)


type PlayerId
    = PlayerId Int


toInt : PlayerId -> Int
toInt (PlayerId n) =
    n
