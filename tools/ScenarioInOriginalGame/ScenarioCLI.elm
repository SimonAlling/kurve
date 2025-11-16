port module ScenarioCLI exposing (main)

import CompileScenario exposing (commandLineWrapper)
import Platform


port outputToOutsideWorld : String -> Cmd msg


type alias Flags =
    { elmFlag_commandLineArgs : List String
    }


type alias Model =
    ()


type alias Msg =
    Never


main : Program Flags Model Msg
main =
    Platform.worker
        { init = init
        , update = never
        , subscriptions = always Sub.none
        }


init : Flags -> ( Model, Cmd Msg )
init { elmFlag_commandLineArgs } =
    ( (), commandLineWrapper elmFlag_commandLineArgs |> outputToOutsideWorld )
