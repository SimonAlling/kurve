module GUI.Digits exposing (large, small)

import Color exposing (Color)
import GUI.Font exposing (Font(..))
import Html exposing (Html, div)
import Html.Attributes as Attr


large : Color -> Int -> List (Html msg)
large =
    digits (Scaled 1 GUI.Font.bgiStroked28x43)


small : Color -> Int -> List (Html msg)
small =
    digits (Scaled 2 GUI.Font.bgiDefault8x8)


digits : ScaledFont -> Color -> Int -> List (Html msg)
digits fontAndSize color =
    String.fromInt >> text fontAndSize color


type ScaledFont
    = Scaled Int Font


text : ScaledFont -> Color -> String -> List (Html msg)
text fontAndSize color =
    String.toList >> List.map (char fontAndSize color)


char : ScaledFont -> Color -> Char -> Html msg
char (Scaled sizeMultiplier (Font font)) color c =
    let
        scaledFontWidth =
            font.width * sizeMultiplier

        scaledFontHeight =
            font.height * sizeMultiplier

        cssSize n =
            String.fromInt n ++ "px"

        maskImage : String
        maskImage =
            "url(\"../resources/fonts/" ++ font.resourceName ++ ".png\")"

        maskPosition : String
        maskPosition =
            String.fromInt (Char.toCode c * scaledFontWidth * -1) ++ "px 0"
    in
    div
        [ Attr.class "character"
        , Attr.style "background-color" <| Color.toCssString color
        , Attr.style "-webkit-mask-image" maskImage
        , Attr.style "mask-image" maskImage
        , Attr.style "-webkit-mask-position" maskPosition
        , Attr.style "mask-position" maskPosition
        , Attr.style "width" (cssSize scaledFontWidth)
        , Attr.style "height" (cssSize scaledFontHeight)
        ]
        []



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
