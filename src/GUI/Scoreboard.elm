module GUI.Scoreboard exposing (scoreboard, scoreboardContainer)

import Dict
import GUI.Digits
import Game exposing (GameState)
import Html exposing (Html, div)
import Html.Attributes as Attr
import Players exposing (AllPlayers, includeResultsFrom, noExtraData, participating)
import Round exposing (Round)
import Types.Player exposing (Player)
import Types.PlayerStatus exposing (PlayerStatus(..))
import Types.Score exposing (Score(..))


scoreboard : GameState -> AllPlayers -> Html msg
scoreboard gameState players =
    scoreboardContainer
        (content players (Game.getCurrentRound gameState))


scoreboardContainer : List (Html msg) -> Html msg
scoreboardContainer =
    div
        [ Attr.id "scoreboard"
        , Attr.class "canvasHeight"
        ]


content : AllPlayers -> Round -> List (Html msg)
content players currentRound =
    if Dict.size (participating noExtraData players) > 1 then
        players |> includeResultsFrom currentRound |> Dict.toList |> List.map (Tuple.second >> scoreboardEntry)

    else
        -- The scoreboard should be empty in single-player mode.
        []


scoreboardEntry : ( Player, PlayerStatus ) -> Html msg
scoreboardEntry ( player, status ) =
    div
        [ Attr.class "scoreboardEntry"
        ]
        (case status of
            Participating (Score score) ->
                GUI.Digits.large player.color score

            NotParticipating ->
                []
        )
