module GUI.Digits exposing (large, small)

import Color exposing (Color)
import GUI.Fonts exposing (Font(..))
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


type ScaledFont
    = Scaled Int Font


digits : Size -> Color -> Int -> List (Html msg)
digits size color =
    let
        fontAndSize =
            case size of
                Large ->
                    Scaled 1 GUI.Fonts.bgiStroked28x43

                Small ->
                    Scaled 2 GUI.Fonts.bgiDefault8x8
    in
    String.fromInt >> text fontAndSize color


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
