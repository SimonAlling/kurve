module Holes exposing
    ( HoleInit(..)
    , HoleStatus
    , Holiness(..)
    , RandomHoleStatus
    , getHoliness
    , makeHoleInit
    , makeInitialHoleStatus
    , updateHoleStatus
    )

import Config exposing (HoleConfig(..), KurveConfig, PeriodicHoleConfig, RandomHoleConfig)
import Random
import Types.Distance as Distance exposing (Distance, computeDistanceBetweenCenters)
import World


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


type HoleInit
    = InitRandomHoles RandomHoleConfig Random.Seed
    | InitPeriodicHoles PeriodicHoleConfig
    | InitNoHoles


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


makeInitialHoleStatus : KurveConfig -> HoleInit -> HoleStatus
makeInitialHoleStatus kurveConfig holeInit =
    let
        distanceToTicks : Distance -> Int
        distanceToTicks =
            World.distanceToTicks kurveConfig.tickrate kurveConfig.speed
    in
    case holeInit of
        InitRandomHoles randomHoleConfig seed ->
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

        InitPeriodicHoles periodicHoleConfig ->
            PeriodicHoles
                { holiness = Unholy
                , ticksLeft = distanceToTicks periodicHoleConfig.interval
                , periodicHoleConfig = periodicHoleConfig
                }

        InitNoHoles ->
            NoHoles


makeHoleInit : KurveConfig -> Random.Seed -> HoleInit
makeHoleInit kurveConfig seed =
    case kurveConfig.holes of
        UseRandomHoles randomHoleConfig ->
            InitRandomHoles randomHoleConfig seed

        UsePeriodicHoles periodicHoleConfig ->
            InitPeriodicHoles periodicHoleConfig

        UseNoHoles ->
            InitNoHoles
