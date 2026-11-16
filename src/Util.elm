module Util exposing
    ( find
    , isEven
    )


isEven : Int -> Bool
isEven n =
    modBy 2 n == 0


find : (a -> Bool) -> List a -> Maybe a
find predicate list =
    case list of
        [] ->
            Nothing

        first :: rest ->
            if predicate first then
                Just first

            else
                find predicate rest
