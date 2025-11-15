port module ScenarioAPI exposing (main)

import CompileScenario exposing (CompilationResult(..), compileScenario)
import Json.Encode as Encode
import OriginalGamePlayers exposing (playerIndex)
import Platform
import TheScenario exposing (theScenario)


type alias Flags =
    { elmFlag_baseAddress : String
    }


port outputToOutsideWorld : Encode.Value -> Cmd msg


type alias Msg =
    Never


main : Program Flags () Msg
main =
    Platform.worker
        { init = init
        , update = update
        , subscriptions = \_ -> Sub.none
        }


init : Flags -> ( (), Cmd Msg )
init { elmFlag_baseAddress } =
    ( (), compileScenario elmFlag_baseAddress theScenario |> encodeCompilationResultAsJson |> outputToOutsideWorld )


update : Msg -> () -> ( (), Cmd Msg )
update _ model =
    ( model, Cmd.none )


{-| This is the external API.

The keys are deliberately long to make them unique and therefore searchable.

-}
encodeCompilationResultAsJson : CompilationResult -> Encode.Value
encodeCompilationResultAsJson result =
    case result of
        CompilationSuccess { participating, compiledProgram } ->
            Encode.object
                [ ( "compilationSuccess", Encode.bool True )
                , ( "compiledScenario"
                  , Encode.object
                        [ ( "participatingPlayersById", Encode.list Encode.int (List.map playerIndex participating) )
                        , ( "scanmemProgram", Encode.string compiledProgram )
                        ]
                  )
                ]

        CompilationFailure errorMessage ->
            Encode.object
                [ ( "compilationSuccess", Encode.bool False )
                , ( "compilationErrorMessage", Encode.string errorMessage )
                ]
