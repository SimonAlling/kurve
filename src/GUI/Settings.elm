module GUI.Settings exposing (settings)

import Colors
import Config exposing (Config)
import GUI.Text as Text
import Html exposing (Html, button, div, footer, h2, input, label)
import Html.Attributes as Attr
import Html.Events
import Settings exposing (SettingId(..), Settings)


settings : (SettingId -> Bool -> msg) -> (Settings -> msg) -> msg -> Config -> Html msg
settings makeMsg makeApplyPresetMsg closeMsg config =
    div
        [ Attr.id "settings-screen" ]
        (closeButton closeMsg
            :: (makeSettingsEntries config |> List.map (showEntry makeMsg))
            ++ [ presetsFooter makeApplyPresetMsg thePresets ]
        )


type alias SettingsEntry =
    { settingId : SettingId
    , settingLabel : String
    , settingDescription : String
    , currentValue : Bool
    }


showEntry : (SettingId -> Bool -> msg) -> SettingsEntry -> Html msg
showEntry makeMsg { settingId, settingLabel, settingDescription, currentValue } =
    let
        id : String
        id =
            idFor settingId
    in
    div
        [ Attr.title settingDescription
        ]
        [ input
            [ Attr.type_ "checkbox"
            , Attr.checked currentValue
            , Attr.id id
            , Html.Events.onCheck (makeMsg settingId)
            ]
            []
        , label
            [ Attr.for id ]
            (Text.string (Text.Size 1) Colors.white settingLabel)
        ]


makeSettingsEntries : Config -> List SettingsEntry
makeSettingsEntries config =
    [ { settingId = SpawnProtection
      , settingLabel = "Prevent spawnkills"
      , settingDescription = "Ensure a minimum distance between spawns, to minimize the risk of crashing immediately after spawning."
      , currentValue = config.spawn.spawnkillProtection
      }
    , { settingId = PersistHoleStatus
      , settingLabel = "Persist hole status between rounds"
      , settingDescription = "Remember each player's hole status (e.g. solid with the next hole coming up in 5 ticks) when proceeding to the next round."
      , currentValue = config.kurves.holes.persistBetweenRounds
      }
    , { settingId = ReplicateTruncationBug
      , settingLabel = "Replicate position truncation bug"
      , settingDescription = "Round positions <1 pixel outside the top and left edge of the canvas to 0 instead of –1, effectively making those edges easier to avoid."
      , currentValue = config.world.replicateTruncationBug
      }
    , { settingId = EnableAlternativeControls
      , settingLabel = "Enable alternative controls"
      , settingDescription = "Make it easier to control players whose default controls are tricky to use in some way, or not present on all keyboards."
      , currentValue = config.enableAlternativeControls
      }
    ]


thePresets : List Preset
thePresets =
    [ ( Settings.default, "Sane defaults" )
    , ( Settings.trueOriginalExperience, "True Original Experience(tm)" )
    ]


type alias Preset =
    ( Settings, String )


presetsFooter : (Settings -> msg) -> List Preset -> Html msg
presetsFooter makeMsg presets =
    footer
        []
        [ presetsHeading, presetButtons makeMsg presets ]


presetsHeading : Html msg
presetsHeading =
    h2
        []
        (Text.string (Text.Size 1) Colors.white "Presets")


presetButtons : (Settings -> msg) -> List Preset -> Html msg
presetButtons makeMsg presets =
    div
        [ Attr.id "preset-buttons"
        ]
        (List.map (makeButton makeMsg) presets)


makeButton : (Settings -> msg) -> Preset -> Html msg
makeButton makeMsg ( settingsRecord, buttonLabel ) =
    button
        [ Attr.class "buttony-button"
        , Html.Events.onClick (makeMsg settingsRecord)
        ]
        (Text.string (Text.Size 1) Colors.white buttonLabel)


closeButton : msg -> Html msg
closeButton msg =
    button
        [ Attr.id "button-hide-settings"
        , Attr.class "icon-button"
        , Attr.class "in-top-right-corner"
        , Attr.title "Close"
        , Html.Events.onClick msg
        ]
        []


idFor : SettingId -> String
idFor settingId =
    case settingId of
        SpawnProtection ->
            "spawn-protection"

        PersistHoleStatus ->
            "persist-hole-status"

        ReplicateTruncationBug ->
            "replicate-truncation-bug"

        EnableAlternativeControls ->
            "enable-alternative-controls"
