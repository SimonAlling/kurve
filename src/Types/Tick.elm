module Types.Tick exposing (Tick(..), succ)


type Tick
    = Tick Int


succ : Tick -> Tick
succ (Tick n) =
    Tick (n + 1)
