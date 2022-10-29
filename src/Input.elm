module Input exposing (Button(..), ButtonDirection(..), UserInteraction, toStringSetControls, updatePressedButtons)

import Set exposing (Set(..))


type alias UserInteraction =
    { happenedAfterTick : Int
    , direction : ButtonDirection
    , button : Button
    }


type ButtonDirection
    = Up
    | Down


updatePressedButtons : ButtonDirection -> Button -> Set String -> Set String
updatePressedButtons direction =
    buttonToString
        >> (case direction of
                Down ->
                    Set.insert

                Up ->
                    Set.remove
           )


type Button
    = Key String


buttonToString : Button -> String
buttonToString (Key eventCode) =
    eventCode


toStringSetControls : ( List Button, List Button ) -> ( Set String, Set String )
toStringSetControls =
    Tuple.mapBoth buttonListToStringSet buttonListToStringSet


buttonListToStringSet : List Button -> Set String
buttonListToStringSet =
    List.map buttonToString >> Set.fromList
