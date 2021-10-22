port module Main exposing (main)

import Platform exposing (worker)
import Time


port myPort : Int -> Cmd msg


tickrate : Float
tickrate =
    60


type alias Model =
    { x : Int
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { x = 0 }, Cmd.none )


type Msg
    = Msg Int


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Msg _ ->
            let
                newX =
                    model.x + 1
            in
            ( { model | x = newX }, myPort newX )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Time.every (1000 / tickrate) (Time.posixToMillis >> Msg)


main =
    worker
        { init = init
        , update = update
        , subscriptions = subscriptions
        }
