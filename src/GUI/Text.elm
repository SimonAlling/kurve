module GUI.Text exposing (ScaledFont(..), string)

import Color exposing (Color)
import GUI.Fonts exposing (Font(..))
import Html exposing (Html, div)
import Html.Attributes as Attr


type ScaledFont
    = Scaled Int Font


string : ScaledFont -> Color -> String -> List (Html msg)
string fontAndSize color =
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
