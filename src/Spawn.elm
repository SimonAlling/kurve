module Spawn exposing (generateHoleSize, generateHoleSpacing, generatePlayers)

import Config
import Input exposing (toStringSetControls)
import Random
import Random.Extra as Random
import Types.Angle exposing (Angle(..))
import Types.Distance as Distance exposing (Distance(..))
import Types.Player as Player exposing (Player)
import Types.Radius as Radius exposing (Radius(..))
import Types.Thickness as Thickness exposing (Thickness(..))
import World exposing (Position, distanceToTicks)


generatePlayers : List Config.PlayerConfig -> Random.Generator (List Player)
generatePlayers configs =
    let
        numberOfPlayers =
            List.length configs

        generateNewAndPrepend : Config.PlayerConfig -> List Player -> Random.Generator (List Player)
        generateNewAndPrepend config precedingPlayers =
            generatePlayer numberOfPlayers (List.map .position precedingPlayers) config
                |> Random.map (\player -> player :: precedingPlayers)

        generateReversedPlayers =
            List.foldl
                (Random.andThen << generateNewAndPrepend)
                (Random.constant [])
                configs
    in
    generateReversedPlayers |> Random.map List.reverse


isSafeNewPosition : Int -> List Position -> Position -> Bool
isSafeNewPosition numberOfPlayers existingPositions newPosition =
    List.all (not << isTooCloseFor numberOfPlayers newPosition) existingPositions


isTooCloseFor : Int -> Position -> Position -> Bool
isTooCloseFor numberOfPlayers point1 point2 =
    let
        desiredMinimumDistance =
            toFloat (Thickness.toInt Config.thickness) + Radius.toFloat Config.turningRadius * Config.desiredMinimumSpawnDistanceTurningRadiusFactor

        ( ( left, top ), ( right, bottom ) ) =
            spawnArea

        availableArea =
            (right - left) * (bottom - top)

        -- Derived from:
        -- audacity × total available area > number of players × ( max allowed minimum distance / 2 )² × pi
        maxAllowedMinimumDistance =
            2 * sqrt (Config.spawnProtectionAudacity * availableArea / (toFloat numberOfPlayers * pi))
    in
    Distance.toFloat (distanceBetween point1 point2) < min desiredMinimumDistance maxAllowedMinimumDistance


distanceBetween : Position -> Position -> Distance
distanceBetween ( x1, y1 ) ( x2, y2 ) =
    Distance <| sqrt ((x2 - x1) ^ 2 + (y2 - y1) ^ 2)


generatePlayer : Int -> List Position -> Config.PlayerConfig -> Random.Generator Player
generatePlayer numberOfPlayers existingPositions config =
    let
        safeSpawnPosition =
            generateSpawnPosition |> Random.filter (isSafeNewPosition numberOfPlayers existingPositions)
    in
    Random.map3
        (\generatedPosition generatedAngle generatedHoleStatus ->
            { color = config.color
            , controls = toStringSetControls config.controls
            , position = generatedPosition
            , direction = generatedAngle
            , holeStatus = generatedHoleStatus
            }
        )
        safeSpawnPosition
        generateSpawnAngle
        generateInitialHoleStatus


spawnArea : ( Position, Position )
spawnArea =
    let
        topLeft =
            ( Config.spawnMargin
            , Config.spawnMargin
            )

        bottomRight =
            ( toFloat Config.worldWidth - Config.spawnMargin
            , toFloat Config.worldHeight - Config.spawnMargin
            )
    in
    ( topLeft, bottomRight )


generateSpawnPosition : Random.Generator Position
generateSpawnPosition =
    let
        ( ( left, top ), ( right, bottom ) ) =
            spawnArea
    in
    Random.pair (Random.float left right) (Random.float top bottom)


generateSpawnAngle : Random.Generator Angle
generateSpawnAngle =
    Random.float (-pi / 2) (pi / 2) |> Random.map Angle


generateHoleSpacing : Random.Generator Distance
generateHoleSpacing =
    Distance.generate Config.holes.minInterval Config.holes.maxInterval


generateHoleSize : Random.Generator Distance
generateHoleSize =
    Distance.generate Config.holes.minSize Config.holes.maxSize


generateInitialHoleStatus : Random.Generator Player.HoleStatus
generateInitialHoleStatus =
    generateHoleSpacing |> Random.map (distanceToTicks Config.speed >> Player.Unholy)
