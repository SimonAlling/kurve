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
import WebGL


type alias Model =
    Float


type alias Msg =
    Float


main : Program () Model Msg
main =
    Browser.element
        { init = \_ -> ( 0, Cmd.none )
        , view = view
        , subscriptions = \_ -> onAnimationFrameDelta Basics.identity
        , update = \elapsed currentTime -> ( elapsed + currentTime, Cmd.none )
        }


view : Model -> Html Msg
view t =
    WebGL.toHtml
        [ width 559
        , height 480
        , style "display" "block"
        ]
        [ Rectangle.view Color.red ( 100 + round (t / 8), 100 )
        ]
