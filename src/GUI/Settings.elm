module GUI.Settings exposing (settings)

import Colors
import Config exposing (Config)
import GUI.Text as Text
import Html exposing (Html, button, div, input, label)
import Html.Attributes as Attr
import Html.Events
import Settings exposing (SettingId(..))


settings : (SettingId -> Bool -> msg) -> msg -> Config -> Html msg
settings makeMsg closeMsg config =
    div
        [ Attr.id "settings-screen" ]
        (closeButton closeMsg :: (makeSettingsEntries config |> List.map (showEntry makeMsg)))


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
    , ( EnableAlternativeControls, "Enable alternative controls", config.enableAlternativeControls )
    ]


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

        EnableAlternativeControls ->
            "enable-alternative-controls"
