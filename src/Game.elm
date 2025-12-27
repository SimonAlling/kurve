module Game exposing
    ( ActiveGameState(..)
    , GameState(..)
    , LiveOrReplay(..)
    , PausedOrNot(..)
    , SpawnState
    , TickResult(..)
    , firstUpdateTick
    , getActiveRound
    , getCurrentRound
    , modifyMidRoundState
    , prepareLiveRound
    , prepareReplayRound
    , prepareRoundFromKnownInitialState
    , reactToTick
    , recordUserInteraction
    , tickResultToGameState
    )

import Color exposing (Color)
import Config exposing (Config, KurveConfig)
import Dialog
import Players exposing (ParticipatingPlayers)
import Random
import RenderAction exposing (WhatToDraw)
import Round exposing (Kurves, Round, RoundInitialState, modifyAlive, modifyDead, roundIsOver)
import Set exposing (Set)
import Spawn exposing (generateHoleSize, generateHoleSpacing, generateKurves)
import Thickness exposing (theThickness)
import Turning exposing (computeAngleChange, computeTurningState, turningStateFromHistory)
import Types.Angle as Angle exposing (Angle)
import Types.Distance as Distance exposing (Distance(..))
import Types.FrameTime exposing (LeftoverFrameTime)
import Types.Kurve as Kurve exposing (Kurve, UserInteraction(..), modifyReversedInteractions)
import Types.Speed as Speed
import Types.Tick as Tick exposing (Tick)
import Types.Tickrate as Tickrate
import Types.TurningState exposing (TurningState)
import World exposing (DrawingPosition, Pixel, Position, distanceToTicks)


type GameState
    = Active LiveOrReplay PausedOrNot ActiveGameState
    | RoundOver Round Dialog.State


type PausedOrNot
    = Paused
    | NotPaused


type ActiveGameState
    = Spawning SpawnState Round
    | Moving LeftoverFrameTime Tick Round


type TickResult a
    = RoundKeepsGoing a
    | RoundEnds Round


getCurrentRound : GameState -> Round
getCurrentRound gameState =
    case gameState of
        Active _ _ activeGameState ->
            getActiveRound activeGameState

        RoundOver round _ ->
            round


getActiveRound : ActiveGameState -> Round
getActiveRound activeGameState =
    case activeGameState of
        Spawning _ round ->
            round

        Moving _ _ round ->
            round


modifyMidRoundState : (Round -> Round) -> GameState -> GameState
modifyMidRoundState f gameState =
    case gameState of
        Active p liveOrReplay (Moving t leftoverFrameTime midRoundState) ->
            Active p liveOrReplay <| Moving t leftoverFrameTime <| f midRoundState

        Active p liveOrReplay (Spawning s midRoundState) ->
            Active p liveOrReplay <| Spawning s <| f midRoundState

        _ ->
            gameState


type LiveOrReplay
    = Live
    | Replay


type alias SpawnState =
    { kurvesLeft : List Kurve
    , alreadySpawnedKurves : List Kurve
    , ticksLeft : Int
    }


firstUpdateTick : Tick
firstUpdateTick =
    -- Any buttons already pressed at round start are treated as having been pressed right before this tick.
    Tick.succ Tick.genesis


prepareLiveRound : Config -> Random.Seed -> ParticipatingPlayers -> Set String -> Round
prepareLiveRound config seed players pressedButtons =
    let
        recordInitialInteractions : List Kurve -> List Kurve
        recordInitialInteractions =
            List.map (recordUserInteraction pressedButtons firstUpdateTick)

        ( theKurves, seedAfterSpawn ) =
            Random.step (generateKurves config players) seed |> Tuple.mapFirst recordInitialInteractions
    in
    prepareRoundFromKnownInitialState { seedAfterSpawn = seedAfterSpawn, spawnedKurves = theKurves }


prepareReplayRound : RoundInitialState -> Round
prepareReplayRound initialState =
    prepareRoundFromKnownInitialState initialState


prepareRoundFromKnownInitialState : RoundInitialState -> Round
prepareRoundFromKnownInitialState initialState =
    let
        theKurves : List Kurve
        theKurves =
            initialState.spawnedKurves

        round : Round
        round =
            { kurves = { alive = theKurves, dead = [] }
            , occupiedPixels = List.foldl (.state >> .position >> World.drawingPosition >> World.pixelsToOccupy >> Set.union) Set.empty theKurves
            , initialState = initialState
            , seed = initialState.seedAfterSpawn
            }
    in
    round


reactToTick : Config -> Tick -> Round -> ( TickResult Round, WhatToDraw )
reactToTick config tick currentRound =
    let
        ( newKurvesGenerator, newOccupiedPixels, newColoredDrawingPositions ) =
            List.foldr
                (checkIndividualKurve config tick)
                ( Random.constant
                    { alive = [] -- We start with the empty list because the new one we'll create may not include all the Kurves from the old one.
                    , dead = currentRound.kurves.dead -- Dead Kurves, however, will not spring to life again.
                    }
                , currentRound.occupiedPixels
                , []
                )
                currentRound.kurves.alive

        ( newKurves, newSeed ) =
            Random.step newKurvesGenerator currentRound.seed

        newCurrentRound : Round
        newCurrentRound =
            { kurves = newKurves
            , occupiedPixels = newOccupiedPixels
            , initialState = currentRound.initialState
            , seed = newSeed
            }

        tickResult : TickResult Round
        tickResult =
            if roundIsOver newKurves then
                RoundEnds newCurrentRound

            else
                RoundKeepsGoing newCurrentRound
    in
    ( tickResult
    , { headDrawing = newKurves.alive
      , bodyDrawing = newColoredDrawingPositions
      }
    )


tickResultToGameState : LiveOrReplay -> TickResult ( LeftoverFrameTime, Tick, Round ) -> GameState
tickResultToGameState liveOrReplay tickResult =
    case tickResult of
        RoundKeepsGoing ( leftoverFrameTime, tick, midRoundState ) ->
            Active liveOrReplay NotPaused (Moving leftoverFrameTime tick midRoundState)

        RoundEnds finishedRound ->
            RoundOver finishedRound Dialog.NotOpen


{-| Takes the distance between the _edges_ of two drawn squares and returns the distance between their _centers_.
-}
computeDistanceBetweenCenters : Distance -> Distance
computeDistanceBetweenCenters distanceBetweenEdges =
    Distance <| Distance.toFloat distanceBetweenEdges + theThickness


checkIndividualKurve :
    Config
    -> Tick
    -> Kurve
    -> ( Random.Generator Kurves, Set World.Pixel, List ( Color, DrawingPosition ) )
    ->
        ( Random.Generator Kurves
        , Set World.Pixel
        , List ( Color, DrawingPosition )
        )
checkIndividualKurve config tick kurve ( checkedKurvesGenerator, occupiedPixels, coloredDrawingPositions ) =
    let
        turningState : TurningState
        turningState =
            turningStateFromHistory tick kurve

        ( newKurveDrawingPositions, checkedKurveGenerator, fate ) =
            updateKurve config turningState occupiedPixels kurve

        occupiedPixelsAfterCheckingThisKurve : Set Pixel
        occupiedPixelsAfterCheckingThisKurve =
            List.foldl
                (World.pixelsToOccupy >> Set.union)
                occupiedPixels
                newKurveDrawingPositions

        coloredDrawingPositionsAfterCheckingThisKurve : List ( Color, DrawingPosition )
        coloredDrawingPositionsAfterCheckingThisKurve =
            coloredDrawingPositions ++ List.map (Tuple.pair kurve.color) newKurveDrawingPositions

        kurvesAfterCheckingThisKurve : Kurve -> Kurves -> Kurves
        kurvesAfterCheckingThisKurve checkedKurve =
            case fate of
                Kurve.Dies ->
                    modifyDead ((::) checkedKurve)

                Kurve.Lives ->
                    modifyAlive ((::) checkedKurve)
    in
    ( Random.map2 kurvesAfterCheckingThisKurve checkedKurveGenerator checkedKurvesGenerator
    , occupiedPixelsAfterCheckingThisKurve
    , coloredDrawingPositionsAfterCheckingThisKurve
    )


evaluateMove : Config -> Position -> Position -> Set Pixel -> Kurve.HoleStatus -> ( List DrawingPosition, Kurve.Fate )
evaluateMove config startingPoint desiredEndPoint occupiedPixels holeStatus =
    let
        startingPointAsDrawingPosition : DrawingPosition
        startingPointAsDrawingPosition =
            World.drawingPosition startingPoint

        positionsToCheck : List DrawingPosition
        positionsToCheck =
            World.desiredDrawingPositions startingPoint desiredEndPoint

        checkPositions : List DrawingPosition -> DrawingPosition -> List DrawingPosition -> ( List DrawingPosition, Kurve.Fate )
        checkPositions checked lastChecked remaining =
            case remaining of
                [] ->
                    ( checked, Kurve.Lives )

                current :: rest ->
                    let
                        theHitbox : Set Pixel
                        theHitbox =
                            World.hitbox lastChecked current

                        crashesIntoWall : Bool
                        crashesIntoWall =
                            List.member True
                                [ current.leftEdge < 0
                                , current.topEdge < 0
                                , current.leftEdge > config.world.width - theThickness
                                , current.topEdge > config.world.height - theThickness
                                ]

                        crashesIntoKurve : Bool
                        crashesIntoKurve =
                            not <| Set.isEmpty <| Set.intersect theHitbox occupiedPixels

                        dies : Bool
                        dies =
                            crashesIntoWall || crashesIntoKurve
                    in
                    if dies then
                        ( checked, Kurve.Dies )

                    else
                        checkPositions (current :: checked) current rest

        isHoly : Bool
        isHoly =
            case holeStatus of
                Kurve.Holy _ ->
                    True

                Kurve.Unholy _ ->
                    False

        ( checkedPositionsReversed, evaluatedStatus ) =
            checkPositions [] startingPointAsDrawingPosition positionsToCheck

        positionsToDraw : List DrawingPosition
        positionsToDraw =
            if isHoly then
                case evaluatedStatus of
                    Kurve.Lives ->
                        []

                    Kurve.Dies ->
                        -- The Kurve's head must always be drawn when they die, even if they are in the middle of a hole.
                        -- If the Kurve couldn't draw at all in this tick, then the last position where the Kurve could draw before dying (and therefore the one to draw to represent the Kurve's death) is this tick's starting point.
                        -- Otherwise, the last position where the Kurve could draw is the last checked position before death occurred.
                        List.singleton <| Maybe.withDefault startingPointAsDrawingPosition <| List.head checkedPositionsReversed

            else
                checkedPositionsReversed
    in
    ( positionsToDraw |> List.reverse, evaluatedStatus )


updateKurve : Config -> TurningState -> Set Pixel -> Kurve -> ( List DrawingPosition, Random.Generator Kurve, Kurve.Fate )
updateKurve config turningState occupiedPixels kurve =
    let
        distanceTraveledSinceLastTick : Float
        distanceTraveledSinceLastTick =
            Speed.toFloat config.kurves.speed / Tickrate.toFloat config.kurves.tickrate

        newDirection : Angle
        newDirection =
            Angle.add kurve.state.direction <| computeAngleChange config.kurves turningState

        ( x, y ) =
            kurve.state.position

        newPosition : Position
        newPosition =
            -- This is based on how the original MS-DOS game works:
            --
            --   * The coordinate system is "flipped" (wrt standard math) such that the Y axis points downwards.
            --   * Directions are zeroed around down, not right as in standard math.
            --
            ( x + distanceTraveledSinceLastTick * Angle.sin newDirection
            , y + distanceTraveledSinceLastTick * Angle.cos newDirection
            )

        ( confirmedDrawingPositions, fate ) =
            evaluateMove
                config
                kurve.state.position
                newPosition
                occupiedPixels
                kurve.state.holeStatus

        newHoleStatusGenerator : Random.Generator Kurve.HoleStatus
        newHoleStatusGenerator =
            updateHoleStatus config.kurves kurve.state.holeStatus

        newKurveState : Random.Generator Kurve.State
        newKurveState =
            newHoleStatusGenerator
                |> Random.map
                    (\newHoleStatus ->
                        { position = newPosition
                        , direction = newDirection
                        , holeStatus = newHoleStatus
                        }
                    )

        newKurve : Random.Generator Kurve
        newKurve =
            newKurveState |> Random.map (\s -> { kurve | state = s })
    in
    ( confirmedDrawingPositions
    , newKurve
    , fate
    )


updateHoleStatus : KurveConfig -> Kurve.HoleStatus -> Random.Generator Kurve.HoleStatus
updateHoleStatus kurveConfig holeStatus =
    case holeStatus of
        Kurve.Holy 0 ->
            generateHoleSpacing kurveConfig.holes |> Random.map (distanceToTicks kurveConfig.tickrate kurveConfig.speed >> Kurve.Unholy)

        Kurve.Holy ticksLeft ->
            Random.constant <| Kurve.Holy (ticksLeft - 1)

        Kurve.Unholy 0 ->
            generateHoleSize kurveConfig.holes |> Random.map (computeDistanceBetweenCenters >> distanceToTicks kurveConfig.tickrate kurveConfig.speed >> Kurve.Holy)

        Kurve.Unholy ticksLeft ->
            Random.constant <| Kurve.Unholy (ticksLeft - 1)


recordUserInteraction : Set String -> Tick -> Kurve -> Kurve
recordUserInteraction pressedButtons nextTick kurve =
    let
        newTurningState : TurningState
        newTurningState =
            computeTurningState pressedButtons kurve
    in
    modifyReversedInteractions ((::) (HappenedBefore nextTick newTurningState)) kurve
