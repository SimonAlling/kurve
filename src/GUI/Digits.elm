module GUI.Digits exposing (large, small)

import Color exposing (Color)
import GUI.Fonts exposing (Font(..))
import GUI.Text exposing (ScaledFont(..))
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
        scaledFont =
            case size of
                Large ->
                    Scaled 1 GUI.Fonts.bgiStroked28x43

                Small ->
                    Scaled 2 GUI.Fonts.bgiDefault8x8
    in
    String.fromInt >> GUI.Text.string scaledFont color
