module Holes exposing
    ( HoleConfig(..)
    , HoleStatus(..)
    , Holiness(..)
    , RandomHoleStatus
    , getHoliness
    , makeInitialHoleStatus
    , updateHoleStatus
    )

import Random
import Types.Distance as Distance exposing (Distance, computeDistanceBetweenCenters)


type HoleConfig
    = UseRandomHoles RandomHoleConfig
    | UsePeriodicHoles PeriodicHoleConfig
    | UseNoHoles


type alias RandomHoleConfig =
    { minInterval : Distance
    , maxInterval : Distance
    , minSize : Distance
    , maxSize : Distance
    }


type alias PeriodicHoleConfig =
    { interval : Distance
    , size : Distance
    }


type HoleStatus
    = RandomHoles RandomHoleStatus
    | PeriodicHoles PeriodicHoleStatus
    | NoHoles


type alias RandomHoleStatus =
    { holiness : Holiness
    , ticksLeft : Int
    , holeSeed : Random.Seed
    , randomHoleConfig : RandomHoleConfig
    }


type alias PeriodicHoleStatus =
    { holiness : Holiness
    , ticksLeft : Int
    , periodicHoleConfig : PeriodicHoleConfig
    }


getHoliness : HoleStatus -> Holiness
getHoliness holeStatus =
    case holeStatus of
        RandomHoles { holiness } ->
            holiness

        PeriodicHoles { holiness } ->
            holiness

        NoHoles ->
            Unholy


type Holiness
    = Holy
    | Unholy


updateHoleStatus : (Distance -> Int) -> HoleStatus -> HoleStatus
updateHoleStatus distanceToTicks holeStatus =
    case holeStatus of
        RandomHoles randomHoleStatus ->
            RandomHoles (updateRandomHoleStatus distanceToTicks randomHoleStatus)

        PeriodicHoles periodicHoleStatus ->
            PeriodicHoles (updatePeriodicHoleStatus distanceToTicks periodicHoleStatus)

        NoHoles ->
            NoHoles


updateRandomHoleStatus : (Distance -> Int) -> RandomHoleStatus -> RandomHoleStatus
updateRandomHoleStatus distanceToTicks randomHoleStatus =
    case ( randomHoleStatus.holiness, randomHoleStatus.ticksLeft ) of
        ( Holy, 0 ) ->
            let
                unholyTicksGenerator : Random.Generator Int
                unholyTicksGenerator =
                    generateHoleSpacing randomHoleStatus.randomHoleConfig |> Random.map distanceToTicks

                ( unholyTicks, newSeed ) =
                    Random.step unholyTicksGenerator randomHoleStatus.holeSeed
            in
            { randomHoleStatus | holiness = Unholy, ticksLeft = unholyTicks, holeSeed = newSeed }

        ( Holy, ticksLeft ) ->
            { randomHoleStatus | ticksLeft = ticksLeft - 1 }

        ( Unholy, 0 ) ->
            let
                holyTicksGenerator : Random.Generator Int
                holyTicksGenerator =
                    generateHoleSize randomHoleStatus.randomHoleConfig |> Random.map (computeDistanceBetweenCenters >> distanceToTicks)

                ( holyTicks, newSeed ) =
                    Random.step holyTicksGenerator randomHoleStatus.holeSeed
            in
            { randomHoleStatus | holiness = Holy, ticksLeft = holyTicks, holeSeed = newSeed }

        ( Unholy, ticksLeft ) ->
            { randomHoleStatus | ticksLeft = ticksLeft - 1 }


updatePeriodicHoleStatus : (Distance -> Int) -> PeriodicHoleStatus -> PeriodicHoleStatus
updatePeriodicHoleStatus distanceToTicks periodicHoleStatus =
    case ( periodicHoleStatus.holiness, periodicHoleStatus.ticksLeft ) of
        ( Holy, 0 ) ->
            { periodicHoleStatus
                | holiness = Unholy
                , ticksLeft =
                    periodicHoleStatus.periodicHoleConfig.interval
                        |> computeDistanceBetweenCenters
                        |> distanceToTicks
            }

        ( Holy, ticksLeft ) ->
            { periodicHoleStatus | ticksLeft = ticksLeft - 1 }

        ( Unholy, 0 ) ->
            { periodicHoleStatus
                | holiness = Holy
                , ticksLeft =
                    periodicHoleStatus.periodicHoleConfig.size
                        |> computeDistanceBetweenCenters
                        |> distanceToTicks
            }

        ( Unholy, ticksLeft ) ->
            { periodicHoleStatus | ticksLeft = ticksLeft - 1 }


generateHoleSpacing : RandomHoleConfig -> Random.Generator Distance
generateHoleSpacing holeConfig =
    Distance.generate holeConfig.minInterval holeConfig.maxInterval


generateHoleSize : RandomHoleConfig -> Random.Generator Distance
generateHoleSize holeConfig =
    Distance.generate holeConfig.minSize holeConfig.maxSize


makeInitialHoleStatus : (Distance -> Int) -> HoleConfig -> Random.Seed -> HoleStatus
makeInitialHoleStatus distanceToTicks holeConfig seed =
    case holeConfig of
        UseRandomHoles randomHoleConfig ->
            let
                spacingGenerator : Random.Generator Distance
                spacingGenerator =
                    generateHoleSpacing randomHoleConfig

                ( unholyDistance, newSeed ) =
                    Random.step spacingGenerator seed
            in
            RandomHoles
                { holiness = Unholy
                , ticksLeft = distanceToTicks unholyDistance
                , holeSeed = newSeed
                , randomHoleConfig = randomHoleConfig
                }

        UsePeriodicHoles periodicHoleConfig ->
            PeriodicHoles
                { holiness = Unholy
                , ticksLeft = distanceToTicks periodicHoleConfig.interval
                , periodicHoleConfig = periodicHoleConfig
                }

        UseNoHoles ->
            NoHoles
