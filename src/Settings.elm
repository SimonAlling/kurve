module Settings exposing (SettingId(..), Settings, default, parse, stringify)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


type SettingId
    = SpawnProtection


type alias Settings =
    { spawnkillProtection : Bool
    }


default : Settings
default =
    { spawnkillProtection = True
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
    Decode.map
        Settings
        (Decode.maybe (Decode.field "spawnkillProtectionSetting" Decode.bool) |> Decode.map (Maybe.withDefault default.spawnkillProtection))


settingsEncoder : Settings -> Encode.Value
settingsEncoder settings =
    Encode.object
        [ ( "spawnkillProtectionSetting", Encode.bool settings.spawnkillProtection )
        ]
