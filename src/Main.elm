port module Main exposing (main)

import Browser
import Html exposing (Html, canvas, div)
import Html.Attributes as Attr
import Time


port render : List { position : DrawingPosition, thickness : Int, color : String } -> Cmd msg


port clear : { x : Int, y : Int, width : Int, height : Int } -> Cmd msg


type alias DrawingPosition =
    { leftEdge : Int, topEdge : Int }


type alias Model =
    {}


init : () -> ( Model, Cmd Msg )
init _ =
    ( {}
    , Cmd.none
    )


type Msg
    = GameTick


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.batch <| [ clear { x = 0, y = 0, width = 1000, height = 1000 }, render [] ] )


subscriptions : Model -> Sub Msg
subscriptions model =
    Time.every (1000 / 60) (always GameTick)


view : Model -> Html Msg
view model =
    elmRoot
        []
        [ canvas
            [ Attr.id "canvas_main"
            , Attr.width 559
            , Attr.height 480
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
