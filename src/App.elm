module App exposing (AppState(..), modifyGameState)

import Game exposing (GameState)
import Menu exposing (MenuState)
import Random


type AppState
    = InGame GameState
    | InMenu MenuState Random.Seed


modifyGameState : (GameState -> GameState) -> AppState -> AppState
modifyGameState f appState =
    case appState of
        InGame gameState ->
            InGame <| f gameState

        _ ->
            appState
