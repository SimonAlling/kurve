module GUI.Scoreboard exposing (scoreboard)

import App exposing (AppState(..))
import Dict
import GUI.Digits
import Game exposing (GameState(..))
import Html exposing (Html, div)
import Html.Attributes as Attr
import Players exposing (AllPlayers, includeResultsFrom, participating)
import Round exposing (Round)
import Types.Player exposing (Player)
import Types.PlayerStatus exposing (PlayerStatus(..))
import Types.Score exposing (Score(..))


scoreboard : AppState -> AllPlayers -> Html msg
scoreboard appState players =
    div
        [ Attr.id "scoreboard"
        , Attr.class "canvasHeight"
        ]
        (case appState of
            Lobby _ ->
                []

            InGame (PreRound _ ( _, round )) ->
                content players round

            InGame (MidRound _ ( _, round )) ->
                content players round

            InGame (PostRound round) ->
                content players round

            GameOver _ ->
                []
        )


content : AllPlayers -> Round -> List (Html msg)
content players currentRound =
    if Dict.size (participating players) > 1 then
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
