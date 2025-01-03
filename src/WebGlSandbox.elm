module WebGlSandbox exposing (..)

{-
   Rotating triangle, that is a "hello world" of the WebGL
-}

import Browser
import Browser.Events exposing (onAnimationFrameDelta)
import Color
import Html exposing (Html)
import Html.Attributes exposing (height, style, width)
import Rectangle
import Svg
import Svg.Attributes
import WebGL


type alias Model =
    Int


type alias Msg =
    Int


main : Program () Model Msg
main =
    Browser.element
        { init = \_ -> ( 0, Cmd.none )
        , view = view
        , subscriptions = \_ -> onAnimationFrameDelta (always 1)
        , update = \elapsed currentTime -> ( elapsed + currentTime, Cmd.none )
        }


view : Model -> Html Msg
view t =
    let
        pos =
            ( t, 5 )

        d =
            pos
                |> (\( x, y ) ->
                        "M" ++ String.fromInt x ++ "," ++ String.fromInt y ++ "h3v3h-3"
                   )
    in
    Svg.svg
        [ width 559
        , height 480
        , style "display" "block"
        ]
        [ Svg.path [ Svg.Attributes.d d, Svg.Attributes.fill "black" ] [] ]
