module Holes exposing
    ( HoleStatus(..)
    , Holiness(..)
    , RandomHoleStatus
    , generateInitialUnholyTicks
    , getHoliness
    , updateHoleStatus
    )

import Config exposing (HoleConfig, KurveConfig)
import Random
import Types.Distance as Distance exposing (Distance, computeDistanceBetweenCenters)
import World exposing (distanceToTicks)


type HoleStatus
    = RandomHoles RandomHoleStatus
    | NoHoles


type alias RandomHoleStatus =
    { holiness : Holiness
    , ticksLeft : Int
    , holeSeed : Random.Seed
    }


getHoliness : HoleStatus -> Holiness
getHoliness holeStatus =
    case holeStatus of
        RandomHoles { holiness } ->
            holiness

        NoHoles ->
            Unholy


type Holiness
    = Holy
    | Unholy


updateHoleStatus : KurveConfig -> HoleStatus -> HoleStatus
updateHoleStatus kurveConfig holeStatus =
    case holeStatus of
        RandomHoles randomHoleStatus ->
            RandomHoles (updateRandomHoleStatus kurveConfig randomHoleStatus)

        NoHoles ->
            NoHoles


updateRandomHoleStatus : KurveConfig -> RandomHoleStatus -> RandomHoleStatus
updateRandomHoleStatus kurveConfig randomHoleStatus =
    case ( randomHoleStatus.holiness, randomHoleStatus.ticksLeft ) of
        ( Holy, 0 ) ->
            let
                unholyTicksGenerator : Random.Generator Int
                unholyTicksGenerator =
                    generateHoleSpacing kurveConfig.holes |> Random.map (distanceToTicks kurveConfig.tickrate kurveConfig.speed)

                ( unholyTicks, newSeed ) =
                    Random.step unholyTicksGenerator randomHoleStatus.holeSeed
            in
            { holiness = Unholy, ticksLeft = unholyTicks, holeSeed = newSeed }

        ( Holy, ticksLeft ) ->
            { randomHoleStatus | ticksLeft = ticksLeft - 1 }

        ( Unholy, 0 ) ->
            let
                holyTicksGenerator : Random.Generator Int
                holyTicksGenerator =
                    generateHoleSize kurveConfig.holes |> Random.map (computeDistanceBetweenCenters >> distanceToTicks kurveConfig.tickrate kurveConfig.speed)

                ( holyTicks, newSeed ) =
                    Random.step holyTicksGenerator randomHoleStatus.holeSeed
            in
            { holiness = Holy, ticksLeft = holyTicks, holeSeed = newSeed }

        ( Unholy, ticksLeft ) ->
            { randomHoleStatus | ticksLeft = ticksLeft - 1 }


generateHoleSpacing : HoleConfig -> Random.Generator Distance
generateHoleSpacing holeConfig =
    Distance.generate holeConfig.minInterval holeConfig.maxInterval


generateHoleSize : HoleConfig -> Random.Generator Distance
generateHoleSize holeConfig =
    Distance.generate holeConfig.minSize holeConfig.maxSize


generateInitialUnholyTicks : KurveConfig -> Random.Generator Int
generateInitialUnholyTicks { tickrate, speed, holes } =
    generateHoleSpacing holes |> Random.map (distanceToTicks tickrate speed)
