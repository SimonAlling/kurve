module Types.Tick exposing (Tick, genesis, succ)


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
