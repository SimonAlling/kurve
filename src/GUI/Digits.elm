module GUI.Digits exposing (large, small)

import Color exposing (Color)
import GUI.Fonts
import GUI.Text
import Html exposing (Html)


type Size
    = Large
    | Small


large : Color -> Int -> List (Html msg)
large =
    digits Large


small : Color -> Int -> List (Html msg)
small =
    digits Small


digits : Size -> Color -> Int -> List (Html msg)
digits size color =
    let
        ( font, sizeMultiplier ) =
            case size of
                Large ->
                    ( GUI.Fonts.bgiStroked28x43, 1 )

                Small ->
                    ( GUI.Fonts.bgiDefault8x8, 2 )
    in
    String.fromInt >> GUI.Text.string font sizeMultiplier color
