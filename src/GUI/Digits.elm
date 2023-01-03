module GUI.Digits exposing (large)

import Color exposing (Color)
import Html exposing (Html, div)
import Html.Attributes as Attr


type Size
    = Large


large : Color -> Int -> List (Html msg)
large =
    digits Large


type Digit
    = Digit Int


fromChar : Char -> Maybe Digit
fromChar =
    String.fromChar >> String.toInt >> Maybe.map Digit


digitsFromInt : Int -> List Digit
digitsFromInt =
    String.fromInt >> String.toList >> List.filterMap fromChar


digits : Size -> Color -> Int -> List (Html msg)
digits size color =
    digitsFromInt >> List.map (digit size color)


digit : Size -> Color -> Digit -> Html msg
digit size color (Digit n) =
    let
        ( class, width ) =
            case size of
                Large ->
                    ( "largeDigit", 28 )

        maskPosition : String
        maskPosition =
            String.fromInt (n * width * -1) ++ "px 0"
    in
    div
        [ Attr.class class
        , Attr.style "background-color" <| Color.toCssString color
        , Attr.style "-webkit-mask-position" maskPosition
        , Attr.style "mask-position" maskPosition
        ]
        []
