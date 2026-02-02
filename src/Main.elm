port module Main exposing (Model, Msg(..), init, main, update)

import App exposing (AppState(..), modifyGameState)
import Browser
import Browser.Events
import Canvas exposing (clearEverything, drawingCmd)
import Config exposing (Config)
import Dialog
import Drawing exposing (WhatToDraw, drawSpawnsPermanently, drawSpawnsTemporarily, mergeWhatToDraw)
import Effect exposing (Effect(..), maybeDrawSomething)
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
        , getActiveRound
        , modifyMidRoundState
        , prepareLiveRound
        , prepareReplayRound
        , recordUserInteraction
        , tickResultToGameState
        )
import Html exposing (Html, canvas, div)
import Html.Attributes as Attr
import Input exposing (Button(..), ButtonDirection(..), inputSubscriptions, updatePressedButtons)
import IsGameOver exposing (isGameOver)
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
import Round exposing (Round, initialStateForReplaying, modifyAlive, modifyKurves)
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


init : () -> ( Model, Cmd Msg )
init _ =
    ( { pressedButtons = Set.empty
      , appState = InMenu SplashScreen (Random.initialSeed 1337)
      , config = Config.default
      , players = initialPlayers
      }
    , Cmd.none
    )


startRound : LiveOrReplay -> Model -> Round -> ( Model, Effect )
startRound liveOrReplay model midRoundState =
    let
        gameState : GameState
        gameState =
            Active liveOrReplay NotPaused <|
                Spawning
                    MainLoop.noLeftoverFrameTime
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
                        Live ->
                            ( { model | appState = InGame (Active liveOrReplay Paused s) }, DoNothing )

                        Replay ->
                            -- Not important to pause on focus lost when replaying.
                            ( model, DoNothing )

                _ ->
                    ( model, DoNothing )

        SpawnTick ->
            case model.appState of
                InGame (Active liveOrReplay NotPaused (Spawning leftoverFrameTime spawnState plannedMidRoundState)) ->
                    let
                        ( maybeSpawnState, whatToDraw ) =
                            stepSpawnState config spawnState

                        activeGameState : ActiveGameState
                        activeGameState =
                            case maybeSpawnState of
                                Just newSpawnState ->
                                    Spawning (Debug.todo "leftoverFrameTime") newSpawnState plannedMidRoundState

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
            case model.appState of
                InGame (RoundOver liveOrReplay pausedOrNot tickThatEndedIt finishedRound (Dialog.Open _)) ->
                    case option of
                        Dialog.Confirm ->
                            goToLobby finishedRound.seed model

                        Dialog.Cancel ->
                            ( { model | appState = InGame (RoundOver liveOrReplay pausedOrNot tickThatEndedIt finishedRound Dialog.NotOpen) }, DoNothing )

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
                    startRound Live model <| prepareLiveRound config seed (participating model.players) pressedButtons

                _ ->
                    ( handleUserInteraction Down button { model | players = handlePlayerJoiningOrLeaving button model.players }, DoNothing )

        InGame (RoundOver liveOrReplay pausedOrNot tickThatEndedIt finishedRound dialogState) ->
            case dialogState of
                Dialog.NotOpen ->
                    let
                        newModel : Model
                        newModel =
                            { model | players = includeResultsFrom finishedRound model.players }

                        gameIsOver : Bool
                        gameIsOver =
                            isGameOver (participating newModel.players)
                    in
                    case button of
                        Key "ArrowLeft" ->
                            case liveOrReplay of
                                Live ->
                                    ( handleUserInteraction Down button model, DoNothing )

                                Replay ->
                                    let
                                        fakeActiveGameState : ActiveGameState
                                        fakeActiveGameState =
                                            Moving MainLoop.noLeftoverFrameTime tickThatEndedIt finishedRound
                                    in
                                    rewindReplay pausedOrNot fakeActiveGameState model

                        Key "KeyR" ->
                            startRound Replay model <| prepareReplayRound (initialStateForReplaying finishedRound)

                        Key "Escape" ->
                            -- Quitting after the final round is not allowed in the original game.
                            if not gameIsOver then
                                ( { model | appState = InGame (RoundOver liveOrReplay pausedOrNot tickThatEndedIt finishedRound (Dialog.Open Dialog.Cancel)) }, DoNothing )

                            else
                                ( handleUserInteraction Down button model, DoNothing )

                        Key "Space" ->
                            if gameIsOver then
                                gameOver finishedRound.seed newModel

                            else
                                startRound Live newModel <| prepareLiveRound config finishedRound.seed (participating newModel.players) pressedButtons

                        _ ->
                            ( handleUserInteraction Down button model, DoNothing )

                Dialog.Open selectedOption ->
                    let
                        cancel : ( Model, Effect )
                        cancel =
                            ( { model | appState = InGame (RoundOver liveOrReplay pausedOrNot tickThatEndedIt finishedRound Dialog.NotOpen) }, DoNothing )

                        confirm : ( Model, Effect )
                        confirm =
                            goToLobby finishedRound.seed model

                        select : Dialog.Option -> ( Model, Effect )
                        select option =
                            ( { model | appState = InGame (RoundOver liveOrReplay pausedOrNot tickThatEndedIt finishedRound (Dialog.Open option)) }, DoNothing )
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

        InGame (Active Live Paused s) ->
            case button of
                Key "Space" ->
                    ( { model | appState = InGame (Active Live NotPaused s) }, DoNothing )

                _ ->
                    ( handleUserInteraction Down button model, DoNothing )

        InGame (Active Replay Paused s) ->
            case button of
                Key "Space" ->
                    ( { model | appState = InGame (Active Replay NotPaused s) }, DoNothing )

                Key "ArrowLeft" ->
                    rewindReplay Paused s model

                Key "ArrowRight" ->
                    case s of
                        Spawning _ _ _ ->
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
                            ( { model | appState = InGame (tickResultToGameState Replay Paused tickResult) }
                            , maybeDrawSomething whatToDraw
                            )

                Key "KeyE" ->
                    stepOneTick s model

                Key "KeyR" ->
                    startRound Replay model <| prepareReplayRound (initialStateForReplaying (getActiveRound s))

                _ ->
                    ( handleUserInteraction Down button model, DoNothing )

        InGame (Active Live NotPaused _) ->
            ( handleUserInteraction Down button model, DoNothing )

        InGame (Active Replay NotPaused s) ->
            case button of
                Key "ArrowLeft" ->
                    rewindReplay NotPaused s model

                Key "ArrowRight" ->
                    case s of
                        Spawning _ _ _ ->
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
                            ( { model | appState = InGame (tickResultToGameState Replay NotPaused tickResult) }
                            , maybeDrawSomething whatToDraw
                            )

                Key "KeyE" ->
                    stepOneTick s model

                Key "KeyR" ->
                    startRound Replay model <| prepareReplayRound (initialStateForReplaying (getActiveRound s))

                Key "Space" ->
                    ( { model | appState = InGame (Active Replay Paused s) }, DoNothing )

                _ ->
                    ( handleUserInteraction Down button model, DoNothing )

        InMenu GameOver seed ->
            case button of
                Key "Space" ->
                    goToLobby seed model

                _ ->
                    ( handleUserInteraction Down button model, DoNothing )


stepOneTick : ActiveGameState -> Model -> ( Model, Effect )
stepOneTick activeGameState model =
    case activeGameState of
        Spawning _ _ _ ->
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
            ( { model | appState = InGame (tickResultToGameState Replay Paused tickResult) }
            , maybeDrawSomething whatToDraw
            )


rewindReplay : PausedOrNot -> ActiveGameState -> Model -> ( Model, Effect )
rewindReplay pausedOrNot activeGameState model =
    case activeGameState of
        Spawning _ _ _ ->
            ( model, DoNothing )

        Moving _ lastTick midRoundState ->
            let
                roundAtBeginning : Round
                roundAtBeginning =
                    prepareReplayRound (initialStateForReplaying midRoundState)

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
            ( { model | appState = InGame (tickResultToGameState Replay pausedOrNot tickResult) }
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
                InGame (Active Live _ (Spawning _ _ _)) ->
                    recordInteractionBefore firstUpdateTick

                InGame (Active Live _ (Moving _ lastTick _)) ->
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
        (case model.appState of
            InMenu SplashScreen _ ->
                Sub.none

            InMenu Lobby _ ->
                Sub.none

            InGame (Active _ NotPaused (Spawning _ _ _)) ->
                Time.every (1000 / model.config.spawn.flickerTicksPerSecond) (always SpawnTick)

            InGame (Active _ NotPaused (Moving _ _ _)) ->
                Browser.Events.onAnimationFrameDelta AnimationFrame

            InGame (Active _ Paused _) ->
                Sub.none

            InGame (RoundOver _ _ _ _ _) ->
                Sub.none

            InMenu GameOver _ ->
                Sub.none
        )
            :: focusLost (always FocusLost)
            :: inputSubscriptions ButtonUsed


view : Model -> Html Msg
view model =
    case model.appState of
        InMenu Lobby _ ->
            elmRoot [] [ lobby model.players ]

        InMenu GameOver _ ->
            elmRoot [] [ endScreen model.players ]

        InMenu SplashScreen _ ->
            elmRoot [] [ splashScreen ]

        InGame gameState ->
            elmRoot
                [ Attr.class "in-game"
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


elmRoot : List (Html.Attribute msg) -> List (Html msg) -> Html msg
elmRoot attrs =
    div (Attr.id "elm-root" :: attrs)


main : Program () Model Msg
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
