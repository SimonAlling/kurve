module Types.SquaredDistance exposing
    ( SquaredDistance(..)
    , lessThan
    , min
    )


type SquaredDistance
    = SquaredDistance Float


min : SquaredDistance -> SquaredDistance -> SquaredDistance
min (SquaredDistance a) (SquaredDistance b) =
    SquaredDistance (Basics.min a b)


lessThan : SquaredDistance -> SquaredDistance -> Bool
lessThan (SquaredDistance first) (SquaredDistance second) =
    first < second
