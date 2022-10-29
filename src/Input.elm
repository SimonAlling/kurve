module Input exposing (KeyDirection(..), KeyboardInteraction, updatePressedKeys)

import Set exposing (Set(..))


type alias KeyboardInteraction =
    { happenedAfterTick : Int
    , direction : KeyDirection
    , key : String
    }


type KeyDirection
    = Up
    | Down


updatePressedKeys : KeyDirection -> String -> Set String -> Set String
updatePressedKeys direction =
    case direction of
        Down ->
            Set.insert

        Up ->
            Set.remove
