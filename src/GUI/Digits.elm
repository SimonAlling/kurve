module GUI.Digits exposing (large, small)

import Color exposing (Color)
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


digits : Size -> Color -> Int -> List (Html msg)
digits _ color =
    String.fromInt >> text color


text : Color -> String -> List (Html msg)
text color =
    String.toList >> List.map (char color)


char : Color -> Char -> Html msg
char color c =
    let
        width =
            8

        size =
            String.fromInt width ++ "px"

        maskPosition : String
        maskPosition =
            String.fromInt (Char.toCode c * width * -1) ++ "px 0"
    in
    div
        [ Attr.class "character"
        , Attr.style "background-color" <| Color.toCssString color
        , Attr.style "-webkit-mask-position" maskPosition
        , Attr.style "mask-position" maskPosition
        , Attr.style "width" size
        , Attr.style "height" size
        ]
        []



-- fontToString : Font -> String
-- fontToString f =
--     case f of
--         BGIDefault8x8 ->
--             "bgi-default-8x8"
-- type Font
--     = BGIDefault8x8
-- digit : Size -> Color -> Digit -> Html msg
-- digit size color (Digit n) =
--     let
--         ( class, width ) =
--             case size of
--                 Large ->
--                     ( "largeDigit", 28 )
--                 Small ->
--                     ( "smallDigit", 16 )
--         maskPosition : String
--         maskPosition =
--             String.fromInt (n * width * -1) ++ "px 0"
--     in
--     div
--         [ Attr.class class
--         , Attr.style "background-color" <| Color.toCssString color
--         , Attr.style "-webkit-mask-position" maskPosition
--         , Attr.style "mask-position" maskPosition
--         ]
--         []
