module GUI.Lobby exposing (lobby)

import Dict
import GUI.Controls
import GUI.Text as Text
import Html exposing (Html, button, div, p)
import Html.Attributes as Attr
import Html.Events
import Players exposing (AllPlayers)
import Types.Player exposing (Player)
import Types.PlayerStatus exposing (PlayerStatus(..))


lobby : Bool -> msg -> AllPlayers -> Html msg
lobby enableExtraControls onSettingsButtonClick players =
    div
        [ Attr.id "lobby"
        ]
        (settingsButton onSettingsButtonClick :: (Dict.values players |> List.map (playerEntry enableExtraControls)))


playerEntry : Bool -> ( Player, PlayerStatus ) -> Html msg
playerEntry enableExtraControls ( player, status ) =
    let
        ( left, right ) =
            GUI.Controls.showControls player
    in
    Html.div
        [ Attr.class "playerEntry" ]
        [ Html.div
            [ Attr.class "controls"
            ]
            [ p
                []
                (Text.string (Text.Size 1) player.color <| "(" ++ left ++ " " ++ right ++ ")")
            , p
                [ Attr.class "extra-controls"
                , Attr.hidden (not enableExtraControls)
                ]
                (Text.string (Text.Size 1) player.color (GUI.Controls.showExtraControls player))
            ]
        , Html.div
            [ Attr.style "visibility"
                (case status of
                    Participating _ ->
                        "visible"

                    NotParticipating ->
                        "hidden"
                )
            ]
            (Text.string (Text.Size 2) player.color "READY")
        ]


settingsButton : msg -> Html msg
settingsButton onClick =
    button
        [ Attr.id "button-show-settings"
        , Attr.class "icon-button"
        , Attr.class "in-top-right-corner"
        , Attr.title "Settings"
        , Attr.class "stop-propagation-on-mousedown" -- to prevent Blue from joining when button clicked
        , Html.Events.onClick onClick
        ]
        []
