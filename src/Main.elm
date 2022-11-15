module Main exposing (main)

import Canvas exposing (bodyDrawingCmds, clearEverything, clearOverlay, drawSpawnIfAndOnlyIf, headDrawingCmds)
import Color exposing (Color)
import Config exposing (config)
import Input exposing (Button(..), ButtonDirection(..), inputSubscriptions, updatePressedButtons)
import Platform exposing (worker)
import Random
import Random.Extra as Random
import Round exposing (Players, Round, RoundInitialState, initialStateForReplaying, modifyAlive, modifyDead, modifyPlayers, roundIsOver)
import Set exposing (Set(..))
import Spawn exposing (generateHoleSize, generateHoleSpacing, generatePlayers)
import Time
import Turning exposing (computeAngleChange, computeTurningState, turningStateFromHistory)
import Types.Angle as Angle exposing (Angle(..))
import Types.Distance as Distance exposing (Distance(..))
import Types.Player as Player exposing (Player, UserInteraction(..), modifyReversedInteractions)
import Types.Speed as Speed exposing (Speed(..))
import Types.Thickness as Thickness exposing (Thickness(..))
import Types.Tick as Tick exposing (Tick(..))
import Types.Tickrate as Tickrate exposing (Tickrate(..))
import Types.TurningState exposing (TurningState)
import Util exposing (isEven)
import World exposing (DrawingPosition, Pixel, distanceToTicks)


type alias Model =
    { pressedButtons : Set String
    , gameState : GameState
    }


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


type MidRoundState
    = Live Round
    | Replay Round


modifyRound : (Round -> Round) -> MidRoundState -> MidRoundState
modifyRound f midRoundState =
    case midRoundState of
        Live round ->
            Live <| f round

        Replay round ->
            Replay <| f round


type alias SpawnState =
    { playersLeft : List Player
    , ticksLeft : Int
    }


firstUpdateTick : Tick
firstUpdateTick =
    -- Any buttons already pressed at round start are treated as having been pressed right before this tick.
    Tick.succ Tick.genesis


init : () -> ( Model, Cmd Msg )
init _ =
    ( { pressedButtons = Set.empty
      , gameState = Lobby (Random.initialSeed 1337)
      }
    , Cmd.none
    )


startRound : Model -> MidRoundState -> ( Model, Cmd msg )
startRound model midRoundState =
    let
        ( gameState, cmd ) =
            newRoundGameStateAndCmd midRoundState
    in
    ( { model | gameState = gameState }, cmd )


newRoundGameStateAndCmd : MidRoundState -> ( GameState, Cmd msg )
newRoundGameStateAndCmd plannedMidRoundState =
    ( PreRound
        { playersLeft = extractRound plannedMidRoundState |> .players |> .alive
        , ticksLeft = config.spawn.numberOfFlickerTicks
        }
        plannedMidRoundState
    , clearEverything ( config.world.width, config.world.height )
    )


prepareLiveRound : Random.Seed -> Set String -> MidRoundState
prepareLiveRound seed pressedButtons =
    let
        recordInitialInteractions =
            List.map (recordUserInteraction pressedButtons firstUpdateTick)

        ( thePlayers, seedAfterSpawn ) =
            Random.step (generatePlayers config) seed |> Tuple.mapFirst recordInitialInteractions
    in
    Live <| prepareRoundHelper { seedAfterSpawn = seedAfterSpawn, spawnedPlayers = thePlayers, pressedButtons = pressedButtons }


prepareReplayRound : RoundInitialState -> MidRoundState
prepareReplayRound initialState =
    Replay <| prepareRoundHelper initialState


prepareRoundHelper : RoundInitialState -> Round
prepareRoundHelper initialState =
    let
        thePlayers =
            initialState.spawnedPlayers

        thickness =
            config.kurves.thickness

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


type Msg
    = GameTick Tick MidRoundState
    | ButtonUsed ButtonDirection Button
    | SpawnTick SpawnState MidRoundState


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
                        theHitbox =
                            World.hitbox config.kurves.thickness lastChecked current

                        thickness =
                            Thickness.toInt config.kurves.thickness

                        drawsOutsideWorld =
                            List.any ((==) True)
                                [ current.leftEdge < 0
                                , current.topEdge < 0
                                , current.leftEdge > config.world.width - thickness
                                , current.topEdge > config.world.height - thickness
                                ]

                        dies =
                            drawsOutsideWorld || (not <| Set.isEmpty <| Set.intersect theHitbox occupiedPixels)
                    in
                    if dies then
                        ( checked, Player.Dies )

                    else
                        checkPositions (current :: checked) current rest

        isHoly =
            case holeStatus of
                Player.Holy _ ->
                    True

                Player.Unholy _ ->
                    False

        ( checkedPositionsReversed, evaluatedStatus ) =
            checkPositions [] startingPoint positionsToCheck

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
        distanceTraveledSinceLastTick =
            Speed.toFloat config.kurves.speed / Tickrate.toFloat config.kurves.tickrate

        newDirection =
            Angle.add player.state.direction <| computeAngleChange config.kurves turningState

        ( x, y ) =
            player.state.position

        newPosition =
            ( x + distanceTraveledSinceLastTick * Angle.cos newDirection
            , -- The coordinate system is traditionally "flipped" (wrt standard math) such that the Y axis points downwards.
              -- Therefore, we have to use minus instead of plus for the Y-axis calculation.
              y - distanceTraveledSinceLastTick * Angle.sin newDirection
            )

        thickness =
            config.kurves.thickness

        ( confirmedDrawingPositions, fate ) =
            evaluateMove
                (World.drawingPosition thickness player.state.position)
                (World.desiredDrawingPositions thickness player.state.position newPosition)
                occupiedPixels
                player.state.holeStatus

        newHoleStatusGenerator =
            updateHoleStatus config.kurves.speed player.state.holeStatus

        newPlayerState =
            newHoleStatusGenerator
                |> Random.map
                    (\newHoleStatus ->
                        { position = newPosition
                        , direction = newDirection
                        , holeStatus = newHoleStatus
                        }
                    )

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


extractRound : MidRoundState -> Round
extractRound s =
    case s of
        Live round ->
            round

        Replay round ->
            round


stepSpawnState : SpawnState -> ( MidRoundState -> GameState, Cmd msg )
stepSpawnState { playersLeft, ticksLeft } =
    case playersLeft of
        [] ->
            -- All players have spawned.
            ( MidRound <| Tick.genesis, Cmd.none )

        spawning :: waiting ->
            let
                newSpawnState =
                    if ticksLeft == 0 then
                        { playersLeft = waiting, ticksLeft = config.spawn.numberOfFlickerTicks }

                    else
                        { playersLeft = spawning :: waiting, ticksLeft = ticksLeft - 1 }
            in
            ( PreRound newSpawnState, drawSpawnIfAndOnlyIf (isEven ticksLeft) spawning config.kurves.thickness )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ pressedButtons } as model) =
    case msg of
        SpawnTick spawnState plannedMidRoundState ->
            stepSpawnState spawnState
                |> Tuple.mapFirst (\makeGameState -> { model | gameState = makeGameState plannedMidRoundState })

        GameTick tick midRoundState ->
            let
                currentRound =
                    extractRound midRoundState

                checkIndividualPlayer :
                    Player
                    -> ( Random.Generator Players, Set World.Pixel, List ( Color, DrawingPosition ) )
                    ->
                        ( Random.Generator Players
                        , Set World.Pixel
                        , List ( Color, DrawingPosition )
                        )
                checkIndividualPlayer player ( checkedPlayersGenerator, occupiedPixels, coloredDrawingPositions ) =
                    let
                        turningState =
                            turningStateFromHistory tick player

                        ( newPlayerDrawingPositions, checkedPlayerGenerator, fate ) =
                            updatePlayer turningState occupiedPixels player

                        occupiedPixelsAfterCheckingThisPlayer =
                            List.foldr
                                (World.pixelsToOccupy config.kurves.thickness >> Set.union)
                                occupiedPixels
                                newPlayerDrawingPositions

                        coloredDrawingPositionsAfterCheckingThisPlayer =
                            coloredDrawingPositions ++ List.map (Tuple.pair player.color) newPlayerDrawingPositions

                        playersAfterCheckingThisPlayer : Player -> Players -> Players
                        playersAfterCheckingThisPlayer checkedPlayer =
                            case fate of
                                Player.Dies ->
                                    modifyDead ((::) checkedPlayer)

                                Player.Lives ->
                                    modifyAlive ((::) checkedPlayer)
                    in
                    ( Random.map2 playersAfterCheckingThisPlayer checkedPlayerGenerator checkedPlayersGenerator
                    , occupiedPixelsAfterCheckingThisPlayer
                    , coloredDrawingPositionsAfterCheckingThisPlayer
                    )

                ( newPlayersGenerator, newOccupiedPixels, newColoredDrawingPositions ) =
                    List.foldr
                        checkIndividualPlayer
                        ( Random.constant
                            { alive = [] -- We start with the empty list because the new one we'll create may not include all the players from the old one.
                            , dead = currentRound.players.dead -- Dead players, however, will not spring to life again.
                            }
                        , currentRound.occupiedPixels
                        , []
                        )
                        currentRound.players.alive

                ( newPlayers, newSeed ) =
                    Random.step newPlayersGenerator currentRound.seed

                newCurrentRound =
                    { players = newPlayers
                    , occupiedPixels = newOccupiedPixels
                    , history = currentRound.history
                    , seed = newSeed
                    }

                newGameState =
                    if roundIsOver newPlayers then
                        PostRound newCurrentRound

                    else
                        MidRound tick <| modifyRound (always newCurrentRound) midRoundState
            in
            ( { model | gameState = newGameState }
            , clearOverlay { width = config.world.width, height = config.world.height }
                :: headDrawingCmds config.kurves.thickness newPlayers.alive
                ++ bodyDrawingCmds config.kurves.thickness newColoredDrawingPositions
                |> Cmd.batch
            )

        ButtonUsed Down button ->
            let
                startNewRoundIfSpacePressed seed =
                    case button of
                        Key "Space" ->
                            startRound model <| prepareLiveRound seed pressedButtons

                        _ ->
                            ( handleUserInteraction Down button model, Cmd.none )
            in
            case model.gameState of
                Lobby seed ->
                    startNewRoundIfSpacePressed seed

                PostRound finishedRound ->
                    case button of
                        Key "KeyR" ->
                            startRound model <| prepareReplayRound (initialStateForReplaying finishedRound)

                        _ ->
                            startNewRoundIfSpacePressed finishedRound.seed

                _ ->
                    ( handleUserInteraction Down button model, Cmd.none )

        ButtonUsed Up key ->
            ( handleUserInteraction Up key model, Cmd.none )


handleUserInteraction : ButtonDirection -> Button -> Model -> Model
handleUserInteraction direction button model =
    let
        newPressedButtons =
            updatePressedButtons direction button model.pressedButtons

        howToModifyRound =
            case model.gameState of
                MidRound lastTick (Live _) ->
                    recordInteractionBefore (Tick.succ lastTick)

                PreRound _ (Live _) ->
                    recordInteractionBefore firstUpdateTick

                _ ->
                    identity

        recordInteractionBefore tick =
            modifyPlayers <| modifyAlive <| List.map (recordUserInteraction newPressedButtons tick)
    in
    { model
        | pressedButtons = newPressedButtons
        , gameState = modifyMidRoundState (modifyRound howToModifyRound) model.gameState
    }


recordUserInteraction : Set String -> Tick -> Player -> Player
recordUserInteraction pressedButtons nextTick player =
    let
        newTurningState =
            computeTurningState pressedButtons player
    in
    modifyReversedInteractions ((::) (HappenedBefore nextTick newTurningState)) player


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch <|
        (case model.gameState of
            Lobby _ ->
                Sub.none

            PostRound _ ->
                Sub.none

            PreRound spawnState plannedMidRoundState ->
                Time.every (1000 / config.spawn.flickerTicksPerSecond) (always <| SpawnTick spawnState plannedMidRoundState)

            MidRound lastTick midRoundState ->
                Time.every (1000 / Tickrate.toFloat config.kurves.tickrate) (always <| GameTick (Tick.succ lastTick) midRoundState)
        )
            :: inputSubscriptions ButtonUsed


main : Program () Model Msg
main =
    worker
        { init = init
        , update = update
        , subscriptions = subscriptions
        }
