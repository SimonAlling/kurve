module Input exposing (Button(..), ButtonDirection(..), buttonsWithSpecialMeaning, toStringSetControls, updatePressedButtons)

import Set exposing (Set)


{-| Buttons that are used in the game for things other than controlling players. Please DRY up.
-}
buttonsWithSpecialMeaning : List Button
buttonsWithSpecialMeaning =
    [ Key "ArrowLeft"
    , Key "ArrowRight"
    , Key "Enter"
    , Key "Escape"
    , Key "KeyE"
    , Key "KeyO"
    , Key "KeyR"
    , Key "Space"
    , Key "Tab"
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


toStringSetControls : ( List Button, List Button ) -> ( Set String, Set String )
toStringSetControls =
    Tuple.mapBoth buttonListToStringSet buttonListToStringSet


buttonListToStringSet : List Button -> Set String
buttonListToStringSet =
    List.map buttonToString >> Set.fromList
