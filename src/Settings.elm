module Settings exposing (SettingId(..), Settings, default, parse, stringify, trueOriginalExperience)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


type SettingId
    = SpawnProtection
    | PersistHoleStatus
    | ReplicateTruncationBug
    | EnableAlternativeControls


type alias Settings =
    { spawnkillProtection : Bool
    , persistHoleStatus : Bool
    , replicateTruncationBug : Bool
    , enableAlternativeControls : Bool
    }


default : Settings
default =
    { spawnkillProtection = True
    , persistHoleStatus = False
    , replicateTruncationBug = False
    , enableAlternativeControls = True
    }


trueOriginalExperience : Settings
trueOriginalExperience =
    { spawnkillProtection = False
    , persistHoleStatus = True
    , replicateTruncationBug = True
    , enableAlternativeControls = False
    }


parse : Maybe String -> Settings
parse maybeRawString =
    case maybeRawString of
        Nothing ->
            default

        Just rawString ->
            Decode.decodeString settingsDecoder rawString
                |> Result.withDefault default


stringify : Settings -> String
stringify settings =
    Encode.encode 2 (settingsEncoder settings)


settingsDecoder : Decoder Settings
settingsDecoder =
    Decode.map4
        Settings
        (Decode.maybe (Decode.field "spawnkillProtectionSetting" Decode.bool) |> Decode.map (Maybe.withDefault default.spawnkillProtection))
        (Decode.maybe (Decode.field "persistHoleStatusSetting" Decode.bool) |> Decode.map (Maybe.withDefault default.persistHoleStatus))
        (Decode.maybe (Decode.field "replicateTruncationBugSetting" Decode.bool) |> Decode.map (Maybe.withDefault default.replicateTruncationBug))
        (Decode.maybe (Decode.field "enableAlternativeControlsSetting" Decode.bool) |> Decode.map (Maybe.withDefault default.enableAlternativeControls))


settingsEncoder : Settings -> Encode.Value
settingsEncoder settings =
    Encode.object
        [ ( "spawnkillProtectionSetting", Encode.bool settings.spawnkillProtection )
        , ( "persistHoleStatusSetting", Encode.bool settings.persistHoleStatus )
        , ( "replicateTruncationBugSetting", Encode.bool settings.replicateTruncationBug )
        , ( "enableAlternativeControlsSetting", Encode.bool settings.enableAlternativeControls )
        ]
