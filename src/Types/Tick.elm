module Types.Tick exposing (Tick, fromInt, genesis, succ, toInt)


type Tick
    = Tick Int


{-| The tick at which Kurves are released.
-}
genesis : Tick
genesis =
    Tick 0


succ : Tick -> Tick
succ (Tick n) =
    Tick (n + 1)


toInt : Tick -> Int
toInt (Tick n) =
    n


fromInt : Int -> Tick
fromInt =
    Tick
