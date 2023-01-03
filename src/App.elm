module App exposing (AppState(..), modifyGameState)

import Game exposing (GameState)
import Random


type AppState
    = InGame GameState
    | Lobby Random.Seed
    | GameOver Random.Seed


modifyGameState : (GameState -> GameState) -> AppState -> AppState
modifyGameState f appState =
    case appState of
        InGame gameState ->
            InGame <| f gameState

        _ ->
            appState
