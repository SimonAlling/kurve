module Input exposing (ButtonDirection(..), UserInteraction, updatePressedButtons)

import Set exposing (Set(..))


type alias UserInteraction =
    { happenedAfterTick : Int
    , direction : ButtonDirection
    , button : String
    }


type ButtonDirection
    = Up
    | Down


updatePressedButtons : ButtonDirection -> String -> Set String -> Set String
updatePressedButtons direction =
    case direction of
        Down ->
            Set.insert

        Up ->
            Set.remove
