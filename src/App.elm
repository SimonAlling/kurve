module App exposing
    ( AppState(..)
    , modifyGameState
    )

import Game exposing (GameState)
import Menu exposing (MenuState)


type AppState
    = InMenu MenuState
    | InGame GameState


modifyGameState : (GameState -> GameState) -> AppState -> AppState
modifyGameState f appState =
    case appState of
        InGame gameState ->
            InGame <| f gameState

        _ ->
            appState
