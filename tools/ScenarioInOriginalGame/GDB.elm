module GDB exposing (compile)

import MemoryLayout exposing (StateComponent(..), relativeAddressFor)
import ModMem exposing (AbsoluteAddress, ModMemCmd(..), resolveAddress, serializeAddress)
import OriginalGamePlayers exposing (PlayerId(..))


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
        whatToDoAfterSettingLastWatchpoint : List GdbCommand
        whatToDoAfterSettingLastWatchpoint =
            [ "exit" -- Otherwise gdb remains attached until DOSBox is closed. See the PR/commit that added this comment for details about why that's problematic.
            ]
    in
    List.foldr
        (\(ModifyMemory relativeAddress newValue) compiledContinuation ->
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
            , "watch *(float*)" ++ serializedAddress
            , "commands"
            , "set {float}" ++ serializedAddress ++ " = " ++ String.fromFloat newValue
            , "delete $bpnum"
            ]
                ++ compiledContinuation
                ++ closeWatchBlock
                |> applyWorkaroundForRedYIfApplicable
        )
        whatToDoAfterSettingLastWatchpoint


setupCommands : List GdbCommand
setupCommands =
    [ "set pagination off"
    , "set logging off"
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
