module Spawn exposing
    ( generateHoleSize
    , generateHoleSpacing
    , generateKurves
    )

import Config exposing (Config, HoleConfig, KurveConfig, SpawnConfig, WorldConfig)
import Dict
import Input exposing (toStringSetControls)
import Players exposing (ParticipatingPlayers)
import Random
import Random.Extra as Random
import Types.Angle exposing (Angle(..))
import Types.Distance as Distance exposing (Distance)
import Types.Kurve as Kurve exposing (Kurve)
import Types.Player exposing (Player)
import Types.PlayerId exposing (PlayerId)
import Types.Radius as Radius
import Types.Thickness as Thickness
import Util exposing (curry)
import World exposing (Position, distanceBetween, distanceToTicks)


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

        generateReversedKurves : Random.Generator (List Kurve)
        generateReversedKurves =
            Dict.foldl
                (\id ( player, _ ) -> curry (Random.andThen << generateNewAndPrepend) id player)
                (Random.constant [])
                players
    in
    generateReversedKurves |> Random.map List.reverse


isSafeNewPosition : Config -> Int -> List Position -> Position -> Bool
isSafeNewPosition config numberOfPlayers existingPositions newPosition =
    List.all (not << isTooCloseFor numberOfPlayers config newPosition) existingPositions


isTooCloseFor : Int -> Config -> Position -> Position -> Bool
isTooCloseFor numberOfPlayers config point1 point2 =
    let
        desiredMinimumDistance : Float
        desiredMinimumDistance =
            toFloat (Thickness.toInt config.kurves.thickness) + Radius.toFloat config.kurves.turningRadius * config.spawn.desiredMinimumDistanceTurningRadiusFactor

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
    let
        safeSpawnPosition : Random.Generator Position
        safeSpawnPosition =
            generateSpawnPosition config.spawn config.world |> Random.filter (isSafeNewPosition config numberOfPlayers existingPositions)
    in
    Random.map3
        (\generatedPosition generatedAngle generatedHoleStatus ->
            let
                state : Kurve.State
                state =
                    { position = generatedPosition
                    , direction = generatedAngle
                    , holeStatus = generatedHoleStatus
                    }
            in
            { color = player.color
            , id = id
            , controls = toStringSetControls player.controls
            , state = state
            , stateAtSpawn = state
            , reversedInteractions = []
            }
        )
        safeSpawnPosition
        (generateSpawnAngle config.spawn.angleInterval)
        (generateInitialHoleStatus config.kurves)


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


generateHoleSpacing : HoleConfig -> Random.Generator Distance
generateHoleSpacing holeConfig =
    Distance.generate holeConfig.minInterval holeConfig.maxInterval


generateHoleSize : HoleConfig -> Random.Generator Distance
generateHoleSize holeConfig =
    Distance.generate holeConfig.minSize holeConfig.maxSize


generateInitialHoleStatus : KurveConfig -> Random.Generator Kurve.HoleStatus
generateInitialHoleStatus { tickrate, speed, holes } =
    generateHoleSpacing holes |> Random.map (distanceToTicks tickrate speed >> Kurve.Unholy)
