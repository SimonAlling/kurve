module Scanmem exposing (compile)

import ModMem exposing (AbsoluteAddress, ModMemCmd(..), resolveAddress, serializeAddress)


type alias ScanmemCommand =
    String


compile : AbsoluteAddress -> List ModMemCmd -> String
compile baseAddress core =
    let
        coreCommands : List ScanmemCommand
        coreCommands =
            compileCore baseAddress core
    in
    List.concat
        [ setupCommands
        , coreCommands
        , teardownCommands
        ]
        |> String.join ";"


compileCore : AbsoluteAddress -> List ModMemCmd -> List ScanmemCommand
compileCore baseAddress =
    List.map
        (\(ModifyMemory relativeAddress newValue) ->
            let
                serializedAddress : String
                serializedAddress =
                    resolveAddress baseAddress relativeAddress |> serializeAddress
            in
            "write float32 " ++ serializedAddress ++ " " ++ String.fromFloat newValue
        )


setupCommands : List ScanmemCommand
setupCommands =
    [ "option endianness 1"
    ]


teardownCommands : List ScanmemCommand
teardownCommands =
    [ "exit"
    ]
