module CompileScenario exposing (CompilationResult(..), compileAndSerialize, compileScenario)

import Json.Encode as Encode
import ModMem exposing (AbsoluteAddress, parseAddress)
import OriginalGamePlayers exposing (PlayerId, playerIndex)
import Scanmem
import ScenarioCore exposing (Scenario, toModMem)
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
        Accepted baseAddress ->
            CompilationSuccess
                { participating = participatingPlayers scenario
                , compiledProgram = scenario |> toModMem |> Scanmem.compile baseAddress
                }

        Rejected reason ->
            CompilationFailure reason


type ParsedArguments
    = Accepted AbsoluteAddress
    | Rejected String


parseArguments : List String -> ParsedArguments
parseArguments commandLineArgs =
    case commandLineArgs of
        [ rawBaseAddress ] ->
            case parseAddress rawBaseAddress of
                Just baseAddress ->
                    Accepted baseAddress

                Nothing ->
                    Rejected <| "Cannot parse base address: " ++ rawBaseAddress ++ " (must be hexadecimal, with or without '0x' prefix)."

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
                        , ( "scanmemProgram", Encode.string compiledProgram )
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
