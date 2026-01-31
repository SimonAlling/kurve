module TestHelpers.Randomness exposing (withSeed)

import App exposing (AppState(..))
import Game exposing (ActiveGameState(..), GameState(..))
import Main exposing (Model)
import Random
import Round exposing (Round)


withSeed : Random.Seed -> Model -> Model
withSeed desiredSeed model =
    { model | appState = appStateWithSeed desiredSeed model.appState }


appStateWithSeed : Random.Seed -> AppState -> AppState
appStateWithSeed desiredSeed appState =
    case appState of
        InMenu menuState _ ->
            InMenu menuState desiredSeed

        InGame gameState ->
            InGame (gameStateWithSeed desiredSeed gameState)


gameStateWithSeed : Random.Seed -> GameState -> GameState
gameStateWithSeed desiredSeed gameState =
    case gameState of
        Active liveOrReplay pausedOrNot activeGameState ->
            Active liveOrReplay pausedOrNot (activeGameStateWithSeed desiredSeed activeGameState)

        RoundOver roundOverContext round dialogState ->
            RoundOver roundOverContext (roundWithSeed desiredSeed round) dialogState


activeGameStateWithSeed : Random.Seed -> ActiveGameState -> ActiveGameState
activeGameStateWithSeed desiredSeed activeGameState =
    case activeGameState of
        Spawning spawnState round ->
            Spawning spawnState (roundWithSeed desiredSeed round)

        Moving leftoverFrameTime tick round ->
            Moving leftoverFrameTime tick (roundWithSeed desiredSeed round)


roundWithSeed : Random.Seed -> Round -> Round
roundWithSeed desiredSeed round =
    { round | seed = desiredSeed }
