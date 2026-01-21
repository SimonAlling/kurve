module Holes exposing
    ( HoleStatus(..)
    , Holiness(..)
    , RandomHoleStatus
    , generateSolidTicks
    , getHoliness
    , updateHoleStatus
    )

import Config exposing (HoleConfig)
import Random


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


updateHoleStatus : HoleConfig -> HoleStatus -> HoleStatus
updateHoleStatus holeConfig holeStatus =
    case holeStatus of
        RandomHoles randomHoleStatus ->
            RandomHoles (updateRandomHoleStatus holeConfig randomHoleStatus)

        NoHoles ->
            NoHoles


updateRandomHoleStatus : HoleConfig -> RandomHoleStatus -> RandomHoleStatus
updateRandomHoleStatus holeConfig randomHoleStatus =
    case ( randomHoleStatus.holiness, randomHoleStatus.ticksLeft ) of
        ( Holy, 0 ) ->
            let
                ( solidTicks, newSeed ) =
                    Random.step (generateSolidTicks holeConfig) randomHoleStatus.holeSeed
            in
            { holiness = Solid, ticksLeft = solidTicks, holeSeed = newSeed }

        ( Holy, ticksLeft ) ->
            { randomHoleStatus | ticksLeft = ticksLeft - 1 }

        ( Solid, 0 ) ->
            let
                ( holyTicks, newSeed ) =
                    Random.step (generateHolyTicks holeConfig) randomHoleStatus.holeSeed
            in
            { holiness = Holy, ticksLeft = holyTicks, holeSeed = newSeed }

        ( Solid, ticksLeft ) ->
            { randomHoleStatus | ticksLeft = ticksLeft - 1 }


generateSolidTicks : HoleConfig -> Random.Generator Int
generateSolidTicks holes =
    Random.int holes.minSolidTicks holes.maxSolidTicks


generateHolyTicks : HoleConfig -> Random.Generator Int
generateHolyTicks holes =
    Random.int holes.minHolyTicks holes.maxHolyTicks
