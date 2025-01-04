module App exposing
    ( AppState(..)
    , modifyGameState
    )

import Game exposing (GameState, Milliseconds)
import Menu exposing (MenuState)
import Random


type AppState
    = InMenu MenuState Random.Seed
    | InGame Milliseconds GameState


modifyGameState : (GameState -> GameState) -> AppState -> AppState
modifyGameState f appState =
    case appState of
        InGame ms gameState ->
            InGame ms <| f gameState

        _ ->
            appState
