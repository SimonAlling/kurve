module GUI.Text exposing
    ( Size(..)
    , string
    )

import Color exposing (Color)
import Html exposing (Html, span)
import Html.Attributes as Attr


type Size
    = Size Int


string : Size -> Color -> String -> List (Html msg)
string size color =
    String.toList >> List.map (char size color)


char : Size -> Color -> Char -> Html msg
char (Size multiplier) color c =
    let
        scaledFontHeight : Int
        scaledFontHeight =
            8 * multiplier

        scaledFontWidth : Int
        scaledFontWidth =
            8 * multiplier

        maskPosition : String
        maskPosition =
            cssSize (Char.toCode c * scaledFontWidth * -1)
    in
    span
        [ Attr.class "character"
        , Attr.style "background-color" (Color.toCssString color)
        , Attr.style "-webkit-mask-position" maskPosition
        , Attr.style "mask-position" maskPosition
        , Attr.style "width" (cssSize scaledFontWidth)
        , Attr.style "height" (cssSize scaledFontHeight)
        ]
        []


cssSize : Int -> String
cssSize n =
    String.fromInt n ++ "px"
