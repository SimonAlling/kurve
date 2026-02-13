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
    ( SettingId, String, Bool )


showEntry : (SettingId -> Bool -> msg) -> SettingsEntry -> Html msg
showEntry makeMsg ( settingId, settingLabel, currentValue ) =
    let
        id : String
        id =
            idFor settingId
    in
    div
        []
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
    [ ( SpawnProtection, "Prevent spawnkills", config.spawn.spawnkillProtection )
    , ( PersistHoleStatus, "Persist hole status between rounds", config.kurves.holes.persistBetweenRounds )
    , ( EnableAlternativeControls, "Enable alternative controls", config.enableAlternativeControls )
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

        EnableAlternativeControls ->
            "enable-alternative-controls"
