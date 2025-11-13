module CompileScenario exposing (CompilationResult(..), compileScenario)

import ModMem exposing (parseAddress)
import OriginalGamePlayers exposing (PlayerId)
import Scanmem
import ScenarioCore exposing (Scenario, toModMem)


type CompilationResult
    = CompilationSuccess
        { participating : List PlayerId
        , compiledProgram : String
        }
    | CompilationFailure String


compileScenario : String -> Scenario -> CompilationResult
compileScenario rawBaseAddress scenario =
    case parseAddress rawBaseAddress of
        Just baseAddress ->
            CompilationSuccess
                { participating = participatingPlayers scenario
                , compiledProgram = scenario |> toModMem |> Scanmem.compile baseAddress
                }

        Nothing ->
            CompilationFailure ("Invalid base address: " ++ rawBaseAddress)


participatingPlayers : Scenario -> List PlayerId
participatingPlayers =
    List.map Tuple.first
