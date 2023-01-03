module Game exposing (GameState(..), MidRoundState, MidRoundStateVariant(..), SpawnState, checkIndividualKurve, firstUpdateTick, modifyMidRoundState, modifyRound, prepareLiveRound, prepareReplayRound, recordUserInteraction)

import Color exposing (Color)
import Config exposing (Config, KurveConfig)
import Players exposing (ParticipatingPlayers)
import Random
import Round exposing (Kurves, Round, RoundInitialState, modifyAlive, modifyDead)
import Set exposing (Set)
import Spawn exposing (generateHoleSize, generateHoleSpacing, generateKurves)
import Turning exposing (computeAngleChange, computeTurningState, turningStateFromHistory)
import Types.Angle as Angle exposing (Angle)
import Types.Distance as Distance exposing (Distance(..))
import Types.Kurve as Kurve exposing (Kurve, UserInteraction(..), modifyReversedInteractions)
import Types.Speed as Speed
import Types.Thickness as Thickness exposing (Thickness)
import Types.Tick as Tick exposing (Tick)
import Types.Tickrate as Tickrate
import Types.TurningState exposing (TurningState)
import World exposing (DrawingPosition, Pixel, Position, distanceToTicks)


type GameState
    = MidRound Tick MidRoundState
    | PostRound Round
    | PreRound SpawnState MidRoundState


modifyMidRoundState : (MidRoundState -> MidRoundState) -> GameState -> GameState
modifyMidRoundState f gameState =
    case gameState of
        MidRound t midRoundState ->
            MidRound t <| f midRoundState

        PreRound s midRoundState ->
            PreRound s <| f midRoundState

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
    ( Live, prepareRoundHelper config { seedAfterSpawn = seedAfterSpawn, spawnedKurves = theKurves, pressedButtons = pressedButtons } )


prepareReplayRound : Config -> RoundInitialState -> MidRoundState
prepareReplayRound config initialState =
    ( Replay, prepareRoundHelper config initialState )


prepareRoundHelper : Config -> RoundInitialState -> Round
prepareRoundHelper config initialState =
    let
        theKurves : List Kurve
        theKurves =
            initialState.spawnedKurves

        thickness : Thickness
        thickness =
            config.kurves.thickness

        round : Round
        round =
            { kurves = { alive = theKurves, dead = [] }
            , occupiedPixels = List.foldr (.state >> .position >> World.drawingPosition thickness >> World.pixelsToOccupy thickness >> Set.union) Set.empty theKurves
            , history =
                { initialState = initialState
                }
            , seed = initialState.seedAfterSpawn
            }
    in
    round


{-| Takes the distance between the _edges_ of two drawn squares and returns the distance between their _centers_.
-}
computeDistanceBetweenCenters : Thickness -> Distance -> Distance
computeDistanceBetweenCenters thickness distanceBetweenEdges =
    Distance <| Distance.toFloat distanceBetweenEdges + toFloat (Thickness.toInt thickness)


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
                (World.pixelsToOccupy config.kurves.thickness >> Set.union)
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


evaluateMove : Config -> DrawingPosition -> List DrawingPosition -> Set Pixel -> Kurve.HoleStatus -> ( List DrawingPosition, Kurve.Fate )
evaluateMove config startingPoint positionsToCheck occupiedPixels holeStatus =
    let
        checkPositions : List DrawingPosition -> DrawingPosition -> List DrawingPosition -> ( List DrawingPosition, Kurve.Fate )
        checkPositions checked lastChecked remaining =
            case remaining of
                [] ->
                    ( checked, Kurve.Lives )

                current :: rest ->
                    let
                        theHitbox : Set Pixel
                        theHitbox =
                            World.hitbox config.kurves.thickness lastChecked current

                        thickness : Int
                        thickness =
                            Thickness.toInt config.kurves.thickness

                        drawsOutsideWorld : Bool
                        drawsOutsideWorld =
                            List.any ((==) True)
                                [ current.leftEdge < 0
                                , current.topEdge < 0
                                , current.leftEdge > config.world.width - thickness
                                , current.topEdge > config.world.height - thickness
                                ]

                        dies : Bool
                        dies =
                            drawsOutsideWorld || (not <| Set.isEmpty <| Set.intersect theHitbox occupiedPixels)
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
            checkPositions [] startingPoint positionsToCheck

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
                        List.singleton <| Maybe.withDefault startingPoint <| List.head checkedPositionsReversed

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

        thickness : Thickness
        thickness =
            config.kurves.thickness

        ( confirmedDrawingPositions, fate ) =
            evaluateMove
                config
                (World.drawingPosition thickness kurve.state.position)
                (World.desiredDrawingPositions thickness kurve.state.position newPosition)
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
            generateHoleSize kurveConfig.holes |> Random.map (computeDistanceBetweenCenters kurveConfig.thickness >> distanceToTicks kurveConfig.tickrate kurveConfig.speed >> Kurve.Holy)

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
