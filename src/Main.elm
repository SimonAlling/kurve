port module Main exposing (main)

import Browser
import Html exposing (Html, canvas, div)
import Html.Attributes as Attr
import Time


port render : List { position : DrawingPosition, thickness : Int, color : String } -> Cmd msg


type alias DrawingPosition =
    { leftEdge : Int, topEdge : Int }


type alias Model =
    { x : Float
    , y : Float
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { x = 0, y = 100 }
    , Cmd.none
    )


type Msg
    = GameTick


tickrate : number
tickrate =
    60


speed : number
speed =
    -- px per second
    180


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( { x = model.x + (speed / tickrate), y = model.y }
    , render [ { position = { leftEdge = round model.x, topEdge = round model.y }, thickness = 5, color = "white" } ]
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    Time.every (1000 / tickrate) (always GameTick)


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
