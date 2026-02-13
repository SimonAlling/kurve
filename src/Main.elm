port module Main exposing (Model, Msg(..), init, main, update)

import App exposing (AppState(..), modifyGameState)
import Browser
import Browser.Events
import Canvas exposing (clearEverything, drawingCmd)
import Config exposing (Config)
import Dialog
import Drawing exposing (WhatToDraw, drawSpawnsPermanently, mergeWhatToDraw)
import Effect exposing (Effect(..), maybeDrawSomething)
import Events
import GUI.ConfirmQuitDialog exposing (confirmQuitDialog)
import GUI.EndScreen exposing (endScreen)
import GUI.Hints exposing (Hint, Hints)
import GUI.Lobby exposing (lobby)
import GUI.Scoreboard exposing (scoreboard, scoreboardContainer)
import GUI.Settings
import GUI.SplashScreen exposing (splashScreen)
import GUI.TextOverlay exposing (textOverlay)
import Game
    exposing
        ( ActiveGameState(..)
        , GameState(..)
        , LiveOrReplay(..)
        , PausedOrNot(..)
        , firstUpdateTick
        , getFinishedRound
        , isReplay
        , modifyMidRoundState
        , prepareLiveRound
        , prepareReplayRound
        , recordUserInteraction
        , tickResultToGameState
        )
import Holes exposing (HoleStatus)
import Html exposing (Html, canvas, div)
import Html.Attributes as Attr
import Input exposing (Button(..), ButtonDirection(..), updatePressedButtons)
import IsGameOver exposing (isGameOver)
import JavaScript exposing (magicClassNameToPreventUnload)
import MainLoop
import Menu exposing (MenuState(..))
import Overlay
import Players
    exposing
        ( AllPlayers
        , atLeastOneIsParticipating
        , everyoneLeaves
        , getAllPlayerButtons
        , handlePlayerJoiningOrLeaving
        , includeResultsFrom
        , initialPlayers
        , noExtraData
        , participating
        )
import Random
import Round exposing (FinishedRound, Round, initialStateForReplaying, modifyAlive, modifyKurves)
import Set exposing (Set)
import Settings exposing (SettingId(..), Settings)
import Spawn exposing (flickerFrequencyToTicksPerSecond, makeSpawnState, stepSpawnState)
import Time
import Types.FrameTime exposing (FrameTime)
import Types.Kurve exposing (Kurve, getHoleStatus, hasPlayerId)
import Types.PlayerId exposing (PlayerId)
import Types.Tick as Tick exposing (Tick)
import Types.Tickrate as Tickrate
import Util exposing (find)


type alias Model =
    { pressedButtons : Set String
    , appState : AppState
    , config : Config
    , players : AllPlayers
    , hints : Hints
    }


port focusLost : (() -> msg) -> Sub msg


port toggleFullscreen : () -> Cmd msg


port saveToLocalStorage : String -> Cmd msg


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { pressedButtons = Set.empty
      , appState = InMenu SplashScreen (Random.initialSeed 1337)
      , config = Config.default |> Config.withSettings (Settings.parse flags.settingsJsonFromLocalStorage)
      , players = initialPlayers
      , hints = GUI.Hints.initial
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
                    (makeSpawnState model.config.spawn.numberOfFlickers midRoundState)
                    midRoundState
    in
    ( { model | appState = InGame gameState }, ClearEverything )


type Msg
    = SpawnTick
    | AnimationFrame FrameTime
    | ButtonUsed ButtonDirection Button
    | ToggleSettingsScreen
    | SettingChanged SettingId Bool
    | SettingsPresetApplied Settings
    | DialogChoiceMade Dialog.Option
    | HintDismissed Hint
    | FocusLost
    | RequestToggleFullscreen


type alias Flags =
    { settingsJsonFromLocalStorage : Maybe String
    }


update : Msg -> Model -> ( Model, Effect )
update msg ({ config } as model) =
    case msg of
        FocusLost ->
            case model.appState of
                InGame (Active liveOrReplay _ s) ->
                    case liveOrReplay of
                        Live () ->
                            ( { model | appState = InGame (Active liveOrReplay Paused s) }, DoNothing )

                        Replay _ _ ->
                            -- Not important to pause on focus lost when replaying.
                            ( model, DoNothing )

                _ ->
                    ( model, DoNothing )

        RequestToggleFullscreen ->
            ( model, ToggleFullscreen )

        SpawnTick ->
            case model.appState of
                InGame (Active liveOrReplay NotPaused (Spawning spawnState plannedMidRoundState)) ->
                    let
                        ( maybeSpawnState, whatToDraw ) =
                            stepSpawnState spawnState

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

        ToggleSettingsScreen ->
            case model.appState of
                InMenu SplashScreen _ ->
                    -- Not expected to ever happen.
                    ( model, DoNothing )

                InMenu SettingsScreen seed ->
                    closeSettings seed model

                InMenu Lobby seed ->
                    openSettings seed model

                InMenu GameOver _ ->
                    -- Not expected to ever happen.
                    ( model, DoNothing )

                InGame _ ->
                    -- Not expected to ever happen.
                    ( model, DoNothing )

        SettingChanged settingId newValue ->
            let
                newConfig : Config
                newConfig =
                    case settingId of
                        SpawnProtection ->
                            Config.withSpawnkillProtection newValue model.config

                        PersistHoleStatus ->
                            Config.withPersistHoleStatus newValue model.config

                        EnableAlternativeControls ->
                            Config.withEnableAlternativeControls newValue model.config
            in
            ( { model | config = newConfig }, SaveSettings (Config.getSettings newConfig) )

        SettingsPresetApplied newSettings ->
            ( { model | config = Config.withSettings newSettings config }, SaveSettings newSettings )

        DialogChoiceMade option ->
            handleDialogChoice option model

        HintDismissed hint ->
            handleHintDismissed hint model


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


handleHintDismissed : Hint -> Model -> ( Model, Effect )
handleHintDismissed hint model =
    ( { model | hints = GUI.Hints.dismiss hint model.hints }
    , DoNothing
    )


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
                    startRound (Live ()) model <| prepareLiveRound config seed (participating (always Nothing) model.players) pressedButtons

                _ ->
                    ( handleUserInteraction Down button { model | players = handlePlayerJoiningOrLeaving config.enableAlternativeControls button model.players }, DoNothing )

        InMenu SettingsScreen seed ->
            case button of
                Key "Escape" ->
                    closeSettings seed model

                _ ->
                    ( handleUserInteraction Down button model, DoNothing )

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

                                Replay overlayState _ ->
                                    let
                                        fakeActiveGameState : ActiveGameState
                                        fakeActiveGameState =
                                            Moving MainLoop.noLeftoverFrameTime tickThatEndedIt unpackedFinishedRound
                                    in
                                    rewindReplay overlayState pausedOrNot fakeActiveGameState finishedRound model

                        Key "KeyO" ->
                            case liveOrReplay of
                                Live _ ->
                                    ( handleUserInteraction Down button model, DoNothing )

                                Replay overlayState _ ->
                                    ( { model | appState = InGame (RoundOver (Replay (Overlay.toggle overlayState) finishedRound) pausedOrNot tickThatEndedIt dialogState) }, DoNothing )

                        Key "KeyR" ->
                            let
                                newOverlayState : Overlay.State
                                newOverlayState =
                                    case liveOrReplay of
                                        Live _ ->
                                            -- Users might perceive the replay as the next live round if the overlay is gone, so we reset it here.
                                            Overlay.Visible

                                        Replay overlayState _ ->
                                            -- Users are probably mentally "in replay mode". They'll know that they've recently hidden the overlay themselves, and that it's still a replay.
                                            overlayState
                            in
                            startRound (Replay newOverlayState finishedRound) model <| prepareReplayRound config.world (initialStateForReplaying finishedRound)

                        Key "Escape" ->
                            let
                                playersWithRecentResults : AllPlayers
                                playersWithRecentResults =
                                    includeResultsFrom unpackedFinishedRound model.players
                            in
                            -- Quitting after the final round is not allowed in the original game.
                            if isGameOver (participating noExtraData playersWithRecentResults) then
                                ( handleUserInteraction Down button model, DoNothing )

                            else
                                ( { model | appState = InGame (RoundOver liveOrReplay pausedOrNot tickThatEndedIt (Dialog.Open Dialog.Cancel)) }, DoNothing )

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

        InGame (Active (Replay overlayState finishedRound) Paused s) ->
            case button of
                Key "Space" ->
                    proceedToNextRound finishedRound model

                Key "Enter" ->
                    ( { model | appState = InGame (Active (Replay overlayState finishedRound) NotPaused s) }, DoNothing )

                Key "ArrowLeft" ->
                    rewindReplay overlayState Paused s finishedRound model

                Key "ArrowRight" ->
                    fastForwardReplay overlayState Paused s finishedRound model

                Key "KeyE" ->
                    stepOneTick overlayState s finishedRound model

                Key "KeyO" ->
                    ( { model | appState = InGame (Active (Replay (Overlay.toggle overlayState) finishedRound) Paused s) }, DoNothing )

                Key "KeyR" ->
                    startRound (Replay overlayState finishedRound) model <| prepareReplayRound config.world (initialStateForReplaying finishedRound)

                _ ->
                    ( handleUserInteraction Down button model, DoNothing )

        InGame (Active (Live ()) NotPaused _) ->
            ( handleUserInteraction Down button model, DoNothing )

        InGame (Active (Replay overlayState finishedRound) NotPaused s) ->
            case button of
                Key "ArrowLeft" ->
                    rewindReplay overlayState NotPaused s finishedRound model

                Key "ArrowRight" ->
                    fastForwardReplay overlayState NotPaused s finishedRound model

                Key "KeyE" ->
                    stepOneTick overlayState s finishedRound model

                Key "KeyO" ->
                    ( { model | appState = InGame (Active (Replay (Overlay.toggle overlayState) finishedRound) NotPaused s) }, DoNothing )

                Key "KeyR" ->
                    startRound (Replay overlayState finishedRound) model <| prepareReplayRound config.world (initialStateForReplaying finishedRound)

                Key "Space" ->
                    proceedToNextRound finishedRound model

                Key "Enter" ->
                    ( { model | appState = InGame (Active (Replay overlayState finishedRound) Paused s) }, DoNothing )

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

        theKurvesInNoParticularOrder : List Kurve
        theKurvesInNoParticularOrder =
            unpackedFinishedRound.kurves.alive ++ unpackedFinishedRound.kurves.dead

        getHoleStatusById : PlayerId -> Maybe HoleStatus
        getHoleStatusById id =
            theKurvesInNoParticularOrder
                |> find (hasPlayerId id)
                |> Maybe.map getHoleStatus
    in
    if isGameOver (participating noExtraData playersWithRecentResults) then
        gameOver unpackedFinishedRound.seed modelWithRecentResults

    else
        startRound (Live ()) modelWithRecentResults <| prepareLiveRound config unpackedFinishedRound.seed (participating getHoleStatusById playersWithRecentResults) pressedButtons


stepOneTick : Overlay.State -> ActiveGameState -> FinishedRound -> Model -> ( Model, Effect )
stepOneTick overlayState activeGameState finishedRound model =
    case activeGameState of
        Spawning _ _ ->
            ( model, DoNothing )

        Moving _ lastTick midRoundState ->
            let
                timeToSkipInMs : FrameTime
                timeToSkipInMs =
                    1000 / Tickrate.toFloat model.config.kurves.tickrate

                ( tickResult, whatToDraw ) =
                    MainLoop.consumeAnimationFrame
                        model.config
                        timeToSkipInMs
                        MainLoop.noLeftoverFrameTime
                        lastTick
                        midRoundState
            in
            ( { model | appState = InGame (tickResultToGameState (Replay overlayState finishedRound) Paused tickResult) }
            , maybeDrawSomething whatToDraw
            )


fastForwardReplay : Overlay.State -> PausedOrNot -> ActiveGameState -> FinishedRound -> Model -> ( Model, Effect )
fastForwardReplay overlayState pausedOrNot activeGameState finishedRound ({ config } as model) =
    case activeGameState of
        Spawning _ plannedMidRoundState ->
            let
                newActiveGameState : ActiveGameState
                newActiveGameState =
                    Moving MainLoop.noLeftoverFrameTime Tick.genesis plannedMidRoundState

                whatToDraw : WhatToDraw
                whatToDraw =
                    drawSpawnsPermanently plannedMidRoundState.kurves.alive
            in
            ( { model | appState = InGame <| Active (Replay overlayState finishedRound) NotPaused newActiveGameState }
            , DrawSomething whatToDraw
            )

        Moving _ lastTick midRoundState ->
            let
                ( tickResult, whatToDraw ) =
                    MainLoop.consumeAnimationFrame
                        config
                        (toFloat config.replay.skipStepInMs |> MainLoop.withFloatingPointRoundingErrorCompensation)
                        MainLoop.noLeftoverFrameTime
                        lastTick
                        midRoundState
            in
            ( { model | appState = InGame (tickResultToGameState (Replay overlayState finishedRound) pausedOrNot tickResult) }
            , maybeDrawSomething whatToDraw
            )


rewindReplay : Overlay.State -> PausedOrNot -> ActiveGameState -> FinishedRound -> Model -> ( Model, Effect )
rewindReplay overlayState pausedOrNot activeGameState finishedRound model =
    case activeGameState of
        Spawning _ _ ->
            startRound (Replay overlayState finishedRound) model <| prepareReplayRound model.config.world (initialStateForReplaying finishedRound)

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
                    ((tickToGoTo |> Tick.toInt |> toFloat) / tickrateInHz) * 1000 |> MainLoop.withFloatingPointRoundingErrorCompensation

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
            ( { model | appState = InGame (tickResultToGameState (Replay overlayState finishedRound) pausedOrNot tickResult) }
            , ClearAndThenDraw whatToDraw
            )


gameOver : Random.Seed -> Model -> ( Model, Effect )
gameOver seed model =
    ( { model | appState = InMenu GameOver seed }, DoNothing )


goToLobby : Random.Seed -> Model -> ( Model, Effect )
goToLobby seed model =
    ( { model | appState = InMenu Lobby seed, players = everyoneLeaves model.players }, DoNothing )


openSettings : Random.Seed -> Model -> ( Model, Effect )
openSettings seed model =
    ( { model | appState = InMenu SettingsScreen seed }, DoNothing )


closeSettings : Random.Seed -> Model -> ( Model, Effect )
closeSettings seed model =
    -- Cannot use goToLobby because then we'd "forget" the participating players.
    ( { model | appState = InMenu Lobby seed }, DoNothing )


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

            InMenu SettingsScreen _ ->
                Sub.none

            InGame (Active _ NotPaused (Spawning _ _)) ->
                Time.every (1000 / flickerFrequencyToTicksPerSecond model.config.spawn.flickerFrequency) (always SpawnTick)

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
    let
        playerButtons : List Button
        playerButtons =
            getAllPlayerButtons model.players
    in
    case model.appState of
        InMenu Lobby _ ->
            elmRoot (Events.AllowDefaultExcept playerButtons)
                [ Attr.class "in-game-ish"
                ]
                [ div
                    [ Attr.id "wrapper"
                    ]
                    [ div
                        [ Attr.id "border"
                        ]
                        [ lobby model.config.enableAlternativeControls ToggleSettingsScreen model.players
                        ]
                    , scoreboardContainer []
                    ]
                ]

        InMenu SettingsScreen _ ->
            elmRoot (Events.AllowDefaultExcept playerButtons)
                [ Attr.class "in-game-ish"
                ]
                [ div
                    [ Attr.id "wrapper"
                    ]
                    [ div
                        [ Attr.id "border"
                        ]
                        [ GUI.Settings.settings SettingChanged SettingsPresetApplied ToggleSettingsScreen model.config
                        ]
                    , scoreboardContainer []
                    ]
                ]

        InMenu GameOver _ ->
            elmRoot (Events.AllowDefaultExcept playerButtons) [] [ endScreen model.players ]

        InMenu SplashScreen _ ->
            elmRoot (Events.AllowDefaultExcept playerButtons) [] [ splashScreen RequestToggleFullscreen ]

        InGame gameState ->
            elmRoot
                (Game.eventPrevention playerButtons gameState)
                [ Attr.class "in-game-ish"
                , Attr.class magicClassNameToPreventUnload
                ]
                [ div
                    [ Attr.id "wrapper"
                    ]
                    [ div
                        (Attr.id "border"
                            :: borderAttributes gameState
                        )
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
                        , textOverlay HintDismissed model.hints gameState
                        , confirmQuitDialog DialogChoiceMade gameState
                        ]
                    , scoreboard gameState model.players
                    ]
                ]


elmRoot : Events.Prevention -> List (Html.Attribute Msg) -> List (Html Msg) -> Html Msg
elmRoot prevention attrs content =
    div (Attr.id "elm-root" :: attrs) (Events.eventsElement prevention ButtonUsed :: content)


borderAttributes : GameState -> List (Html.Attribute msg)
borderAttributes gameState =
    if isReplay gameState then
        [ Attr.class "replay-mode" ]

    else
        []


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

        ToggleFullscreen ->
            toggleFullscreen ()

        SaveSettings settings ->
            saveToLocalStorage (Settings.stringify settings)

        DoNothing ->
            Cmd.none
