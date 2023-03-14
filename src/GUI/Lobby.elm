module GUI.Lobby exposing (lobby)

import Dict
import GUI.Controls
import GUI.Text as Text
import Html exposing (Html, div)
import Html.Attributes as Attr
import Players exposing (AllPlayers)
import Types.Player exposing (Player)
import Types.PlayerStatus exposing (PlayerStatus(..))


lobby : AllPlayers -> Html msg
lobby players =
    div
        [ Attr.id "lobby"
        ]
        (Dict.values players |> List.map playerEntry)


playerEntry : ( Player, PlayerStatus ) -> Html msg
playerEntry ( player, status ) =
    let
        ( left, right ) =
            GUI.Controls.showControls player
    in
    Html.div
        [ Attr.class "playerEntry" ]
        [ Html.div
            [ Attr.class "controls"
            ]
            (Text.string (Text.Size 1) player.color <| "(" ++ left ++ " " ++ right ++ ")")
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
