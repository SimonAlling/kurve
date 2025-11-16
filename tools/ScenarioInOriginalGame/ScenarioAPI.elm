port module ScenarioAPI exposing (main)

import CompileScenario exposing (commandLineWrapper)
import Platform


type alias Flags =
    { elmFlag_commandLineArgs : List String
    }


port outputToOutsideWorld : String -> Cmd msg


type alias Model =
    ()


type alias Msg =
    Never


main : Program Flags Model Msg
main =
    Platform.worker
        { init = init
        , update = update
        , subscriptions = \_ -> Sub.none
        }


init : Flags -> ( Model, Cmd Msg )
init { elmFlag_commandLineArgs } =
    ( (), commandLineWrapper elmFlag_commandLineArgs |> outputToOutsideWorld )


update : Msg -> Model -> ( Model, Cmd Msg )
update _ model =
    ( model, Cmd.none )
