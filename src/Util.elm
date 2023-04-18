module Util exposing (curry, isEven)


curry : (( a, b ) -> c) -> a -> b -> c
curry f a b =
    f ( a, b )


isEven : Int -> Bool
isEven n =
    modBy 2 n == 0
