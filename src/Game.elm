module Game exposing
    ( ActiveGameState(..)
    , GameState(..)
    , MidRoundState
    , MidRoundStateVariant(..)
    , Paused(..)
    , SpawnState
    , TickResult(..)
    , firstUpdateTick
    , modifyMidRoundState
    , modifyRound
    , prepareLiveRound
    , prepareReplayRound
    , prepareRoundFromKnownInitialState
    , reactToTick
    , recordUserInteraction
    , tickResultToGameState
    )

import Canvas exposing (bodyDrawingCmd, headDrawingCmd)
import Color exposing (Color)
import Config exposing (Config, KurveConfig)
import Dialog
import Players exposing (ParticipatingPlayers)
import Random
import Round exposing (Kurves, Round, RoundInitialState, modifyAlive, modifyDead, roundIsOver)
import Set exposing (Set)
import Spawn exposing (generateHoleSize, generateHoleSpacing, generateKurves)
import Thickness exposing (theThickness)
import Turning exposing (computeAngleChange, computeTurningState, turningStateFromHistory)
import Types.Angle as Angle exposing (Angle(..))
import Types.Distance as Distance exposing (Distance(..))
import Types.Kurve as Kurve exposing (HoleStatus(..), Kurve, UserInteraction(..), modifyReversedInteractions)
import Types.Speed as Speed
import Types.Tick as Tick exposing (Tick)
import Types.Tickrate as Tickrate
import Types.TurningState exposing (TurningState)
import World exposing (DrawingPosition, Pixel, Position, distanceToTicks)


type GameState
    = Active Paused ActiveGameState
    | RoundOver Round Dialog.State


type Paused
    = Paused
    | NotPaused


type ActiveGameState
    = Spawning SpawnState MidRoundState
    | Moving Tick MidRoundState


type TickResult
    = RoundKeepsGoing Tick MidRoundState
    | RoundEnds Round


modifyMidRoundState : (MidRoundState -> MidRoundState) -> GameState -> GameState
modifyMidRoundState f gameState =
    case gameState of
        Active p (Moving t midRoundState) ->
            Active p <| Moving t <| f midRoundState

        Active p (Spawning s midRoundState) ->
            Active p <| Spawning s <| f midRoundState

        _ ->
            gameState


type alias MidRoundState =
    ( MidRoundStateVariant, Round )


type MidRoundStateVariant
    = Live
    | Replay


modifyRound : (Round -> Round) -> MidRoundState -> MidRoundState
modifyRound =
    Tuple.mapSecond


type alias SpawnState =
    { kurvesLeft : List Kurve
    , ticksLeft : Int
    }


firstUpdateTick : Tick
firstUpdateTick =
    -- Any buttons already pressed at round start are treated as having been pressed right before this tick.
    Tick.succ Tick.genesis


prepareLiveRound : Config -> Random.Seed -> ParticipatingPlayers -> Set String -> MidRoundState
prepareLiveRound config seed players pressedButtons =
    let
        recordInitialInteractions : List Kurve -> List Kurve
        recordInitialInteractions =
            List.map (recordUserInteraction pressedButtons firstUpdateTick)

        ( _, seedAfterSpawn ) =
            Random.step (generateKurves config players) seed |> Tuple.mapFirst recordInitialInteractions

        theKurves =
            [ magenta, cyan, white ]

        magenta : Kurve
        magenta =
            { color = Color.rgba 1 0 1 0.9
            , id = 5
            , controls = ( Set.empty, Set.empty )
            , state =
                { position = ( 115, 147 )
                , direction = Angle (56.78 * (2 * pi / 360))
                , holeStatus = Unholy 60000
                }
            , stateAtSpawn =
                { position = ( 0, 0 )
                , direction = Angle 0
                , holeStatus = Unholy 0
                }
            , reversedInteractions = []
            }

        cyan : Kurve
        cyan =
            { color = Color.rgba 0 1 1 1
            , id = 5
            , controls = ( Set.empty, Set.empty )
            , state =
                { position = ( 140, 296 )
                , direction = Angle 0.202
                , holeStatus = Unholy 60000
                }
            , stateAtSpawn =
                { position = ( 0, 0 )
                , direction = Angle 0
                , holeStatus = Unholy 0
                }
            , reversedInteractions = []
            }

        white : Kurve
        white =
            -- so the others keep going until they crash
            { color = Color.white
            , id = 5
            , controls = ( Set.empty, Set.empty )
            , state =
                { position = ( 50, 400 )
                , direction = Angle 0
                , holeStatus = Unholy 60000
                }
            , stateAtSpawn =
                { position = ( 0, 0 )
                , direction = Angle 0
                , holeStatus = Unholy 0
                }
            , reversedInteractions = []
            }
    in
    ( Replay, prepareRoundFromKnownInitialState { seedAfterSpawn = seedAfterSpawn, spawnedKurves = theKurves } )


prepareReplayRound : RoundInitialState -> MidRoundState
prepareReplayRound initialState =
    ( Replay, prepareRoundFromKnownInitialState initialState )


prepareRoundFromKnownInitialState : RoundInitialState -> Round
prepareRoundFromKnownInitialState initialState =
    let
        theKurves : List Kurve
        theKurves =
            initialState.spawnedKurves

        round : Round
        round =
            { kurves = { alive = theKurves, dead = [] }
            , occupiedPixels = List.foldr (.state >> .position >> World.drawingPosition >> World.pixelsToOccupy >> Set.union) Set.empty theKurves
            , initialState = initialState
            , seed = initialState.seedAfterSpawn
            }
    in
    round


reactToTick : Config -> Tick -> MidRoundState -> ( TickResult, Cmd msg )
reactToTick config tick (( _, currentRound ) as midRoundState) =
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

        tickResult : TickResult
        tickResult =
            if roundIsOver newKurves then
                RoundEnds newCurrentRound

            else
                RoundKeepsGoing tick <| modifyRound (always newCurrentRound) midRoundState
    in
    ( tickResult
    , [ headDrawingCmd newKurves.alive
      , bodyDrawingCmd newColoredDrawingPositions
      ]
        |> Cmd.batch
    )


tickResultToGameState : TickResult -> GameState
tickResultToGameState tickResult =
    case tickResult of
        RoundKeepsGoing tick s ->
            Active NotPaused (Moving tick s)

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
            List.foldr
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
            ( x + distanceTraveledSinceLastTick * Angle.cos newDirection
            , -- The coordinate system is traditionally "flipped" (wrt standard math) such that the Y axis points downwards.
              -- Therefore, we have to use minus instead of plus for the Y-axis calculation.
              y - distanceTraveledSinceLastTick * Angle.sin newDirection
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
