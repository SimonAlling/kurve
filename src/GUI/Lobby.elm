module GUI.Lobby exposing (lobby)

import Color
import Dict
import Html exposing (Html, div)
import Html.Attributes as Attr
import Players exposing (AllPlayers)
import Types.Player exposing (Player)
import Types.PlayerId exposing (PlayerId)
import Types.PlayerStatus exposing (PlayerStatus(..))


lobby : AllPlayers -> Html msg
lobby players =
    div
        [ Attr.id "lobby"
        ]
        (Dict.toList players |> List.map playerEntry)


playerEntry : ( PlayerId, ( Player, PlayerStatus ) ) -> Html msg
playerEntry ( id, ( player, status ) ) =
    let
        controlsImageMask : String
        controlsImageMask =
            "url(./resources/controls-player-" ++ String.fromInt id ++ ".png)"

        backgroundColor : String
        backgroundColor =
            Color.toCssString player.color
    in
    Html.div
        [ Attr.class "playerEntry" ]
        [ Html.div
            [ Attr.class "controls"
            , Attr.style "background-color" backgroundColor
            , Attr.style "-webkit-mask-image" controlsImageMask
            , Attr.style "mask-image" controlsImageMask
            ]
            []
        , Html.div
            [ Attr.class "ready"
            , Attr.style "background-color" backgroundColor
            , Attr.style "visibility"
                (case status of
                    Participating ->
                        "visible"

                    NotParticipating ->
                        "hidden"
                )
            ]
            []
        ]
