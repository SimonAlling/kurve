module Spawn exposing (SpawnState, flickerFrequencyToTicksPerSecond, generateKurves, makeSpawnState, stepSpawnState)

import Config exposing (Config, SpawnConfig, WorldConfig)
import Dict
import Drawing exposing (WhatToDraw, drawSpawnsPermanently, drawSpawnsTemporarily)
import Holes exposing (HoleStatus(..), Holiness(..), generateSolidTicks)
import Input exposing (toStringSetControls)
import Players exposing (ParticipatingPlayers)
import Random
import Random.Extra as Random
import Round exposing (Round)
import Thickness exposing (theThickness)
import Types.Angle exposing (Angle(..))
import Types.Distance as Distance
import Types.Kurve as Kurve exposing (Kurve)
import Types.Player exposing (Player)
import Types.PlayerId exposing (PlayerId)
import Types.Radius as Radius
import Util exposing (curry, isEven)
import World exposing (Position, distanceBetween)


type alias SpawnState =
    { kurvesLeft : List Kurve
    , alreadySpawnedKurves : List Kurve
    , ticksLeftStartingValue : Int
    , ticksLeft : Int
    }


makeSpawnState : Int -> Round -> SpawnState
makeSpawnState numberOfFlickers round =
    let
        ticksLeftStartingValue : Int
        ticksLeftStartingValue =
            numberOfFlickersToNumberOfTicks numberOfFlickers - 1
    in
    { kurvesLeft = round |> .kurves |> .alive
    , alreadySpawnedKurves = []
    , ticksLeftStartingValue = ticksLeftStartingValue
    , ticksLeft = ticksLeftStartingValue
    }


stepSpawnState : SpawnState -> ( Maybe SpawnState, WhatToDraw )
stepSpawnState ({ kurvesLeft, alreadySpawnedKurves, ticksLeftStartingValue, ticksLeft } as spawnState) =
    case kurvesLeft of
        [] ->
            -- All Kurves have spawned.
            ( Nothing, drawSpawnsPermanently alreadySpawnedKurves )

        spawning :: waiting ->
            let
                spawnedAndSpawning : List Kurve
                spawnedAndSpawning =
                    alreadySpawnedKurves ++ [ spawning ]

                kurvesToDraw : List Kurve
                kurvesToDraw =
                    if not (isEven ticksLeft) then
                        spawnedAndSpawning

                    else
                        alreadySpawnedKurves

                newSpawnState : SpawnState
                newSpawnState =
                    if ticksLeft == 0 then
                        { spawnState | kurvesLeft = waiting, alreadySpawnedKurves = spawnedAndSpawning, ticksLeft = ticksLeftStartingValue }

                    else
                        { spawnState | ticksLeft = ticksLeft - 1 }
            in
            ( Just newSpawnState, drawSpawnsTemporarily kurvesToDraw )


numberOfFlickersToNumberOfTicks : Int -> Int
numberOfFlickersToNumberOfTicks =
    (*) 2


flickerFrequencyToTicksPerSecond : Float -> Float
flickerFrequencyToTicksPerSecond =
    (*) 2


generateKurves : Config -> ParticipatingPlayers (Maybe HoleStatus) -> Random.Generator (List Kurve)
generateKurves config players =
    let
        numberOfPlayers : Int
        numberOfPlayers =
            Dict.size players

        generateNewAndPrepend : Maybe HoleStatus -> ( PlayerId, Player ) -> List Kurve -> Random.Generator (List Kurve)
        generateNewAndPrepend maybeHoleStatus ( id, player ) precedingKurves =
            generateKurve config id numberOfPlayers (List.map (.state >> .position) precedingKurves) player maybeHoleStatus
                |> Random.map (\kurve -> kurve :: precedingKurves)
    in
    Dict.foldr
        (\id ( player, _, maybeHoleStatusFromPreviousRound ) -> curry (Random.andThen << generateNewAndPrepend maybeHoleStatusFromPreviousRound) id player)
        (Random.constant [])
        players


isSafeNewPosition : Config -> Int -> List Position -> Position -> Bool
isSafeNewPosition config numberOfPlayers existingPositions newPosition =
    List.all (not << isTooCloseFor numberOfPlayers config newPosition) existingPositions


isTooCloseFor : Int -> Config -> Position -> Position -> Bool
isTooCloseFor numberOfPlayers config point1 point2 =
    let
        desiredMinimumDistance : Float
        desiredMinimumDistance =
            theThickness + Radius.toFloat config.kurves.turningRadius * config.spawn.desiredMinimumDistanceTurningRadiusFactor

        ( ( left, top ), ( right, bottom ) ) =
            spawnArea config.spawn config.world

        availableArea : Float
        availableArea =
            (right - left) * (bottom - top)

        -- Derived from:
        -- audacity × total available area > number of players × ( max allowed minimum distance / 2 )² × pi
        maxAllowedMinimumDistance : Float
        maxAllowedMinimumDistance =
            2 * sqrt (config.spawn.protectionAudacity * availableArea / (toFloat numberOfPlayers * pi))
    in
    Distance.toFloat (distanceBetween point1 point2) < min desiredMinimumDistance maxAllowedMinimumDistance


generateKurve : Config -> PlayerId -> Int -> List Position -> Player -> Maybe HoleStatus -> Random.Generator Kurve
generateKurve config id numberOfPlayers existingPositions player holeStatusFromPreviousRound =
    generateKurveState config numberOfPlayers existingPositions holeStatusFromPreviousRound
        |> Random.map
            (\state ->
                { color = player.color
                , id = id
                , controls = toStringSetControls config.enableAlternativeControls player.controls
                , state = state
                , stateAtSpawn = state
                , reversedInteractions = []
                }
            )


generateKurveState : Config -> Int -> List Position -> Maybe HoleStatus -> Random.Generator Kurve.State
generateKurveState config numberOfPlayers existingPositions holeStatusFromPreviousRound =
    let
        maybeSafeSpawnPosition : Random.Generator Position
        maybeSafeSpawnPosition =
            if config.spawn.spawnkillProtection then
                generateSpawnPosition config.spawn config.world |> Random.filter (isSafeNewPosition config numberOfPlayers existingPositions)

            else
                generateSpawnPosition config.spawn config.world
    in
    Random.map4
        (\generatedPosition generatedAngle generatedSolidTicks generatedHoleSeed ->
            { position = generatedPosition
            , direction = generatedAngle
            , holeStatus =
                let
                    freshHoleStatus : HoleStatus
                    freshHoleStatus =
                        RandomHoles
                            { holiness = Solid
                            , ticksLeft = generatedSolidTicks
                            , holeSeed = generatedHoleSeed
                            }
                in
                if config.kurves.holes.persistBetweenRounds then
                    holeStatusFromPreviousRound |> Maybe.withDefault freshHoleStatus

                else
                    freshHoleStatus
            }
        )
        maybeSafeSpawnPosition
        (generateSpawnAngle config.spawn.angleInterval)
        (generateSolidTicks config.kurves)
        Random.independentSeed


spawnArea : SpawnConfig -> WorldConfig -> ( Position, Position )
spawnArea { margin } { width, height } =
    let
        topLeft : ( Float, Float )
        topLeft =
            ( margin
            , margin
            )

        bottomRight : ( Float, Float )
        bottomRight =
            ( toFloat width - margin
            , toFloat height - margin
            )
    in
    ( topLeft, bottomRight )


generateSpawnPosition : SpawnConfig -> WorldConfig -> Random.Generator Position
generateSpawnPosition spawnConfig worldConfig =
    let
        ( ( left, top ), ( right, bottom ) ) =
            spawnArea spawnConfig worldConfig
    in
    Random.pair (Random.float left right) (Random.float top bottom)


generateSpawnAngle : ( Float, Float ) -> Random.Generator Angle
generateSpawnAngle ( min, max ) =
    Random.float min max |> Random.map Angle
