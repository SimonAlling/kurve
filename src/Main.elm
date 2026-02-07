port module Main exposing (Model, Msg(..), init, main, update)

import App exposing (AppState(..), modifyGameState)
import Browser
import Browser.Events
import Canvas exposing (clearEverything, drawingCmd)
import Config exposing (Config)
import Dialog
import Drawing exposing (WhatToDraw, drawSpawnsPermanently, drawSpawnsTemporarily, mergeWhatToDraw)
import Effect exposing (Effect(..), maybeDrawSomething)
import Events
import GUI.ConfirmQuitDialog exposing (confirmQuitDialog)
import GUI.EndScreen exposing (endScreen)
import GUI.Lobby exposing (lobby)
import GUI.Scoreboard exposing (scoreboard)
import GUI.SplashScreen exposing (splashScreen)
import GUI.TextOverlay exposing (textOverlay)
import Game
    exposing
        ( ActiveGameState(..)
        , GameState(..)
        , LiveOrReplay(..)
        , PausedOrNot(..)
        , SpawnState
        , firstUpdateTick
        , getFinishedRound
        , modifyMidRoundState
        , prepareLiveRound
        , prepareReplayRound
        , recordUserInteraction
        , tickResultToGameState
        )
import Html exposing (Html, canvas, div)
import Html.Attributes as Attr
import Input exposing (Button(..), ButtonDirection(..), updatePressedButtons)
import IsGameOver exposing (isGameOver)
import JavaScript exposing (magicClassNameToPreventUnload)
import MainLoop
import Menu exposing (MenuState(..))
import Players
    exposing
        ( AllPlayers
        , atLeastOneIsParticipating
        , everyoneLeaves
        , handlePlayerJoiningOrLeaving
        , includeResultsFrom
        , initialPlayers
        , participating
        )
import Random
import Round exposing (FinishedRound, Round, initialStateForReplaying, modifyAlive, modifyKurves)
import Set exposing (Set)
import Time
import Types.FrameTime exposing (FrameTime)
import Types.Kurve exposing (Kurve)
import Types.Tick as Tick exposing (Tick)
import Types.Tickrate as Tickrate
import Util exposing (isEven)


type alias Model =
    { pressedButtons : Set String
    , appState : AppState
    , config : Config
    , players : AllPlayers
    }


port focusLost : (() -> msg) -> Sub msg


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { pressedButtons = Set.empty
      , appState = InMenu SplashScreen (Random.initialSeed flags.initialSeedValue)
      , config = Config.default
      , players = initialPlayers
      }
    , Cmd.none
    )


startRound : LiveOrReplay () -> Model -> Round -> ( Model, Effect )
startRound liveOrReplay model midRoundState =
    let
        gameState : GameState
        gameState =
            Active liveOrReplay NotPaused <|
                Spawning
                    { kurvesLeft = midRoundState |> .kurves |> .alive
                    , alreadySpawnedKurves = []
                    , ticksLeft = model.config.spawn.numberOfFlickerTicks
                    }
                    midRoundState
    in
    ( { model | appState = InGame gameState }, ClearEverything )


type Msg
    = SpawnTick
    | AnimationFrame FrameTime
    | ButtonUsed ButtonDirection Button
    | DialogChoiceMade Dialog.Option
    | FocusLost


type alias Flags =
    { initialSeedValue : Int
    }


stepSpawnState : Config -> SpawnState -> ( Maybe SpawnState, WhatToDraw )
stepSpawnState config { kurvesLeft, alreadySpawnedKurves, ticksLeft } =
    case kurvesLeft of
        [] ->
            -- All Kurves have spawned.
            ( Nothing, drawSpawnsPermanently alreadySpawnedKurves )

        spawning :: waiting ->
            let
                spawnedAndSpawning : List Kurve
                spawnedAndSpawning =
                    alreadySpawnedKurves ++ [ spawning ]

                kurvesToDraw : List Kurve
                kurvesToDraw =
                    if isEven ticksLeft then
                        spawnedAndSpawning

                    else
                        alreadySpawnedKurves

                newSpawnState : SpawnState
                newSpawnState =
                    if ticksLeft == 0 then
                        { kurvesLeft = waiting, alreadySpawnedKurves = spawnedAndSpawning, ticksLeft = config.spawn.numberOfFlickerTicks }

                    else
                        { kurvesLeft = spawning :: waiting, alreadySpawnedKurves = alreadySpawnedKurves, ticksLeft = ticksLeft - 1 }
            in
            ( Just newSpawnState, drawSpawnsTemporarily kurvesToDraw )


update : Msg -> Model -> ( Model, Effect )
update msg ({ config } as model) =
    case msg of
        FocusLost ->
            case model.appState of
                InGame (Active liveOrReplay _ s) ->
                    case liveOrReplay of
                        Live () ->
                            ( { model | appState = InGame (Active liveOrReplay Paused s) }, DoNothing )

                        Replay _ ->
                            -- Not important to pause on focus lost when replaying.
                            ( model, DoNothing )

                _ ->
                    ( model, DoNothing )

        SpawnTick ->
            case model.appState of
                InGame (Active liveOrReplay NotPaused (Spawning spawnState plannedMidRoundState)) ->
                    let
                        ( maybeSpawnState, whatToDraw ) =
                            stepSpawnState config spawnState

                        activeGameState : ActiveGameState
                        activeGameState =
                            case maybeSpawnState of
                                Just newSpawnState ->
                                    Spawning newSpawnState plannedMidRoundState

                                Nothing ->
                                    Moving MainLoop.noLeftoverFrameTime Tick.genesis plannedMidRoundState
                    in
                    ( { model | appState = InGame <| Active liveOrReplay NotPaused activeGameState }
                    , DrawSomething whatToDraw
                    )

                _ ->
                    -- Not expected to ever happen.
                    ( model, DoNothing )

        AnimationFrame delta ->
            case model.appState of
                InGame (Active liveOrReplay NotPaused (Moving leftoverTimeFromPreviousFrame lastTick midRoundState)) ->
                    let
                        ( tickResult, whatToDraw ) =
                            MainLoop.consumeAnimationFrame
                                config
                                delta
                                leftoverTimeFromPreviousFrame
                                lastTick
                                midRoundState
                    in
                    ( { model | appState = InGame (tickResultToGameState liveOrReplay NotPaused tickResult) }
                    , maybeDrawSomething whatToDraw
                    )

                _ ->
                    -- Not expected to ever happen.
                    ( model, DoNothing )

        ButtonUsed Down button ->
            buttonUsed button model

        ButtonUsed Up key ->
            ( handleUserInteraction Up key model, DoNothing )

        DialogChoiceMade option ->
            handleDialogChoice option model


handleDialogChoice : Dialog.Option -> Model -> ( Model, Effect )
handleDialogChoice option model =
    case model.appState of
        InGame (RoundOver liveOrReplay pausedOrNot tickThatEndedIt (Dialog.Open _)) ->
            case option of
                Dialog.Confirm ->
                    let
                        finishedRound : FinishedRound
                        finishedRound =
                            getFinishedRound liveOrReplay
                    in
                    goToLobby (Round.unpackFinished finishedRound).seed model

                Dialog.Cancel ->
                    ( { model | appState = InGame (RoundOver liveOrReplay pausedOrNot tickThatEndedIt Dialog.NotOpen) }, DoNothing )

        _ ->
            -- Not expected to ever happen.
            ( model, DoNothing )


buttonUsed : Button -> Model -> ( Model, Effect )
buttonUsed button ({ config, pressedButtons } as model) =
    case model.appState of
        InMenu SplashScreen seed ->
            case button of
                Key "Space" ->
                    goToLobby seed model

                _ ->
                    ( handleUserInteraction Down button model, DoNothing )

        InMenu Lobby seed ->
            case ( button, atLeastOneIsParticipating model.players ) of
                ( Key "Space", True ) ->
                    startRound (Live ()) model <| prepareLiveRound config seed (participating model.players) pressedButtons

                _ ->
                    ( handleUserInteraction Down button { model | players = handlePlayerJoiningOrLeaving button model.players }, DoNothing )

        InGame (RoundOver liveOrReplay pausedOrNot tickThatEndedIt dialogState) ->
            case dialogState of
                Dialog.NotOpen ->
                    let
                        finishedRound : FinishedRound
                        finishedRound =
                            getFinishedRound liveOrReplay

                        unpackedFinishedRound : Round
                        unpackedFinishedRound =
                            Round.unpackFinished finishedRound
                    in
                    case button of
                        Key "ArrowLeft" ->
                            case liveOrReplay of
                                Live _ ->
                                    ( handleUserInteraction Down button model, DoNothing )

                                Replay _ ->
                                    let
                                        fakeActiveGameState : ActiveGameState
                                        fakeActiveGameState =
                                            Moving MainLoop.noLeftoverFrameTime tickThatEndedIt unpackedFinishedRound
                                    in
                                    rewindReplay pausedOrNot fakeActiveGameState finishedRound model

                        Key "KeyR" ->
                            startRound (Replay finishedRound) model <| prepareReplayRound config.world (initialStateForReplaying finishedRound)

                        Key "Escape" ->
                            let
                                playersWithRecentResults : AllPlayers
                                playersWithRecentResults =
                                    includeResultsFrom unpackedFinishedRound model.players
                            in
                            -- Quitting after the final round is not allowed in the original game.
                            if not (isGameOver (participating playersWithRecentResults)) then
                                ( { model | appState = InGame (RoundOver liveOrReplay pausedOrNot tickThatEndedIt (Dialog.Open Dialog.Cancel)) }, DoNothing )

                            else
                                ( handleUserInteraction Down button model, DoNothing )

                        Key "Space" ->
                            proceedToNextRound finishedRound model

                        _ ->
                            ( handleUserInteraction Down button model, DoNothing )

                Dialog.Open selectedOption ->
                    let
                        cancel : ( Model, Effect )
                        cancel =
                            handleDialogChoice Dialog.Cancel model

                        confirm : ( Model, Effect )
                        confirm =
                            handleDialogChoice Dialog.Confirm model

                        select : Dialog.Option -> ( Model, Effect )
                        select option =
                            ( { model | appState = InGame (RoundOver liveOrReplay pausedOrNot tickThatEndedIt (Dialog.Open option)) }, DoNothing )
                    in
                    case ( button, selectedOption ) of
                        ( Key "Escape", _ ) ->
                            cancel

                        ( Key "Enter", Dialog.Cancel ) ->
                            cancel

                        ( Key "Space", Dialog.Cancel ) ->
                            cancel

                        ( Key "Enter", Dialog.Confirm ) ->
                            confirm

                        ( Key "Space", Dialog.Confirm ) ->
                            confirm

                        ( Key "ArrowLeft", _ ) ->
                            select Dialog.Confirm

                        ( Key "ArrowRight", _ ) ->
                            select Dialog.Cancel

                        ( Key "Tab", _ ) ->
                            let
                                isShift : Bool
                                isShift =
                                    Set.member "ShiftLeft" model.pressedButtons || Set.member "ShiftRight" model.pressedButtons
                            in
                            select <|
                                if isShift then
                                    Dialog.Confirm

                                else
                                    Dialog.Cancel

                        _ ->
                            ( handleUserInteraction Down button model, DoNothing )

        InGame (Active (Live ()) Paused s) ->
            case button of
                Key "Space" ->
                    ( { model | appState = InGame (Active (Live ()) NotPaused s) }, DoNothing )

                _ ->
                    ( handleUserInteraction Down button model, DoNothing )

        InGame (Active (Replay finishedRound) Paused s) ->
            case button of
                Key "Space" ->
                    proceedToNextRound finishedRound model

                Key "Enter" ->
                    ( { model | appState = InGame (Active (Replay finishedRound) NotPaused s) }, DoNothing )

                Key "ArrowLeft" ->
                    rewindReplay Paused s finishedRound model

                Key "ArrowRight" ->
                    case s of
                        Spawning _ _ ->
                            ( model, DoNothing )

                        Moving leftoverTimeFromPreviousFrame lastTick midRoundState ->
                            let
                                ( tickResult, whatToDraw ) =
                                    MainLoop.consumeAnimationFrame
                                        config
                                        (toFloat config.replay.skipStepInMs)
                                        leftoverTimeFromPreviousFrame
                                        lastTick
                                        midRoundState
                            in
                            ( { model | appState = InGame (tickResultToGameState (Replay finishedRound) Paused tickResult) }
                            , maybeDrawSomething whatToDraw
                            )

                Key "KeyE" ->
                    stepOneTick s finishedRound model

                Key "KeyR" ->
                    startRound (Replay finishedRound) model <| prepareReplayRound config.world (initialStateForReplaying finishedRound)

                _ ->
                    ( handleUserInteraction Down button model, DoNothing )

        InGame (Active (Live ()) NotPaused _) ->
            ( handleUserInteraction Down button model, DoNothing )

        InGame (Active (Replay finishedRound) NotPaused s) ->
            case button of
                Key "ArrowLeft" ->
                    rewindReplay NotPaused s finishedRound model

                Key "ArrowRight" ->
                    case s of
                        Spawning _ _ ->
                            ( model, DoNothing )

                        Moving leftoverTimeFromPreviousFrame lastTick midRoundState ->
                            let
                                ( tickResult, whatToDraw ) =
                                    MainLoop.consumeAnimationFrame
                                        config
                                        (toFloat config.replay.skipStepInMs)
                                        leftoverTimeFromPreviousFrame
                                        lastTick
                                        midRoundState
                            in
                            ( { model | appState = InGame (tickResultToGameState (Replay finishedRound) NotPaused tickResult) }
                            , maybeDrawSomething whatToDraw
                            )

                Key "KeyE" ->
                    stepOneTick s finishedRound model

                Key "KeyR" ->
                    startRound (Replay finishedRound) model <| prepareReplayRound config.world (initialStateForReplaying finishedRound)

                Key "Space" ->
                    proceedToNextRound finishedRound model

                Key "Enter" ->
                    ( { model | appState = InGame (Active (Replay finishedRound) Paused s) }, DoNothing )

                _ ->
                    ( handleUserInteraction Down button model, DoNothing )

        InMenu GameOver seed ->
            case button of
                Key "Space" ->
                    goToLobby seed model

                _ ->
                    ( handleUserInteraction Down button model, DoNothing )


proceedToNextRound : FinishedRound -> Model -> ( Model, Effect )
proceedToNextRound finishedRound ({ config, pressedButtons } as model) =
    let
        unpackedFinishedRound : Round
        unpackedFinishedRound =
            Round.unpackFinished finishedRound

        playersWithRecentResults : AllPlayers
        playersWithRecentResults =
            includeResultsFrom unpackedFinishedRound model.players

        modelWithRecentResults : Model
        modelWithRecentResults =
            { model | players = playersWithRecentResults }
    in
    if isGameOver (participating playersWithRecentResults) then
        gameOver unpackedFinishedRound.seed modelWithRecentResults

    else
        startRound (Live ()) modelWithRecentResults <| prepareLiveRound config unpackedFinishedRound.seed (participating playersWithRecentResults) pressedButtons


stepOneTick : ActiveGameState -> FinishedRound -> Model -> ( Model, Effect )
stepOneTick activeGameState finishedRound model =
    case activeGameState of
        Spawning _ _ ->
            ( model, DoNothing )

        Moving leftoverTimeFromPreviousFrame lastTick midRoundState ->
            let
                timeToSkipInMs : FrameTime
                timeToSkipInMs =
                    1000 / Tickrate.toFloat model.config.kurves.tickrate

                ( tickResult, whatToDraw ) =
                    MainLoop.consumeAnimationFrame
                        model.config
                        timeToSkipInMs
                        leftoverTimeFromPreviousFrame
                        lastTick
                        midRoundState
            in
            ( { model | appState = InGame (tickResultToGameState (Replay finishedRound) Paused tickResult) }
            , maybeDrawSomething whatToDraw
            )


rewindReplay : PausedOrNot -> ActiveGameState -> FinishedRound -> Model -> ( Model, Effect )
rewindReplay pausedOrNot activeGameState finishedRound model =
    case activeGameState of
        Spawning _ _ ->
            ( model, DoNothing )

        Moving _ lastTick _ ->
            let
                roundAtBeginning : Round
                roundAtBeginning =
                    prepareReplayRound model.config.world (initialStateForReplaying finishedRound)

                tickrateInHz : Float
                tickrateInHz =
                    Tickrate.toFloat model.config.kurves.tickrate

                ticksToRewind : Int
                ticksToRewind =
                    (tickrateInHz * toFloat model.config.replay.skipStepInMs / 1000)
                        -- If the tickrate is 1 Hz and the skip step is 400 ms, should we go back 1 or 0 ticks? I think 1.
                        |> ceiling

                tickToGoTo : Tick
                tickToGoTo =
                    (Tick.toInt lastTick - ticksToRewind)
                        |> Tick.fromInt
                        |> Maybe.withDefault Tick.genesis

                millisecondsToSkipAhead : FrameTime
                millisecondsToSkipAhead =
                    ((tickToGoTo |> Tick.toInt |> toFloat) / tickrateInHz) * 1000

                whatToDrawForSpawns : WhatToDraw
                whatToDrawForSpawns =
                    drawSpawnsPermanently roundAtBeginning.kurves.alive

                ( tickResult, maybeWhatToDrawForSkippingAhead ) =
                    MainLoop.consumeAnimationFrame
                        model.config
                        millisecondsToSkipAhead
                        MainLoop.noLeftoverFrameTime
                        Tick.genesis
                        roundAtBeginning

                whatToDraw : WhatToDraw
                whatToDraw =
                    case maybeWhatToDrawForSkippingAhead of
                        Nothing ->
                            whatToDrawForSpawns

                        Just whatToDrawForSkippingAhead ->
                            mergeWhatToDraw whatToDrawForSpawns whatToDrawForSkippingAhead
            in
            ( { model | appState = InGame (tickResultToGameState (Replay finishedRound) pausedOrNot tickResult) }
            , ClearAndThenDraw whatToDraw
            )


gameOver : Random.Seed -> Model -> ( Model, Effect )
gameOver seed model =
    ( { model | appState = InMenu GameOver seed }, DoNothing )


goToLobby : Random.Seed -> Model -> ( Model, Effect )
goToLobby seed model =
    ( { model | appState = InMenu Lobby seed, players = everyoneLeaves model.players }, DoNothing )


handleUserInteraction : ButtonDirection -> Button -> Model -> Model
handleUserInteraction direction button model =
    let
        newPressedButtons : Set String
        newPressedButtons =
            updatePressedButtons direction button model.pressedButtons

        howToModifyRound : Round -> Round
        howToModifyRound =
            case model.appState of
                InGame (Active (Live _) _ (Spawning _ _)) ->
                    recordInteractionBefore firstUpdateTick

                InGame (Active (Live _) _ (Moving _ lastTick _)) ->
                    recordInteractionBefore (Tick.succ lastTick)

                _ ->
                    identity

        recordInteractionBefore : Tick -> Round -> Round
        recordInteractionBefore tick =
            modifyKurves <| modifyAlive <| List.map (recordUserInteraction newPressedButtons tick)
    in
    { model
        | pressedButtons = newPressedButtons
        , appState = modifyGameState (modifyMidRoundState howToModifyRound) model.appState
    }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch <|
        [ case model.appState of
            InMenu SplashScreen _ ->
                Sub.none

            InMenu Lobby _ ->
                Sub.none

            InGame (Active _ NotPaused (Spawning _ _)) ->
                Time.every (1000 / model.config.spawn.flickerTicksPerSecond) (always SpawnTick)

            InGame (Active _ NotPaused (Moving _ _ _)) ->
                Browser.Events.onAnimationFrameDelta AnimationFrame

            InGame (Active _ Paused _) ->
                Sub.none

            InGame (RoundOver _ _ _ _) ->
                Sub.none

            InMenu GameOver _ ->
                Sub.none
        , focusLost (always FocusLost)
        ]


view : Model -> Html Msg
view model =
    case model.appState of
        InMenu Lobby _ ->
            elmRoot Events.AllowDefault [] [ lobby model.players ]

        InMenu GameOver _ ->
            elmRoot Events.AllowDefault [] [ endScreen model.players ]

        InMenu SplashScreen _ ->
            elmRoot Events.AllowDefault [] [ splashScreen ]

        InGame gameState ->
            elmRoot
                (Game.eventPrevention gameState)
                [ Attr.class "in-game"
                , Attr.class magicClassNameToPreventUnload
                ]
                [ div
                    [ Attr.id "wrapper"
                    ]
                    [ div
                        [ Attr.id "border"
                        ]
                        [ canvas
                            [ Attr.id "bodyCanvas"
                            , Attr.width 559
                            , Attr.height 480
                            ]
                            []
                        , canvas
                            [ Attr.id "headCanvas"
                            , Attr.width 559
                            , Attr.height 480
                            , Attr.class "overlay"
                            ]
                            []
                        , textOverlay gameState
                        , confirmQuitDialog DialogChoiceMade gameState
                        ]
                    , scoreboard gameState model.players
                    ]
                ]


elmRoot : Events.Prevention -> List (Html.Attribute Msg) -> List (Html Msg) -> Html Msg
elmRoot prevention attrs content =
    div (Attr.id "elm-root" :: attrs) (Events.eventsElement prevention ButtonUsed :: content)


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , update = updateWithCmd
        , subscriptions = subscriptions
        , view = view
        }


updateWithCmd : Msg -> Model -> ( Model, Cmd Msg )
updateWithCmd msg =
    update msg >> Tuple.mapSecond makeCmd


makeCmd : Effect -> Cmd msg
makeCmd effect =
    case effect of
        DrawSomething whatToDraw ->
            drawingCmd False whatToDraw

        ClearAndThenDraw whatToDraw ->
            drawingCmd True whatToDraw

        ClearEverything ->
            clearEverything

        DoNothing ->
            Cmd.none
