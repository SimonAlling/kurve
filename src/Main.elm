module Main exposing (main)

import Platform exposing (worker)


type alias Model =
    { ett : Int
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { ett = 5555555 }, Cmd.none )


type Msg
    = Msg Int


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Msg _ ->
            ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none


main =
    worker
        { init = init
        , update = update
        , subscriptions = subscriptions
        }
