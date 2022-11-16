module Util exposing (isEven)


isEven : Int -> Bool
isEven n =
    modBy 2 n == 0
