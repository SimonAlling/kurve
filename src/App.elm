module App exposing
    ( AppState(..)
    , modifyGameState
    )

import Game exposing (GameState)
import Menu exposing (MenuState)
import Random
import Types.FrameTime exposing (LeftoverFrameTime)


type AppState
    = InMenu MenuState Random.Seed
    | InGame LeftoverFrameTime GameState


modifyGameState : (GameState -> GameState) -> AppState -> AppState
modifyGameState f appState =
    case appState of
        InGame leftoverFrameTime gameState ->
            InGame leftoverFrameTime <| f gameState

        _ ->
            appState
