module App exposing
    ( AppState(..)
    , modifyGameState
    )

import Game exposing (GameState)
import Menu exposing (MenuState)
import Movie exposing (Movie)
import Random


type AppState
    = InMenu MenuState Random.Seed
    | InGame GameState
    | InMovie Movie


modifyGameState : (GameState -> GameState) -> AppState -> AppState
modifyGameState f appState =
    case appState of
        InGame gameState ->
            InGame <| f gameState

        _ ->
            appState
