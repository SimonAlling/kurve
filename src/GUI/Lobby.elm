module GUI.Lobby exposing (lobby)

import Color
import Dict
import GUI.Fonts
import GUI.Text
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
        ( left, right ) =
            controls id
    in
    Html.div
        [ Attr.class "playerEntry" ]
        [ Html.div
            [ Attr.class "controls"
            ]
            (GUI.Text.string GUI.Fonts.bgiDefault8x8 1 player.color <| "(" ++ left ++ " " ++ right ++ ")")
        , Html.div
            [ Attr.style "visibility"
                (case status of
                    Participating _ ->
                        "visible"

                    NotParticipating ->
                        "hidden"
                )
            ]
            (GUI.Text.string GUI.Fonts.bgiDefault8x8 2 player.color "READY")
        ]


controls : PlayerId -> ( String, String )
controls id =
    case id of
        0 ->
            ( "1", "Q" )

        1 ->
            ( "L.Ctrl", "L.Alt" )

        2 ->
            ( "M", "," )

        3 ->
            ( "L.Arrow", "R.Arrow" )

        4 ->
            ( "/", "*" )

        5 ->
            ( "L.Mouse", "R.Mouse" )

        _ ->
            ( "", "" )
