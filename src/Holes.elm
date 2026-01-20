module Holes exposing
    ( HoleStatus(..)
    , Holiness(..)
    , RandomHoleStatus
    , generateSolidTicks
    , getHoliness
    , updateHoleStatus
    )

import Config exposing (KurveConfig)
import Random
import Types.Distance as Distance exposing (computeDistanceBetweenCenters)
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
            Solid


type Holiness
    = Holy
    | Solid


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
                ( solidTicks, newSeed ) =
                    Random.step (generateSolidTicks kurveConfig) randomHoleStatus.holeSeed
            in
            { holiness = Solid, ticksLeft = solidTicks, holeSeed = newSeed }

        ( Holy, ticksLeft ) ->
            { randomHoleStatus | ticksLeft = ticksLeft - 1 }

        ( Solid, 0 ) ->
            let
                ( holyTicks, newSeed ) =
                    Random.step (generateHolyTicks kurveConfig) randomHoleStatus.holeSeed
            in
            { holiness = Holy, ticksLeft = holyTicks, holeSeed = newSeed }

        ( Solid, ticksLeft ) ->
            { randomHoleStatus | ticksLeft = ticksLeft - 1 }


generateSolidTicks : KurveConfig -> Random.Generator Int
generateSolidTicks { tickrate, speed, holes } =
    Distance.generate holes.minInterval holes.maxInterval |> Random.map (distanceToTicks tickrate speed)


generateHolyTicks : KurveConfig -> Random.Generator Int
generateHolyTicks { tickrate, speed, holes } =
    Distance.generate holes.minSize holes.maxSize |> Random.map (computeDistanceBetweenCenters >> distanceToTicks tickrate speed)
