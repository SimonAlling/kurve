port module Main exposing (main)

import Browser
import Html exposing (Html, canvas, div)
import Html.Attributes as Attr
import Time


port render : List { position : DrawingPosition, color : String } -> Cmd msg


type alias DrawingPosition =
    ()


type alias State =
    ()


type alias Model =
    { currentState : State
    , previousState : State
    , currentTime : Float
    , accumulator : Float
    , stateToRender : State
    }


init : () -> ( Model, Cmd Msg )
init _ =
    let
        initState =
            ()
    in
    ( { currentState = initState
      , previousState = initState
      , currentTime = 0
      , accumulator = 0
      , stateToRender = initState
      }
    , Cmd.none
    )


type Msg
    = GameTick


tickrate : number
tickrate =
    60


dt : Float
dt =
    0.01


update : Msg -> Model -> ( Model, Cmd Msg )
update _ { currentState, previousState, currentTime, accumulator } =
    let
        -- State state = currentState * alpha +
        --     previousState * ( 1.0 - alpha );
        stateToRender =
            currentState
    in
    ( { currentState = currentState
      , previousState = previousState
      , currentTime = currentTime
      , accumulator = accumulator
      , stateToRender = stateToRender
      }
    , Cmd.none
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    Time.every (1 / tickrate) (always GameTick)


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
