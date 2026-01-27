module Util exposing
    ( curry
    , isEven
    , sign
    )


curry : (( a, b ) -> c) -> a -> b -> c
curry f a b =
    f ( a, b )


isEven : Int -> Bool
isEven n =
    modBy 2 n == 0


sign : number -> Order
sign x =
    compare x 0
