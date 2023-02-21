module GUI.Text exposing (string)

import Color exposing (Color)
import GUI.Fonts exposing (Font(..))
import Html exposing (Html, img, span)
import Html.Attributes as Attr


string : Font -> Int -> Color -> String -> List (Html msg)
string font sizeMultiplier color =
    String.toList >> List.map (char font sizeMultiplier color)


char : Font -> Int -> Color -> Char -> Html msg
char font sizeMultiplier color c =
    let
        cssSize : Int -> String
        cssSize n =
            String.fromInt n ++ "px"
    in
    case font of
        BGIDefault ->
            let
                scaledFontWidth : Int
                scaledFontWidth =
                    8 * sizeMultiplier

                scaledFontHeight : Int
                scaledFontHeight =
                    8 * sizeMultiplier

                maskImage : String
                maskImage =
                    "url(\"../resources/fonts/bgi-default-8x8.png\")"

                maskPosition : String
                maskPosition =
                    String.fromInt (Char.toCode c * scaledFontWidth * -1) ++ "px 0"
            in
            span
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

        BGIStroked ->
            let
                theGlyphUrl : String
                theGlyphUrl =
                    glyphUrl c

                maskImage : String
                maskImage =
                    "url(\"" ++ theGlyphUrl ++ "\")"
            in
            span
                [ Attr.class "character"
                , Attr.style "background-color" <| Color.toCssString color
                , Attr.style "-webkit-mask-image" maskImage
                , Attr.style "mask-image" maskImage
                , Attr.style "height" (cssSize 65)
                ]
                [ img
                    [ Attr.style "opacity" "0"
                    , Attr.src theGlyphUrl
                    ]
                    []
                ]


glyphUrl : Char -> String
glyphUrl c =
    "data:image/png;base64," ++ glyphData c


glyphData : Char -> String
glyphData c =
    case c of
        'H' ->
            "iVBORw0KGgoAAAANSUhEUgAAACgAAABBAQMAAACZy3S8AAAABlBMVEUgICAAAADDODzDAAAAAXRSTlMAQObYZgAAAGpJREFUGFdjYCAV1P+R/8/AwPuAuYKBgb2B8QEDA38DM4hkYD7AwMDNwAQnxRhYG3CTOkBVuMkIoCpUsv7/PyC5ASiPk2RMAKrFSQKdtAEbydoAlEchId6CsCGekz7A9oGB4f8Pe5AbqA8AIPEqUB5VY/IAAAAASUVORK5CYII="

        '/' ->
            "iVBORw0KGgoAAAANSUhEUgAAACkAAABBAQMAAAB2CR+CAAAABlBMVEUgICAAAADDODzDAAAAAXRSTlMAQObYZgAAADJJREFUGNNjYAACxgYQycDMgEyxoVA8EEoChTJAoRIg1AFkiuYmo1pAZ5N5CJucQB+TAWJ5D+6/N2n+AAAAAElFTkSuQmCC"

        _ ->
            ""
