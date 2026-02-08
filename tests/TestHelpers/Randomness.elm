module TestHelpers.Randomness exposing (withSeedIfInMenu)

import App exposing (AppState(..))
import Main exposing (Model)
import Random


withSeedIfInMenu : Random.Seed -> Model -> Model
withSeedIfInMenu desiredSeed model =
    { model | appState = appStateWithSeedIfInMenu desiredSeed model.appState }


appStateWithSeedIfInMenu : Random.Seed -> AppState -> AppState
appStateWithSeedIfInMenu desiredSeed appState =
    case appState of
        InMenu menuState _ ->
            InMenu menuState desiredSeed

        InGame gameState ->
            InGame gameState
