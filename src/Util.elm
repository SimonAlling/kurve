module Util exposing (curry, isEven, maxSafeInteger)


curry : (( a, b ) -> c) -> a -> b -> c
curry f a b =
    f ( a, b )


isEven : Int -> Bool
isEven n =
    modBy 2 n == 0


{-| JavaScript's `Number.MAX_SAFE_INTEGER`.
-}
maxSafeInteger : Int
maxSafeInteger =
    9007199254740991
