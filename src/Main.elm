port module Main exposing (main)

import Browser
import Browser.Events exposing (onAnimationFrame, onAnimationFrameDelta)
import Html exposing (Html, canvas, div)
import Html.Attributes as Attr
import Time


port render : List { position : DrawingPosition, thickness : Int, color : String } -> Cmd msg


type alias DrawingPosition =
    { leftEdge : Int, topEdge : Int }


type alias Model =
    { currentState : { x : Float, y : Float }
    , previousState : { x : Float, y : Float }
    , previousTime : Time.Posix
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { currentState = { x = 0, y = 100 }
      , previousState = { x = 0, y = 100 }
      , previousTime = Time.millisToPosix 0
      }
    , Cmd.none
    )


type Msg
    = GameTick Time.Posix


tickrate : number
tickrate =
    60


speed : number
speed =
    -- px per second
    180


update : Msg -> Model -> ( Model, Cmd Msg )
update (GameTick newTime) model =
    let
        frameTime =
            Time.posixToMillis newTime - Time.posixToMillis model.previousTime
    in
    ( { currentState = { x = model.currentState.x + (speed / tickrate), y = model.currentState.y }
      , previousState = model.currentState
      , previousTime = newTime
      }
    , render [ { position = { leftEdge = round model.currentState.x, topEdge = round model.currentState.y }, thickness = 5, color = "white" } ]
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    Time.every (1 / tickrate) GameTick


view : Model -> Html Msg
view model =
    elmRoot
        []
        [ canvas
            [ Attr.id "canvas_main"
            , Attr.width 1920
            , Attr.height 480
            , Attr.style "background" "black"
            ]
            []
        ]


elmRoot : List (Html.Attribute msg) -> List (Html msg) -> Html msg
elmRoot attrs =
    div (Attr.id "elm-root" :: attrs)


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }
