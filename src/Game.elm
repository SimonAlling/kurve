module Game exposing (GameState(..), MidRoundState, MidRoundStateVariant(..), SpawnState, extractRound, firstUpdateTick, modifyMidRoundState, modifyRound, prepareLiveRound, prepareReplayRound, recordUserInteraction, updatePlayer)

import Config exposing (config)
import Random
import Round exposing (Round, RoundInitialState)
import Set exposing (Set)
import Spawn exposing (generateHoleSize, generateHoleSpacing, generatePlayers)
import Turning exposing (computeAngleChange, computeTurningState)
import Types.Angle as Angle
import Types.Distance as Distance exposing (Distance(..))
import Types.Player as Player exposing (Player, UserInteraction(..), modifyReversedInteractions)
import Types.Speed as Speed exposing (Speed)
import Types.Thickness as Thickness
import Types.Tick as Tick exposing (Tick)
import Types.Tickrate as Tickrate
import Types.TurningState exposing (TurningState)
import World exposing (DrawingPosition, Pixel, Position, distanceToTicks)


type GameState
    = MidRound Tick MidRoundState
    | PostRound Round
    | PreRound SpawnState MidRoundState
    | Lobby Random.Seed


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


extractRound : MidRoundState -> Round
extractRound =
    Tuple.second


modifyRound : (Round -> Round) -> MidRoundState -> MidRoundState
modifyRound =
    Tuple.mapSecond


type alias SpawnState =
    { playersLeft : List Player
    , ticksLeft : Int
    }


firstUpdateTick : Tick
firstUpdateTick =
    -- Any buttons already pressed at round start are treated as having been pressed right before this tick.
    Tick.succ Tick.genesis


prepareLiveRound : Random.Seed -> Set String -> MidRoundState
prepareLiveRound seed pressedButtons =
    let
        recordInitialInteractions : List Player -> List Player
        recordInitialInteractions =
            List.map (recordUserInteraction pressedButtons firstUpdateTick)

        ( thePlayers, seedAfterSpawn ) =
            Random.step (generatePlayers config) seed |> Tuple.mapFirst recordInitialInteractions
    in
    ( Live, prepareRoundHelper { seedAfterSpawn = seedAfterSpawn, spawnedPlayers = thePlayers, pressedButtons = pressedButtons } )


prepareReplayRound : RoundInitialState -> MidRoundState
prepareReplayRound initialState =
    ( Replay, prepareRoundHelper initialState )


prepareRoundHelper : RoundInitialState -> Round
prepareRoundHelper initialState =
    let
        thePlayers : List Player
        thePlayers =
            initialState.spawnedPlayers

        thickness : Thickness.Thickness
        thickness =
            config.kurves.thickness

        round : Round
        round =
            { players = { alive = thePlayers, dead = [] }
            , occupiedPixels = List.foldr (.state >> .position >> World.drawingPosition thickness >> World.pixelsToOccupy thickness >> Set.union) Set.empty thePlayers
            , history =
                { initialState = initialState
                }
            , seed = initialState.seedAfterSpawn
            }
    in
    round


{-| Takes the distance between the _edges_ of two drawn squares and returns the distance between their _centers_.
-}
computeDistanceBetweenCenters : Distance -> Distance
computeDistanceBetweenCenters distanceBetweenEdges =
    Distance <| Distance.toFloat distanceBetweenEdges + toFloat (Thickness.toInt config.kurves.thickness)


evaluateMove : DrawingPosition -> List DrawingPosition -> Set Pixel -> Player.HoleStatus -> ( List DrawingPosition, Player.Fate )
evaluateMove startingPoint positionsToCheck occupiedPixels holeStatus =
    let
        checkPositions : List DrawingPosition -> DrawingPosition -> List DrawingPosition -> ( List DrawingPosition, Player.Fate )
        checkPositions checked lastChecked remaining =
            case remaining of
                [] ->
                    ( checked, Player.Lives )

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
                        ( checked, Player.Dies )

                    else
                        checkPositions (current :: checked) current rest

        isHoly : Bool
        isHoly =
            case holeStatus of
                Player.Holy _ ->
                    True

                Player.Unholy _ ->
                    False

        ( checkedPositionsReversed, evaluatedStatus ) =
            checkPositions [] startingPoint positionsToCheck

        positionsToDraw : List DrawingPosition
        positionsToDraw =
            if isHoly then
                case evaluatedStatus of
                    Player.Lives ->
                        []

                    Player.Dies ->
                        -- The player's head must always be drawn when they die, even if they are in the middle of a hole.
                        -- If the player couldn't draw at all in this tick, then the last position where the player could draw before dying (and therefore the one to draw to represent the player's death) is this tick's starting point.
                        -- Otherwise, the last position where the player could draw is the last checked position before death occurred.
                        List.singleton <| Maybe.withDefault startingPoint <| List.head checkedPositionsReversed

            else
                checkedPositionsReversed
    in
    ( positionsToDraw |> List.reverse, evaluatedStatus )


updatePlayer : TurningState -> Set Pixel -> Player -> ( List DrawingPosition, Random.Generator Player, Player.Fate )
updatePlayer turningState occupiedPixels player =
    let
        distanceTraveledSinceLastTick : Float
        distanceTraveledSinceLastTick =
            Speed.toFloat config.kurves.speed / Tickrate.toFloat config.kurves.tickrate

        newDirection : Angle.Angle
        newDirection =
            Angle.add player.state.direction <| computeAngleChange config.kurves turningState

        ( x, y ) =
            player.state.position

        newPosition : Position
        newPosition =
            ( x + distanceTraveledSinceLastTick * Angle.cos newDirection
            , -- The coordinate system is traditionally "flipped" (wrt standard math) such that the Y axis points downwards.
              -- Therefore, we have to use minus instead of plus for the Y-axis calculation.
              y - distanceTraveledSinceLastTick * Angle.sin newDirection
            )

        thickness : Thickness.Thickness
        thickness =
            config.kurves.thickness

        ( confirmedDrawingPositions, fate ) =
            evaluateMove
                (World.drawingPosition thickness player.state.position)
                (World.desiredDrawingPositions thickness player.state.position newPosition)
                occupiedPixels
                player.state.holeStatus

        newHoleStatusGenerator : Random.Generator Player.HoleStatus
        newHoleStatusGenerator =
            updateHoleStatus config.kurves.speed player.state.holeStatus

        newPlayerState : Random.Generator Player.State
        newPlayerState =
            newHoleStatusGenerator
                |> Random.map
                    (\newHoleStatus ->
                        { position = newPosition
                        , direction = newDirection
                        , holeStatus = newHoleStatus
                        }
                    )

        newPlayer : Random.Generator Player
        newPlayer =
            newPlayerState |> Random.map (\s -> { player | state = s })
    in
    ( confirmedDrawingPositions
    , newPlayer
    , fate
    )


updateHoleStatus : Speed -> Player.HoleStatus -> Random.Generator Player.HoleStatus
updateHoleStatus speed holeStatus =
    case holeStatus of
        Player.Holy 0 ->
            generateHoleSpacing config.kurves.holes |> Random.map (distanceToTicks config.kurves.tickrate speed >> Player.Unholy)

        Player.Holy ticksLeft ->
            Random.constant <| Player.Holy (ticksLeft - 1)

        Player.Unholy 0 ->
            generateHoleSize config.kurves.holes |> Random.map (computeDistanceBetweenCenters >> distanceToTicks config.kurves.tickrate speed >> Player.Holy)

        Player.Unholy ticksLeft ->
            Random.constant <| Player.Unholy (ticksLeft - 1)


recordUserInteraction : Set String -> Tick -> Player -> Player
recordUserInteraction pressedButtons nextTick player =
    let
        newTurningState : TurningState
        newTurningState =
            computeTurningState pressedButtons player
    in
    modifyReversedInteractions ((::) (HappenedBefore nextTick newTurningState)) player
