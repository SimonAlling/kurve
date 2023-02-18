module GUI.Digits exposing (large, small)

import Color exposing (Color)
import Html exposing (Html, div)
import Html.Attributes as Attr


large : Color -> Int -> List (Html msg)
large color =
    digits { font = DenStora, color = color, sizeMultiplier = 1 }


small : Color -> Int -> List (Html msg)
small color =
    digits { font = BGIDefault8x8, color = color, sizeMultiplier = 2 }


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
        theFontProps =
            fontProps font

        scaledFontWidth =
            theFontProps.width * sizeMultiplier

        scaledFontHeight =
            theFontProps.height * sizeMultiplier

        cssSize n =
            String.fromInt n ++ "px"

        maskImage : String
        maskImage =
            "url(\"../resources/fonts/" ++ theFontProps.resourceName ++ ".png\")"

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


type alias FontProps =
    { width : Int, height : Int, resourceName : String }


fontProps : Font -> FontProps
fontProps f =
    case f of
        BGIDefault8x8 ->
            { width = 8, height = 8, resourceName = "bgi-default-8x8" }

        DenStora ->
            { width = 28, height = 43, resourceName = "bgi-stroked" }


type Font
    = BGIDefault8x8
    | DenStora



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
