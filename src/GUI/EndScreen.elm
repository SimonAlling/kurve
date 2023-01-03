module GUI.EndScreen exposing (endScreen)

import Dict
import GUI.Digits
import Html exposing (Html, div)
import Html.Attributes as Attr
import Players exposing (AllPlayers)
import Types.Player exposing (Player)
import Types.PlayerStatus exposing (PlayerStatus(..))
import Types.Score exposing (Score(..))


endScreen : AllPlayers -> Html msg
endScreen players =
    div
        [ Attr.id "endScreen"
        ]
        [ results players
        , Html.img [ Attr.id "KONEC_HRY", Attr.src "./resources/konec-hry.png" ] []
        ]


results : AllPlayers -> Html msg
results players =
    div
        [ Attr.id "results"
        ]
        (players |> Dict.toList |> List.map (Tuple.second >> resultsEntry))


resultsEntry : ( Player, PlayerStatus ) -> Html msg
resultsEntry ( player, status ) =
    div
        [ Attr.class "resultsEntry"
        ]
        (case status of
            Participating (Score score) ->
                GUI.Digits.small player.color score

            NotParticipating ->
                []
        )
