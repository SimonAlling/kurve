module Main exposing (main)

import Canvas exposing (bodyDrawingCmds, clearEverything, clearOverlay, drawSpawnIfAndOnlyIf, headDrawingCmds)
import Color exposing (Color)
import Config exposing (config)
import Input exposing (Button(..), ButtonDirection(..), UserInteraction, inputSubscriptions, updatePressedButtons)
import Platform exposing (worker)
import Random
import Random.Extra as Random
import Set exposing (Set(..))
import Spawn exposing (generateHoleSize, generateHoleSpacing, generatePlayers)
import Time
import Turning exposing (computeAngleChange, computeTurningState)
import Types.Angle as Angle exposing (Angle(..))
import Types.Distance as Distance exposing (Distance(..))
import Types.Player as Player exposing (Player)
import Types.Speed as Speed exposing (Speed(..))
import Types.Thickness as Thickness exposing (Thickness(..))
import Types.Tick as Tick exposing (Tick(..))
import Types.Tickrate as Tickrate exposing (Tickrate(..))
import Util exposing (isEven)
import World exposing (DrawingPosition, Pixel, distanceToTicks)


type alias Model =
    { pressedButtons : Set String
    , gameState : GameState
    , seed : Random.Seed
    }


type alias Round =
    { players : Players
    , occupiedPixels : Set Pixel
    , history : RoundHistory
    , tick : Tick
    }


type GameState
    = MidRound MidRoundState
    | PostRound Round
    | PreRound SpawnState MidRoundState
    | Lobby


type MidRoundState
    = Live Round
    | Replay { emulatedPressedButtons : Set String } Round


type alias SpawnState =
    { playersLeft : List Player
    , ticksLeft : Int
    }


type alias RoundInitialState =
    { seedAfterSpawn : Random.Seed
    , spawnedPlayers : List Player
    , pressedButtons : Set String
    }


type alias RoundHistory =
    { initialState : RoundInitialState
    , reversedUserInteractions : List UserInteraction
    }


type alias Players =
    { alive : List Player
    , dead : List Player
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { pressedButtons = Set.empty
      , gameState = Lobby
      , seed = Random.initialSeed 1337
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
        ( thePlayers, seedAfterSpawn ) =
            Random.step (generatePlayers config) seed
    in
    prepareRoundHelper { seedAfterSpawn = seedAfterSpawn, spawnedPlayers = thePlayers, pressedButtons = pressedButtons } [] |> Live


prepareReplayRound : RoundInitialState -> List UserInteraction -> MidRoundState
prepareReplayRound initialState reversedUserInteractions =
    prepareRoundHelper initialState reversedUserInteractions |> Replay { emulatedPressedButtons = initialState.pressedButtons }


prepareRoundHelper : RoundInitialState -> List UserInteraction -> Round
prepareRoundHelper initialState reversedUserInteractions =
    let
        thePlayers =
            initialState.spawnedPlayers

        thickness =
            config.kurves.thickness

        round =
            { players = { alive = thePlayers, dead = [] }
            , occupiedPixels = List.foldr (.position >> World.drawingPosition thickness >> World.pixelsToOccupy thickness >> Set.union) Set.empty thePlayers
            , history =
                { initialState = initialState
                , reversedUserInteractions = reversedUserInteractions
                }
            , tick = Tick 0
            }
    in
    round


{-| Takes the distance between the _edges_ of two drawn squares and returns the distance between their _centers_.
-}
computeDistanceBetweenCenters : Distance -> Distance
computeDistanceBetweenCenters distanceBetweenEdges =
    Distance <| Distance.toFloat distanceBetweenEdges + toFloat (Thickness.toInt config.kurves.thickness)


type Msg
    = GameTick MidRoundState
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


updatePlayer : Set String -> Set Pixel -> Player -> ( List DrawingPosition, Random.Generator Player, Player.Fate )
updatePlayer pressedButtons occupiedPixels player =
    let
        distanceTraveledSinceLastTick =
            Speed.toFloat config.kurves.speed / Tickrate.toFloat config.kurves.tickrate

        newDirection =
            Angle.add player.direction <| computeAngleChange config.kurves <| computeTurningState pressedButtons player

        ( x, y ) =
            player.position

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
                (World.drawingPosition thickness player.position)
                (World.desiredDrawingPositions thickness player.position newPosition)
                occupiedPixels
                player.holeStatus

        newHoleStatusGenerator =
            updateHoleStatus config.kurves.speed player.holeStatus

        newPlayer =
            newHoleStatusGenerator
                |> Random.map
                    (\newHoleStatus ->
                        { player
                            | position = newPosition
                            , direction = newDirection
                            , holeStatus = newHoleStatus
                        }
                    )
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


considerRecentButtonPresses : RoundHistory -> Tick -> Set String -> Set String
considerRecentButtonPresses history previousTick previousPressedButtons =
    history.reversedUserInteractions
        |> List.filter (\k -> k.happenedAfterTick == previousTick)
        |> List.foldr (\k -> updatePressedButtons k.direction k.button) previousPressedButtons


extractRound : MidRoundState -> Round
extractRound s =
    case s of
        Live round ->
            round

        Replay _ round ->
            round


stepSpawnState : SpawnState -> ( MidRoundState -> GameState, Cmd msg )
stepSpawnState { playersLeft, ticksLeft } =
    case playersLeft of
        [] ->
            -- All players have spawned.
            ( MidRound, Cmd.none )

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

        GameTick midRoundState ->
            let
                currentRound =
                    extractRound midRoundState

                effectivePressedButtons =
                    case midRoundState of
                        Replay { emulatedPressedButtons } _ ->
                            considerRecentButtonPresses currentRound.history currentRound.tick emulatedPressedButtons

                        _ ->
                            pressedButtons

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
                        ( newPlayerDrawingPositions, checkedPlayerGenerator, fate ) =
                            updatePlayer effectivePressedButtons occupiedPixels player

                        occupiedPixelsAfterCheckingThisPlayer =
                            List.foldr
                                (World.pixelsToOccupy config.kurves.thickness >> Set.union)
                                occupiedPixels
                                newPlayerDrawingPositions

                        coloredDrawingPositionsAfterCheckingThisPlayer =
                            coloredDrawingPositions ++ List.map (Tuple.pair player.color) newPlayerDrawingPositions

                        playersAfterCheckingThisPlayer : Player -> Players -> Players
                        playersAfterCheckingThisPlayer checkedPlayer checkedPlayers =
                            case fate of
                                Player.Dies ->
                                    { checkedPlayers | dead = checkedPlayer :: checkedPlayers.dead }

                                Player.Lives ->
                                    { checkedPlayers | alive = checkedPlayer :: checkedPlayers.alive }
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
                    Random.step newPlayersGenerator model.seed

                newCurrentRound =
                    { players = newPlayers
                    , occupiedPixels = newOccupiedPixels
                    , history = currentRound.history
                    , tick = Tick.succ currentRound.tick
                    }

                newGameState =
                    if roundIsOver newPlayers then
                        PostRound newCurrentRound

                    else
                        case midRoundState of
                            Live _ ->
                                MidRound <| Live newCurrentRound

                            Replay _ _ ->
                                MidRound <| Replay { emulatedPressedButtons = effectivePressedButtons } newCurrentRound
            in
            ( { model
                | gameState = newGameState
                , seed = newSeed
              }
            , clearOverlay { width = config.world.width, height = config.world.height }
                :: headDrawingCmds config.kurves.thickness newPlayers.alive
                ++ bodyDrawingCmds config.kurves.thickness newColoredDrawingPositions
                |> Cmd.batch
            )

        ButtonUsed Down button ->
            let
                startNewRoundIfSpacePressed =
                    case button of
                        Key "Space" ->
                            startRound model <|
                                prepareLiveRound
                                    model.seed
                                    pressedButtons

                        _ ->
                            ( handleUserInteraction Down button model, Cmd.none )
            in
            case model.gameState of
                Lobby ->
                    startNewRoundIfSpacePressed

                PostRound finishedRound ->
                    case button of
                        Key "KeyR" ->
                            startRound model <|
                                prepareReplayRound
                                    finishedRound.history.initialState
                                    finishedRound.history.reversedUserInteractions

                        _ ->
                            startNewRoundIfSpacePressed

                _ ->
                    ( handleUserInteraction Down button model, Cmd.none )

        ButtonUsed Up key ->
            ( handleUserInteraction Up key model, Cmd.none )


handleUserInteraction : ButtonDirection -> Button -> Model -> Model
handleUserInteraction direction button model =
    let
        modelWithNewPressedButtons =
            { model | pressedButtons = updatePressedButtons direction button model.pressedButtons }
    in
    case model.gameState of
        MidRound midRoundState ->
            case midRoundState of
                Replay _ _ ->
                    modelWithNewPressedButtons

                Live currentRound ->
                    { modelWithNewPressedButtons | gameState = MidRound (Live <| recordUserInteraction direction button currentRound) }

        _ ->
            modelWithNewPressedButtons


recordUserInteraction : ButtonDirection -> Button -> Round -> Round
recordUserInteraction direction button ({ history } as currentRound) =
    { currentRound
        | history =
            { history
                | reversedUserInteractions =
                    { happenedAfterTick = currentRound.tick
                    , direction = direction
                    , button = button
                    }
                        :: history.reversedUserInteractions
            }
    }


roundIsOver : Players -> Bool
roundIsOver players =
    let
        someoneHasWonInMultiPlayer =
            List.length players.alive == 1 && not (List.isEmpty players.dead)

        playerHasDiedInSinglePlayer =
            List.isEmpty players.alive
    in
    someoneHasWonInMultiPlayer || playerHasDiedInSinglePlayer


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch <|
        (case model.gameState of
            Lobby ->
                Sub.none

            PostRound _ ->
                Sub.none

            PreRound spawnState plannedMidRoundState ->
                Time.every (1000 / config.spawn.flickerTicksPerSecond) (always <| SpawnTick spawnState plannedMidRoundState)

            MidRound midRoundState ->
                Time.every (1000 / Tickrate.toFloat config.kurves.tickrate) (always <| GameTick midRoundState)
        )
            :: inputSubscriptions ButtonUsed


main : Program () Model Msg
main =
    worker
        { init = init
        , update = update
        , subscriptions = subscriptions
        }
