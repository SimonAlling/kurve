module Game exposing
    ( ActiveGameState(..)
    , GameState(..)
    , LiveOrReplay(..)
    , PausedOrNot(..)
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
import Config exposing (Config)
import Dialog
import Drawing exposing (WhatToDraw, getColorAndDrawingPosition)
import Holes exposing (HoleStatus, Holiness(..), getHoliness, updateHoleStatus)
import Players exposing (ParticipatingPlayers)
import Random
import Round exposing (Kurves, Round, RoundInitialState, modifyAlive, modifyDead, roundIsOver)
import Set exposing (Set)
import Spawn exposing (SpawnState, generateKurves)
import Thickness exposing (theThickness)
import Turning exposing (computeAngleChange, computeTurningState, turningStateFromHistory)
import Types.Angle as Angle exposing (Angle)
import Types.FrameTime exposing (LeftoverFrameTime)
import Types.Kurve as Kurve exposing (Fate(..), Kurve, UserInteraction(..), modifyReversedInteractions)
import Types.Speed as Speed
import Types.Tick as Tick exposing (Tick)
import Types.Tickrate as Tickrate
import Types.TurningState exposing (TurningState)
import World exposing (DrawingPosition, Pixel, Position)


type GameState
    = Active LiveOrReplay PausedOrNot ActiveGameState
    | RoundOver LiveOrReplay PausedOrNot Tick Round Dialog.State


type PausedOrNot
    = Paused
    | NotPaused


type ActiveGameState
    = Spawning LeftoverFrameTime SpawnState Round
    | Moving LeftoverFrameTime Tick Round


type TickResult a
    = RoundKeepsGoing a
    | RoundEnds Tick Round


getCurrentRound : GameState -> Round
getCurrentRound gameState =
    case gameState of
        Active _ _ activeGameState ->
            getActiveRound activeGameState

        RoundOver _ _ _ round _ ->
            round


getActiveRound : ActiveGameState -> Round
getActiveRound activeGameState =
    case activeGameState of
        Spawning _ _ round ->
            round

        Moving _ _ round ->
            round


modifyMidRoundState : (Round -> Round) -> GameState -> GameState
modifyMidRoundState f gameState =
    case gameState of
        Active liveOrReplay p (Moving t leftoverFrameTime midRoundState) ->
            Active liveOrReplay p <| Moving t leftoverFrameTime <| f midRoundState

        Active liveOrReplay p (Spawning l s midRoundState) ->
            Active liveOrReplay p <| Spawning l s <| f midRoundState

        _ ->
            gameState


type LiveOrReplay
    = Live
    | Replay


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
            , occupiedPixels = initialOccupiedPixels theKurves
            , initialState = initialState
            , seed = initialState.seedAfterSpawn
            }
    in
    round


initialOccupiedPixels : List Kurve -> Set Pixel
initialOccupiedPixels =
    let
        placeKurve : Kurve -> Set Pixel -> Set Pixel
        placeKurve kurve =
            kurve.state.position
                |> World.drawingPosition
                |> World.occupyDrawingPosition
    in
    List.foldl placeKurve Set.empty


reactToTick : Config -> Tick -> Round -> ( TickResult Round, WhatToDraw )
reactToTick config tick currentRound =
    let
        ( newKurves, newOccupiedPixels, newColoredDrawingPositions ) =
            List.foldr
                (checkIndividualKurve config tick)
                ( { alive = [] -- We start with the empty list because the new one we'll create may not include all the Kurves from the old one.
                  , dead = currentRound.kurves.dead -- Dead Kurves, however, will not spring to life again.
                  }
                , currentRound.occupiedPixels
                , []
                )
                currentRound.kurves.alive

        newCurrentRound : Round
        newCurrentRound =
            { kurves = newKurves
            , occupiedPixels = newOccupiedPixels
            , initialState = currentRound.initialState
            , seed = currentRound.seed
            }

        tickResult : TickResult Round
        tickResult =
            if roundIsOver newKurves then
                RoundEnds tick newCurrentRound

            else
                RoundKeepsGoing newCurrentRound
    in
    ( tickResult
    , { headDrawing = newKurves.alive |> List.map getColorAndDrawingPosition
      , bodyDrawing = newColoredDrawingPositions
      }
    )


tickResultToGameState : LiveOrReplay -> PausedOrNot -> TickResult ( LeftoverFrameTime, Tick, Round ) -> GameState
tickResultToGameState liveOrReplay pausedOrNot tickResult =
    case tickResult of
        RoundKeepsGoing ( leftoverFrameTime, tick, midRoundState ) ->
            Active liveOrReplay pausedOrNot (Moving leftoverFrameTime tick midRoundState)

        RoundEnds tickThatEndedIt finishedRound ->
            RoundOver liveOrReplay pausedOrNot tickThatEndedIt finishedRound Dialog.NotOpen


checkIndividualKurve :
    Config
    -> Tick
    -> Kurve
    -> ( Kurves, Set World.Pixel, List ( Color, DrawingPosition ) )
    ->
        ( Kurves
        , Set World.Pixel
        , List ( Color, DrawingPosition )
        )
checkIndividualKurve config tick kurve ( checkedKurves, occupiedPixels, coloredDrawingPositions ) =
    let
        turningState : TurningState
        turningState =
            turningStateFromHistory tick kurve

        ( newKurveDrawingPositions, checkedKurve, fate ) =
            updateKurve config turningState occupiedPixels kurve

        occupiedPixelsAfterCheckingThisKurve : Set Pixel
        occupiedPixelsAfterCheckingThisKurve =
            List.foldl
                World.occupyDrawingPosition
                occupiedPixels
                newKurveDrawingPositions

        coloredDrawingPositionsAfterCheckingThisKurve : List ( Color, DrawingPosition )
        coloredDrawingPositionsAfterCheckingThisKurve =
            List.map (Tuple.pair kurve.color) newKurveDrawingPositions ++ coloredDrawingPositions

        kurvesAfterCheckingThisKurve : Kurves -> Kurves
        kurvesAfterCheckingThisKurve =
            case fate of
                Dies ->
                    modifyDead ((::) checkedKurve)

                Lives ->
                    modifyAlive ((::) checkedKurve)
    in
    ( kurvesAfterCheckingThisKurve checkedKurves
    , occupiedPixelsAfterCheckingThisKurve
    , coloredDrawingPositionsAfterCheckingThisKurve
    )


type alias HolinessTransition =
    { oldHoliness : Holiness
    , newHoliness : Holiness
    }


evaluateMove : Config -> Position -> Position -> Set Pixel -> HolinessTransition -> ( List DrawingPosition, Fate )
evaluateMove config startingPoint desiredEndPoint occupiedPixels holinessTransition =
    let
        startingPointAsDrawingPosition : DrawingPosition
        startingPointAsDrawingPosition =
            World.drawingPosition startingPoint

        positionsToCheck : List DrawingPosition
        positionsToCheck =
            World.desiredDrawingPositions startingPoint desiredEndPoint

        checkPositions : List DrawingPosition -> DrawingPosition -> List DrawingPosition -> ( List DrawingPosition, Fate )
        checkPositions checked lastChecked remaining =
            case remaining of
                [] ->
                    ( checked, Lives )

                current :: rest ->
                    let
                        theHitbox : Set Pixel
                        theHitbox =
                            World.hitbox lastChecked current

                        crashesIntoWall : Bool
                        crashesIntoWall =
                            List.member True
                                [ current.x < 0
                                , current.y < 0
                                , current.x > config.world.width - theThickness
                                , current.y > config.world.height - theThickness
                                ]

                        crashesIntoKurve : Bool
                        crashesIntoKurve =
                            not <| Set.isEmpty <| Set.intersect theHitbox occupiedPixels

                        dies : Bool
                        dies =
                            crashesIntoWall || crashesIntoKurve
                    in
                    if dies then
                        ( checked, Dies )

                    else
                        checkPositions (current :: checked) current rest

        ( checkedPositionsReversed, evaluatedStatus ) =
            checkPositions [] startingPointAsDrawingPosition positionsToCheck

        { oldHoliness, newHoliness } =
            holinessTransition

        positionsToDraw : List DrawingPosition
        positionsToDraw =
            case ( evaluatedStatus, newHoliness ) of
                ( Lives, Holy ) ->
                    -- The Kurve lives and is holy. Nothing to draw.
                    []

                ( Lives, Solid ) ->
                    -- The Kurve lives and is solid. Draw everything it wanted to draw.
                    checkedPositionsReversed

                ( Dies, Holy ) ->
                    case oldHoliness of
                        Holy ->
                            -- The Kurve died in the middle of a hole. Draw the last position it could be at.
                            -- If the Kurve couldn't move at all in this tick, then the last position where the Kurve could be before dying (and therefore the one to draw to represent the Kurve's death) is this tick's starting point.
                            -- Otherwise, the last position where the Kurve could be is the last checked position before death occurred.
                            List.singleton <| Maybe.withDefault startingPointAsDrawingPosition <| List.head checkedPositionsReversed

                        Solid ->
                            -- The Kurve died as it opened a hole. Draw the last position it could be at, but no need to default to the starting point because it must have been drawn in the previous tick.
                            List.take 1 checkedPositionsReversed

                ( Dies, Solid ) ->
                    case oldHoliness of
                        Holy ->
                            -- The Kurve died as it closed a hole. Draw all positions it could be at.
                            -- If the Kurve couldn't move at all in this tick, then the last position where the Kurve could be before dying (and therefore the one to draw to represent the Kurve's death) is this tick's starting point.
                            if List.isEmpty checkedPositionsReversed then
                                List.singleton startingPointAsDrawingPosition

                            else
                                checkedPositionsReversed

                        Solid ->
                            -- The Kurve died in the middle of a solid segment. Draw all positions it could be at.
                            checkedPositionsReversed
    in
    ( positionsToDraw |> List.reverse, evaluatedStatus )


updateKurve : Config -> TurningState -> Set Pixel -> Kurve -> ( List DrawingPosition, Kurve, Fate )
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
                { oldHoliness = getHoliness kurve.state.holeStatus
                , newHoliness = getHoliness newHoleStatus
                }

        newHoleStatus : HoleStatus
        newHoleStatus =
            updateHoleStatus config.kurves kurve.state.holeStatus

        newKurveState : Kurve.State
        newKurveState =
            { position = newPosition
            , direction = newDirection
            , holeStatus = newHoleStatus
            }

        newKurve : Kurve
        newKurve =
            { kurve | state = newKurveState }
    in
    ( confirmedDrawingPositions
    , newKurve
    , fate
    )


recordUserInteraction : Set String -> Tick -> Kurve -> Kurve
recordUserInteraction pressedButtons nextTick kurve =
    let
        newTurningState : TurningState
        newTurningState =
            computeTurningState pressedButtons kurve
    in
    modifyReversedInteractions ((::) (HappenedBefore nextTick newTurningState)) kurve
