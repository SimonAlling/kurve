module CompileScenario exposing (CompilationResult(..), compileScenario)

import ModMem exposing (AbsoluteAddress, parseAddress)
import OriginalGamePlayers exposing (PlayerId)
import Scanmem
import ScenarioCore exposing (Scenario, toModMem)


type CompilationResult
    = CompilationSuccess CompiledScenario
    | CompilationFailure String


type alias CompiledScenario =
    { participating : List PlayerId
    , compiledProgram : String
    }


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
                    Rejected <| "Cannot parse base address: " ++ rawBaseAddress ++ " (must be hexadecimal, with or without '0x' prefix)"

        _ ->
            Rejected <| "Unexpected number of arguments. Expected 1, but got " ++ (List.length commandLineArgs |> String.fromInt) ++ "."


participatingPlayers : Scenario -> List PlayerId
participatingPlayers =
    List.map Tuple.first
