module App exposing
    ( AppState(..)
    , modifyGameState
    )

import Game exposing (GameState)
import Menu exposing (MenuState)
import Random
import Replay exposing (Replay2)


type AppState
    = InMenu MenuState Random.Seed
    | InGame GameState
    | InReplay Replay2


modifyGameState : (GameState -> GameState) -> AppState -> AppState
modifyGameState f appState =
    case appState of
        InGame gameState ->
            InGame <| f gameState

        _ ->
            appState
