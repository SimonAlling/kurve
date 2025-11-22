module GDB exposing (compile)

import MemoryLayout exposing (StateComponent(..), relativeAddressFor)
import ModMem exposing (AbsoluteAddress, ModMemCmd(..), resolveAddress, serializeAddress)
import OriginalGamePlayers exposing (PlayerId(..))
import ScenarioComments exposing (ignoreBogusWriteComment)


type alias GdbCommand =
    String


compile : AbsoluteAddress -> List ModMemCmd -> String
compile baseAddress core =
    let
        coreCommands : List GdbCommand
        coreCommands =
            compileCore baseAddress core
    in
    List.concat
        [ setupCommands
        , coreCommands
        , teardownCommands
        ]
        |> String.join "\n"


compileCore : AbsoluteAddress -> List ModMemCmd -> List GdbCommand
compileCore baseAddress =
    let
        whatToDoAfterHittingLastWatchpoint : List GdbCommand
        whatToDoAfterHittingLastWatchpoint =
            [ "exit" -- Otherwise gdb remains attached until DOSBox is closed. See the PR/commit that added this comment for details about why that's problematic.
            ]
    in
    List.foldr
        (\(ModifyMemory description relativeAddress newValue) compiledContinuation ->
            let
                serializedAddress : String
                serializedAddress =
                    resolveAddress baseAddress relativeAddress |> serializeAddress

                applyWorkaroundForRedYIfApplicable : List GdbCommand -> List GdbCommand
                applyWorkaroundForRedYIfApplicable =
                    if relativeAddress == relativeAddressFor Red Y then
                        applyWorkaroundForRedY serializedAddress

                    else
                        identity
            in
            [ emptyLineForVisualSeparation
            , makeComment description
            , "watch *(float*)" ++ serializedAddress
            , "commands"
            , "set {float}" ++ serializedAddress ++ " = " ++ String.fromFloat newValue
            , "delete $bpnum"
            ]
                ++ compiledContinuation
                ++ closeWatchBlock
                |> applyWorkaroundForRedYIfApplicable
        )
        whatToDoAfterHittingLastWatchpoint


setupCommands : List GdbCommand
setupCommands =
    [ "set pagination off"
    , "set logging file gdb-log.txt"
    , "set logging overwrite on" -- Otherwise gdb appends to the log file, instead of overwriting it.
    , "set logging enabled on" -- Must be after the other `set logging` commands for them to have effect.
    ]


teardownCommands : List GdbCommand
teardownCommands =
    [ "continue"
    ]


{-| The original game writes a couple of times to Red's y address before writing the actual value. We have to wait for the "real" write before we write our value; otherwise it's just immediately overwritten.
-}
applyWorkaroundForRedY : String -> List GdbCommand -> List GdbCommand
applyWorkaroundForRedY serializedAddress compiledGdbCommands =
    let
        numberOfBogusWritesToRedYAddress : Int
        numberOfBogusWritesToRedYAddress =
            2

        ignoreBogusWrite : List GdbCommand
        ignoreBogusWrite =
            [ emptyLineForVisualSeparation
            , makeComment (ignoreBogusWriteComment Y Red)
            , "watch *(float*)" ++ serializedAddress
            , "commands"
            , "x/4bx " ++ serializedAddress -- (just print the bytes)
            , "delete $bpnum"
            ]

        workaroundOpening : List GdbCommand
        workaroundOpening =
            ignoreBogusWrite |> List.repeat numberOfBogusWritesToRedYAddress |> List.concat

        workaroundClosing : List GdbCommand
        workaroundClosing =
            closeWatchBlock |> List.repeat numberOfBogusWritesToRedYAddress |> List.concat
    in
    workaroundOpening ++ compiledGdbCommands ++ workaroundClosing


emptyLineForVisualSeparation : String
emptyLineForVisualSeparation =
    ""


closeWatchBlock : List GdbCommand
closeWatchBlock =
    [ "continue"
    , "end"
    , emptyLineForVisualSeparation
    ]


makeComment : String -> GdbCommand
makeComment =
    String.append "# "
