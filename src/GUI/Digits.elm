module GUI.Digits exposing (TextProps, large, small)

import Color exposing (Color)
import GUI.Font exposing (Font(..))
import Html exposing (Html, div)
import Html.Attributes as Attr


large : Color -> Int -> List (Html msg)
large color =
    digits { font = GUI.Font.bgiStroked28x43, color = color, sizeMultiplier = 1 }


small : Color -> Int -> List (Html msg)
small color =
    digits { font = GUI.Font.bgiDefault8x8, color = color, sizeMultiplier = 2 }


digits : TextProps -> Int -> List (Html msg)
digits textProps =
    String.fromInt >> text textProps


type alias TextProps =
    { font : Font, sizeMultiplier : Int, color : Color }


text : TextProps -> String -> List (Html msg)
text textProps =
    String.toList >> List.map (char textProps)


char : TextProps -> Char -> Html msg
char { font, sizeMultiplier, color } c =
    let
        (Font fontProperties) =
            font

        scaledFontWidth =
            fontProperties.width * sizeMultiplier

        scaledFontHeight =
            fontProperties.height * sizeMultiplier

        cssSize n =
            String.fromInt n ++ "px"

        maskImage : String
        maskImage =
            "url(\"../resources/fonts/" ++ fontProperties.resourceName ++ ".png\")"

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
