port module Input exposing (Button(..), ButtonDirection(..), UserInteraction, inputSubscriptions, toStringSetControls, updatePressedButtons)

import Set exposing (Set(..))


port onKeydown : (String -> msg) -> Sub msg


port onKeyup : (String -> msg) -> Sub msg


port onMousedown : (Int -> msg) -> Sub msg


port onMouseup : (Int -> msg) -> Sub msg


inputSubscriptions : (ButtonDirection -> Button -> msg) -> List (Sub msg)
inputSubscriptions makeMsg =
    [ onKeydown (Key >> makeMsg Down)
    , onKeyup (Key >> makeMsg Up)
    , onMousedown (Mouse >> makeMsg Down)
    , onMouseup (Mouse >> makeMsg Up)
    ]


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
    | Mouse Int


buttonToString : Button -> String
buttonToString button =
    case button of
        Key eventCode ->
            eventCode

        Mouse buttonNumber ->
            "Mouse" ++ String.fromInt buttonNumber


toStringSetControls : ( List Button, List Button ) -> ( Set String, Set String )
toStringSetControls =
    Tuple.mapBoth buttonListToStringSet buttonListToStringSet


buttonListToStringSet : List Button -> Set String
buttonListToStringSet =
    List.map buttonToString >> Set.fromList
