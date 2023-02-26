module GUI.Digits exposing (large, small)

import Color exposing (Color)
import GUI.Text as Text
import Html exposing (Html, div)
import Html.Attributes as Attr


type Size
    = Large
    | Small


large : Color -> Int -> List (Html msg)
large =
    digits Large


small : Color -> Int -> List (Html msg)
small =
    digits Small


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
    case size of
        Large ->
            digitsFromInt >> List.map (digit color)

        Small ->
            String.fromInt >> Text.string (Text.Size 2) color


digit : Color -> Digit -> Html msg
digit color (Digit n) =
    let
        ( class, width ) =
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
