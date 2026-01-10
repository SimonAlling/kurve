module TestHelpers.Randomness exposing (withSeed)

import Main exposing (Model)
import Random


withSeed : Random.Seed -> Model -> Model
withSeed desiredSeed model =
    { model | seed = desiredSeed }
