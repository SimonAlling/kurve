module Main exposing (main)

import Canvas exposing (bodyDrawingCmds, clearEverything, clearOverlay, drawSpawnIfAndOnlyIf, headDrawingCmds)
import Color exposing (Color)
import Config exposing (config)
import Game exposing (GameState(..), MidRoundState(..), SpawnState, extractRound, firstUpdateTick, modifyMidRoundState, modifyRound, prepareLiveRound, prepareReplayRound, recordUserInteraction, updatePlayer)
import Input exposing (Button(..), ButtonDirection(..), inputSubscriptions, updatePressedButtons)
import Platform exposing (worker)
import Random
import Round exposing (Players, Round, initialStateForReplaying, modifyAlive, modifyDead, modifyPlayers, roundIsOver)
import Set exposing (Set)
import Time
import Turning exposing (turningStateFromHistory)
import Types.Player as Player exposing (Player)
import Types.Tick as Tick exposing (Tick)
import Types.Tickrate as Tickrate
import Types.TurningState exposing (TurningState)
import Util exposing (isEven)
import World exposing (DrawingPosition, Pixel)


type alias Model =
    { pressedButtons : Set String
    , gameState : GameState
    }


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


type Msg
    = GameTick Tick MidRoundState
    | ButtonUsed ButtonDirection Button
    | SpawnTick SpawnState MidRoundState


stepSpawnState : SpawnState -> ( MidRoundState -> GameState, Cmd msg )
stepSpawnState { playersLeft, ticksLeft } =
    case playersLeft of
        [] ->
            -- All players have spawned.
            ( MidRound <| Tick.genesis, Cmd.none )

        spawning :: waiting ->
            let
                newSpawnState : SpawnState
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
                currentRound : Round
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
                        turningState : TurningState
                        turningState =
                            turningStateFromHistory tick player

                        ( newPlayerDrawingPositions, checkedPlayerGenerator, fate ) =
                            updatePlayer turningState occupiedPixels player

                        occupiedPixelsAfterCheckingThisPlayer : Set Pixel
                        occupiedPixelsAfterCheckingThisPlayer =
                            List.foldr
                                (World.pixelsToOccupy config.kurves.thickness >> Set.union)
                                occupiedPixels
                                newPlayerDrawingPositions

                        coloredDrawingPositionsAfterCheckingThisPlayer : List ( Color, DrawingPosition )
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

                newCurrentRound : Round
                newCurrentRound =
                    { players = newPlayers
                    , occupiedPixels = newOccupiedPixels
                    , history = currentRound.history
                    , seed = newSeed
                    }

                newGameState : GameState
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
                startNewRoundIfSpacePressed : Random.Seed -> ( Model, Cmd msg )
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
        newPressedButtons : Set String
        newPressedButtons =
            updatePressedButtons direction button model.pressedButtons

        howToModifyRound : Round -> Round
        howToModifyRound =
            case model.gameState of
                MidRound lastTick (Live _) ->
                    recordInteractionBefore (Tick.succ lastTick)

                PreRound _ (Live _) ->
                    recordInteractionBefore firstUpdateTick

                _ ->
                    identity

        recordInteractionBefore : Tick -> Round -> Round
        recordInteractionBefore tick =
            modifyPlayers <| modifyAlive <| List.map (recordUserInteraction newPressedButtons tick)
    in
    { model
        | pressedButtons = newPressedButtons
        , gameState = modifyMidRoundState (modifyRound howToModifyRound) model.gameState
    }


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
