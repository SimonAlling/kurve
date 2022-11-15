port module Input exposing (Button(..), ButtonDirection(..), inputSubscriptions, stringToButton, toStringSetControls, updatePressedButtons)

import Set exposing (Set)


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


{-| Designed to decode values encoded by `buttonToString`, nothing else.
-}
stringToButton : String -> Maybe Button
stringToButton string =
    case String.toList string of
        'M' :: 'o' :: 'u' :: 's' :: 'e' :: rest ->
            rest |> String.fromList |> String.toInt |> Maybe.map Mouse

        _ ->
            string |> Key |> Just


toStringSetControls : ( List Button, List Button ) -> ( Set String, Set String )
toStringSetControls =
    Tuple.mapBoth buttonListToStringSet buttonListToStringSet


buttonListToStringSet : List Button -> Set String
buttonListToStringSet =
    List.map buttonToString >> Set.fromList
