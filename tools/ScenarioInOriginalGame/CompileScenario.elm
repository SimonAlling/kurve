module CompileScenario exposing (CompilationResult(..), compileAndSerialize, compileScenario)

import GDB
import Json.Encode as Encode
import OriginalGamePlayers exposing (PlayerId, playerIndex)
import ScenarioCore exposing (Scenario, checkScenario, toModMem)
import TheScenario exposing (theScenario)


type CompilationResult
    = CompilationSuccess CompiledScenario
    | CompilationFailure String


type alias CompiledScenario =
    { participating : List PlayerId
    , compiledProgram : String
    }


compileAndSerialize : List String -> String
compileAndSerialize commandLineArgs =
    compileScenario commandLineArgs theScenario |> encodeCompilationResultAsJson |> Encode.encode 0


compileScenario : List String -> Scenario -> CompilationResult
compileScenario commandLineArgs scenario =
    case parseArguments commandLineArgs of
        Accepted baseAddressPlaceholder ->
            case checkScenario scenario of
                Ok checkedScenario ->
                    CompilationSuccess
                        { participating = participatingPlayers scenario
                        , compiledProgram = checkedScenario |> toModMem |> GDB.compile baseAddressPlaceholder
                        }

                Err reason ->
                    CompilationFailure reason

        Rejected reason ->
            CompilationFailure reason


type ParsedArguments
    = Accepted GDB.BaseAddressPlaceholder
    | Rejected String


parseArguments : List String -> ParsedArguments
parseArguments commandLineArgs =
    case commandLineArgs of
        [ rawBaseAddressPlaceholder ] ->
            if not (String.isEmpty (String.trim rawBaseAddressPlaceholder)) then
                Accepted (GDB.BaseAddressPlaceholder rawBaseAddressPlaceholder)

            else
                Rejected "Base address placeholder cannot be empty or consist only of whitespace."

        _ ->
            Rejected <| "Unexpected number of arguments. Expected 1, but got " ++ (List.length commandLineArgs |> String.fromInt) ++ "."


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
                        , ( "gdbProgramWithBaseAddressPlaceholder", Encode.string compiledProgram )
                        ]
                  )
                ]

        CompilationFailure errorMessage ->
            Encode.object
                [ ( "compilationSuccess", Encode.bool False )
                , ( "compilationErrorMessage", Encode.string errorMessage )
                ]


participatingPlayers : Scenario -> List PlayerId
participatingPlayers =
    List.map Tuple.first
