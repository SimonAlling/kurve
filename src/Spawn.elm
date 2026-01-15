module Spawn exposing (generateKurves)

import Config exposing (Config, SpawnConfig, WorldConfig)
import Dict
import Holes exposing (makeInitialHoleStatus)
import Input exposing (toStringSetControls)
import Players exposing (ParticipatingPlayers)
import Random
import Random.Extra as Random
import Thickness exposing (theThickness)
import Types.Angle exposing (Angle(..))
import Types.Distance as Distance
import Types.Kurve as Kurve exposing (Kurve)
import Types.Player exposing (Player)
import Types.PlayerId exposing (PlayerId)
import Types.Radius as Radius
import Util exposing (curry)
import World exposing (Position, distanceBetween)


generateKurves : Config -> ParticipatingPlayers -> Random.Generator (List Kurve)
generateKurves config players =
    let
        numberOfPlayers : Int
        numberOfPlayers =
            Dict.size players

        generateNewAndPrepend : ( PlayerId, Player ) -> List Kurve -> Random.Generator (List Kurve)
        generateNewAndPrepend ( id, player ) precedingKurves =
            generateKurve config id numberOfPlayers (List.map (.state >> .position) precedingKurves) player
                |> Random.map (\kurve -> kurve :: precedingKurves)
    in
    Dict.foldr
        (\id ( player, _ ) -> curry (Random.andThen << generateNewAndPrepend) id player)
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


generateKurve : Config -> PlayerId -> Int -> List Position -> Player -> Random.Generator Kurve
generateKurve config id numberOfPlayers existingPositions player =
    generateKurveState config numberOfPlayers existingPositions
        |> Random.map
            (\state ->
                { color = player.color
                , id = id
                , controls = toStringSetControls player.controls
                , state = state
                , stateAtSpawn = state
                , reversedInteractions = []
                }
            )


generateKurveState : Config -> Int -> List Position -> Random.Generator Kurve.State
generateKurveState config numberOfPlayers existingPositions =
    let
        safeSpawnPosition : Random.Generator Position
        safeSpawnPosition =
            generateSpawnPosition config.spawn config.world |> Random.filter (isSafeNewPosition config numberOfPlayers existingPositions)
    in
    Random.map3
        (\generatedPosition generatedAngle generatedHoleSeed ->
            { position = generatedPosition
            , direction = generatedAngle
            , holeStatus =
                makeInitialHoleStatus
                    (World.distanceToTicks config.kurves.tickrate config.kurves.speed)
                    config.kurves.holes
                    generatedHoleSeed
            }
        )
        safeSpawnPosition
        (generateSpawnAngle config.spawn.angleInterval)
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
