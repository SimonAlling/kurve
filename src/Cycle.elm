module Cycle exposing (Cycle, from, map3, next, previous, toList)


type alias Cycle a =
    ( List a, a, List a )


toList : Cycle a -> List a
toList ( stack, current, queue ) =
    List.reverse stack ++ current :: queue


from : ( List a, a, List a ) -> Cycle a
from ( before, current, after ) =
    ( List.reverse before, current, after )


map3 : ( a -> b, a -> b, a -> b ) -> Cycle a -> Cycle b
map3 ( f1, f2, f3 ) ( stack, current, queue ) =
    ( List.map f1 stack, f2 current, List.map f3 queue )


next : Cycle a -> Cycle a
next ( stack, current, queue ) =
    case queue of
        first :: rest ->
            ( current :: stack, first, rest )

        [] ->
            case List.reverse stack of
                init :: rest ->
                    ( [], init, rest ++ [ current ] )

                [] ->
                    ( [], current, [] )


previous : Cycle a -> Cycle a
previous =
    reverse >> next >> reverse


reverse : Cycle a -> Cycle a
reverse ( stack, current, queue ) =
    ( queue, current, stack )
