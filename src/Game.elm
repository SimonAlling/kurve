module Game exposing
    ( ActiveGameState(..)
    , GameState(..)
    , MidRoundState
    , MidRoundStateVariant(..)
    , Paused(..)
    , SpawnState
    , TickResult(..)
    , firstUpdateTick
    , getCurrentRound
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
import Thickness exposing (minimumDistanceFor45DegreeDraws, theThickness)
import Turning exposing (computeAngleChange, computeTurningState, turningStateFromHistory)
import Types.Angle as Angle exposing (Angle)
import Types.Distance as Distance exposing (Distance(..))
import Types.FrameTime exposing (LeftoverFrameTime)
import Types.Kurve as Kurve exposing (Kurve, UserInteraction(..), modifyReversedInteractions)
import Types.Speed as Speed
import Types.Tick as Tick exposing (Tick)
import Types.Tickrate as Tickrate
import Types.TurningState exposing (TurningState)
import World exposing (DrawingPosition, Pixel, Position, distanceBetween, distanceToTicks, toPixel)


type GameState
    = Active Paused ActiveGameState
    | RoundOver Round Dialog.State


type Paused
    = Paused
    | NotPaused


type ActiveGameState
    = Spawning SpawnState MidRoundState
    | Moving LeftoverFrameTime Tick MidRoundState


type TickResult a
    = RoundKeepsGoing a
    | RoundEnds Round


getCurrentRound : GameState -> Round
getCurrentRound gameState =
    case gameState of
        Active _ (Spawning _ ( _, round )) ->
            round

        Active _ (Moving _ _ ( _, round )) ->
            round

        RoundOver round _ ->
            round


modifyMidRoundState : (MidRoundState -> MidRoundState) -> GameState -> GameState
modifyMidRoundState f gameState =
    case gameState of
        Active p (Moving t leftoverFrameTime midRoundState) ->
            Active p <| Moving t leftoverFrameTime <| f midRoundState

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

        ( theKurves, seedAfterSpawn ) =
            Random.step (generateKurves config players) seed |> Tuple.mapFirst recordInitialInteractions
    in
    ( Live, prepareRoundFromKnownInitialState { seedAfterSpawn = seedAfterSpawn, spawnedKurves = theKurves } )


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
            , occupiedPixelPositions = List.foldl (.state >> .position >> toPixel >> Set.insert) Set.empty theKurves
            , initialState = initialState
            , seed = initialState.seedAfterSpawn
            }
    in
    round


reactToTick : Config -> Tick -> MidRoundState -> ( TickResult MidRoundState, Cmd msg )
reactToTick config tick (( _, currentRound ) as midRoundState) =
    let
        ( newKurvesGenerator, newOccupiedPixelPositions, newColoredPixelPositions ) =
            List.foldr
                (checkIndividualKurve config tick)
                ( Random.constant
                    { alive = [] -- We start with the empty list because the new one we'll create may not include all the Kurves from the old one.
                    , dead = currentRound.kurves.dead -- Dead Kurves, however, will not spring to life again.
                    }
                , currentRound.occupiedPixelPositions
                , []
                )
                currentRound.kurves.alive

        ( newKurves, newSeed ) =
            Random.step newKurvesGenerator currentRound.seed

        newColoredDrawingPositions : List ( Color, DrawingPosition )
        newColoredDrawingPositions =
            List.map (Tuple.mapSecond World.drawingPosition) newColoredPixelPositions

        newCurrentRound : Round
        newCurrentRound =
            { kurves = newKurves
            , occupiedPixelPositions = newOccupiedPixelPositions
            , initialState = currentRound.initialState
            , seed = newSeed
            }

        tickResult : TickResult MidRoundState
        tickResult =
            if roundIsOver newKurves then
                RoundEnds newCurrentRound

            else
                RoundKeepsGoing <| modifyRound (always newCurrentRound) midRoundState
    in
    ( tickResult
    , [ headDrawingCmd newKurves.alive
      , bodyDrawingCmd newColoredDrawingPositions
      ]
        |> Cmd.batch
    )


tickResultToGameState : TickResult ( LeftoverFrameTime, Tick, MidRoundState ) -> GameState
tickResultToGameState tickResult =
    case tickResult of
        RoundKeepsGoing ( leftoverFrameTime, tick, midRoundState ) ->
            Active NotPaused (Moving leftoverFrameTime tick midRoundState)

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
    -> ( Random.Generator Kurves, Set World.Pixel, List ( Color, Pixel ) )
    ->
        ( Random.Generator Kurves
        , Set World.Pixel
        , List ( Color, Pixel )
        )
checkIndividualKurve config tick kurve ( checkedKurvesGenerator, occupiedPixelPositions, coloredPositions ) =
    let
        turningState : TurningState
        turningState =
            turningStateFromHistory tick kurve

        ( newKurvePixelPositions, checkedKurveGenerator, fate ) =
            updateKurve config turningState occupiedPixelPositions kurve

        occupiedPixelPositionsAfterCheckingThisKurve : Set Pixel
        occupiedPixelPositionsAfterCheckingThisKurve =
            List.foldl
                Set.insert
                occupiedPixelPositions
                newKurvePixelPositions

        coloredPixelPositionsAfterCheckingThisKurve : List ( Color, Pixel )
        coloredPixelPositionsAfterCheckingThisKurve =
            coloredPositions ++ List.map (Tuple.pair kurve.color) newKurvePixelPositions

        kurvesAfterCheckingThisKurve : Kurve -> Kurves -> Kurves
        kurvesAfterCheckingThisKurve checkedKurve =
            case fate of
                Kurve.Dies ->
                    modifyDead ((::) checkedKurve)

                Kurve.Lives ->
                    modifyAlive ((::) checkedKurve)
    in
    ( Random.map2 kurvesAfterCheckingThisKurve checkedKurveGenerator checkedKurvesGenerator
    , occupiedPixelPositionsAfterCheckingThisKurve
    , coloredPixelPositionsAfterCheckingThisKurve
    )


evaluateMove : Config -> Position -> Position -> Set Pixel -> Kurve.HoleStatus -> ( List Pixel, Kurve.Fate )
evaluateMove config startingPoint desiredEndPoint occupiedPixelPositions holeStatus =
    let
        startingPointAsPixel : Pixel
        startingPointAsPixel =
            toPixel startingPoint

        pixelPositionsToCheck : List Pixel
        pixelPositionsToCheck =
            World.desiredPixelPositions startingPoint desiredEndPoint

        checkPositions : List Pixel -> Pixel -> List Pixel -> ( List Pixel, Kurve.Fate )
        checkPositions checked lastChecked remaining =
            case remaining of
                [] ->
                    ( checked, Kurve.Lives )

                current :: rest ->
                    let
                        ( currentX, currentY ) =
                            current

                        crashesIntoWall : Bool
                        crashesIntoWall =
                            let
                                halfThicknessRoundedDown : Int
                                halfThicknessRoundedDown =
                                    -- TODO: explain
                                    theThickness // 2
                            in
                            List.member True
                                [ currentX < halfThicknessRoundedDown
                                , currentY < halfThicknessRoundedDown
                                , currentX > config.world.width - halfThicknessRoundedDown - 1
                                , currentY > config.world.height - halfThicknessRoundedDown - 1
                                ]

                        nearbyPositionsX : List Int
                        nearbyPositionsX =
                            List.range (currentX - theThickness) (currentX + theThickness)

                        nearbyPositionsY : List Int
                        nearbyPositionsY =
                            List.range (currentY - theThickness) (currentY + theThickness)

                        nearbyOccupiedPixelPositions : List Pixel
                        nearbyOccupiedPixelPositions =
                            nearbyPositionsX
                                |> List.concatMap (\x -> nearbyPositionsY |> List.map (\y -> ( x, y )))
                                |> List.filter (\pixel -> Set.member pixel occupiedPixelPositions)

                        crashesIntoKurve : Bool
                        crashesIntoKurve =
                            nearbyOccupiedPixelPositions |> List.any (checkCollision current lastChecked)

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
            checkPositions [] startingPointAsPixel pixelPositionsToCheck

        pixelPositionsToDraw : List Pixel
        pixelPositionsToDraw =
            if isHoly then
                case evaluatedStatus of
                    Kurve.Lives ->
                        []

                    Kurve.Dies ->
                        -- The Kurve's head must always be drawn when they die, even if they are in the middle of a hole.
                        -- If the Kurve couldn't draw at all in this tick, then the last position where the Kurve could draw before dying (and therefore the one to draw to represent the Kurve's death) is this tick's starting point.
                        -- Otherwise, the last position where the Kurve could draw is the last checked position before death occurred.
                        List.singleton <| Maybe.withDefault startingPointAsPixel <| List.head checkedPositionsReversed

            else
                checkedPositionsReversed
    in
    ( pixelPositionsToDraw |> List.reverse, evaluatedStatus )


checkCollision : Pixel -> Pixel -> Pixel -> Bool
checkCollision current lastChecked obstacle =
    let
        is45DegreeDraw : Bool
        is45DegreeDraw =
            Tuple.first current /= Tuple.first lastChecked && Tuple.second current /= Tuple.second lastChecked

        minimumDistanceToObstacle : Float
        minimumDistanceToObstacle =
            if is45DegreeDraw then
                minimumDistanceFor45DegreeDraws

            else
                theThickness

        isTooCloseToObstacle : Bool
        isTooCloseToObstacle =
            Distance.toFloat (distanceBetween current obstacle) < minimumDistanceToObstacle

        isMovingTowardObstacle : Bool
        isMovingTowardObstacle =
            -- Otherwise every Kurve immediately crashes into its own "neck".
            Distance.toFloat (distanceBetween current obstacle) < Distance.toFloat (distanceBetween lastChecked obstacle)
    in
    isTooCloseToObstacle && isMovingTowardObstacle


updateKurve : Config -> TurningState -> Set Pixel -> Kurve -> ( List Pixel, Random.Generator Kurve, Kurve.Fate )
updateKurve config turningState occupiedPixelPositions kurve =
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

        ( confirmedPixelPositions, fate ) =
            evaluateMove
                config
                kurve.state.position
                newPosition
                occupiedPixelPositions
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
    ( confirmedPixelPositions
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
