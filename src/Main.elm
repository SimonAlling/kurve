port module Main exposing (Model, Msg(..), main)

import App exposing (AppState(..), modifyGameState)
import Browser
import Browser.Events
import Canvas exposing (clearEverything, drawingCmd)
import Config exposing (Config)
import Dialog
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
import RenderAction exposing (RenderAction, drawSpawnIfAndOnlyIf, drawSpawnsPermanently)
import Round exposing (Round, initialStateForReplaying, modifyAlive, modifyKurves)
import Set exposing (Set)
import Time
import Types.FrameTime exposing (FrameTime, LeftoverFrameTime)
import Types.Tick as Tick exposing (Tick)
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


startRound : LiveOrReplay -> Model -> Round -> ( Model, Cmd msg )
startRound liveOrReplay model midRoundState =
    let
        ( gameState, cmd ) =
            newRoundGameStateAndCmd model.config liveOrReplay midRoundState
    in
    ( { model | appState = InGame gameState }, cmd )


newRoundGameStateAndCmd : Config -> LiveOrReplay -> Round -> ( GameState, Cmd msg )
newRoundGameStateAndCmd config liveOrReplay plannedMidRoundState =
    ( Active liveOrReplay NotPaused <|
        Spawning
            { kurvesLeft = plannedMidRoundState |> .kurves |> .alive
            , alreadySpawnedKurves = []
            , ticksLeft = config.spawn.numberOfFlickerTicks
            }
            plannedMidRoundState
    , clearEverything
    )


type Msg
    = SpawnTick LiveOrReplay SpawnState Round
    | AnimationFrame
        LiveOrReplay
        { delta : FrameTime
        , leftoverTimeFromPreviousFrame : LeftoverFrameTime
        , lastTick : Tick
        }
        Round
    | ButtonUsed ButtonDirection Button
    | DialogChoiceMade Dialog.Option
    | FocusLost


stepSpawnState : Config -> SpawnState -> ( Maybe SpawnState, RenderAction )
stepSpawnState config { kurvesLeft, alreadySpawnedKurves, ticksLeft } =
    case kurvesLeft of
        [] ->
            -- All Kurves have spawned.
            ( Nothing, drawSpawnsPermanently alreadySpawnedKurves )

        spawning :: waiting ->
            let
                newSpawnState : SpawnState
                newSpawnState =
                    if ticksLeft == 0 then
                        { kurvesLeft = waiting, alreadySpawnedKurves = spawning :: alreadySpawnedKurves, ticksLeft = config.spawn.numberOfFlickerTicks }

                    else
                        { kurvesLeft = spawning :: waiting, alreadySpawnedKurves = alreadySpawnedKurves, ticksLeft = ticksLeft - 1 }
            in
            ( Just newSpawnState, drawSpawnIfAndOnlyIf (isEven ticksLeft) spawning alreadySpawnedKurves )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ config, pressedButtons } as model) =
    case msg of
        FocusLost ->
            case model.appState of
                InGame (Active liveOrReplay _ s) ->
                    case liveOrReplay of
                        Live ->
                            ( { model | appState = InGame (Active liveOrReplay Paused s) }, Cmd.none )

                        Replay ->
                            -- Not important to pause on focus lost when replaying.
                            ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        SpawnTick liveOrReplay spawnState plannedMidRoundState ->
            let
                ( maybeSpawnState, renderAction ) =
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
            , drawingCmd renderAction
            )

        AnimationFrame liveOrReplay { delta, leftoverTimeFromPreviousFrame, lastTick } midRoundState ->
            let
                ( tickResult, renderAction ) =
                    MainLoop.consumeAnimationFrame config delta leftoverTimeFromPreviousFrame lastTick midRoundState
            in
            ( { model | appState = InGame (tickResultToGameState liveOrReplay tickResult) }
            , drawingCmd renderAction
            )

        ButtonUsed Down button ->
            case model.appState of
                InMenu SplashScreen seed ->
                    case button of
                        Key "Space" ->
                            goToLobby seed model

                        _ ->
                            ( handleUserInteraction Down button model, Cmd.none )

                InMenu Lobby seed ->
                    case ( button, atLeastOneIsParticipating model.players ) of
                        ( Key "Space", True ) ->
                            startRound Live model <| prepareLiveRound config seed (participating model.players) pressedButtons

                        _ ->
                            ( handleUserInteraction Down button { model | players = handlePlayerJoiningOrLeaving button model.players }, Cmd.none )

                InGame (RoundOver finishedRound dialogState) ->
                    case dialogState of
                        Dialog.NotOpen ->
                            let
                                newModel : Model
                                newModel =
                                    { model | players = includeResultsFrom finishedRound model.players }

                                gameIsOver : Bool
                                gameIsOver =
                                    config.game.isGameOver (participating newModel.players)
                            in
                            case button of
                                Key "KeyR" ->
                                    startRound Replay model <| prepareReplayRound (initialStateForReplaying finishedRound)

                                Key "Escape" ->
                                    -- Quitting after the final round is not allowed in the original game.
                                    if not gameIsOver then
                                        ( { model | appState = InGame (RoundOver finishedRound (Dialog.Open Dialog.Cancel)) }, Cmd.none )

                                    else
                                        ( handleUserInteraction Down button model, Cmd.none )

                                Key "Space" ->
                                    if gameIsOver then
                                        gameOver finishedRound.seed newModel

                                    else
                                        startRound Live newModel <| prepareLiveRound config finishedRound.seed (participating newModel.players) pressedButtons

                                _ ->
                                    ( handleUserInteraction Down button model, Cmd.none )

                        Dialog.Open selectedOption ->
                            let
                                cancel : ( Model, Cmd msg )
                                cancel =
                                    ( { model | appState = InGame (RoundOver finishedRound Dialog.NotOpen) }, Cmd.none )

                                confirm : ( Model, Cmd msg )
                                confirm =
                                    goToLobby finishedRound.seed model

                                select : Dialog.Option -> ( Model, Cmd msg )
                                select option =
                                    ( { model | appState = InGame (RoundOver finishedRound (Dialog.Open option)) }, Cmd.none )
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
                                    ( handleUserInteraction Down button model, Cmd.none )

                InGame (Active Live Paused s) ->
                    case button of
                        Key "Space" ->
                            ( { model | appState = InGame (Active Live NotPaused s) }, Cmd.none )

                        _ ->
                            ( handleUserInteraction Down button model, Cmd.none )

                InGame (Active Replay Paused s) ->
                    case button of
                        Key "Space" ->
                            ( { model | appState = InGame (Active Replay NotPaused s) }, Cmd.none )

                        _ ->
                            ( handleUserInteraction Down button model, Cmd.none )

                InGame (Active Live NotPaused _) ->
                    ( handleUserInteraction Down button model, Cmd.none )

                InGame (Active Replay NotPaused s) ->
                    case button of
                        Key "ArrowRight" ->
                            case s of
                                Spawning _ _ ->
                                    ( model, Cmd.none )

                                Moving leftoverTimeFromPreviousFrame lastTick midRoundState ->
                                    let
                                        ( tickResult, renderAction ) =
                                            MainLoop.consumeAnimationFrame config (toFloat config.replay.skipStepInMs) leftoverTimeFromPreviousFrame lastTick midRoundState
                                    in
                                    ( { model | appState = InGame (tickResultToGameState Replay tickResult) }
                                    , drawingCmd renderAction
                                    )

                        Key "KeyR" ->
                            startRound Replay model <| prepareReplayRound (initialStateForReplaying (getActiveRound s))

                        Key "Space" ->
                            ( { model | appState = InGame (Active Replay Paused s) }, Cmd.none )

                        _ ->
                            ( handleUserInteraction Down button model, Cmd.none )

                InMenu GameOver seed ->
                    case button of
                        Key "Space" ->
                            goToLobby seed model

                        _ ->
                            ( handleUserInteraction Down button model, Cmd.none )

        ButtonUsed Up key ->
            ( handleUserInteraction Up key model, Cmd.none )

        DialogChoiceMade option ->
            case model.appState of
                InGame (RoundOver finishedRound (Dialog.Open _)) ->
                    case option of
                        Dialog.Confirm ->
                            goToLobby finishedRound.seed model

                        Dialog.Cancel ->
                            ( { model | appState = InGame (RoundOver finishedRound Dialog.NotOpen) }, Cmd.none )

                _ ->
                    -- Not expected to ever happen.
                    ( model, Cmd.none )


gameOver : Random.Seed -> Model -> ( Model, Cmd msg )
gameOver seed model =
    ( { model | appState = InMenu GameOver seed }, Cmd.none )


goToLobby : Random.Seed -> Model -> ( Model, Cmd msg )
goToLobby seed model =
    ( { model | appState = InMenu Lobby seed, players = everyoneLeaves model.players }, Cmd.none )


handleUserInteraction : ButtonDirection -> Button -> Model -> Model
handleUserInteraction direction button model =
    let
        newPressedButtons : Set String
        newPressedButtons =
            updatePressedButtons direction button model.pressedButtons

        howToModifyRound : Round -> Round
        howToModifyRound =
            case model.appState of
                InGame (Active Live _ (Spawning _ _)) ->
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

            InGame (Active liveOrReplay NotPaused (Spawning spawnState plannedMidRoundState)) ->
                Time.every (1000 / model.config.spawn.flickerTicksPerSecond) (always <| SpawnTick liveOrReplay spawnState plannedMidRoundState)

            InGame (Active liveOrReplay NotPaused (Moving leftoverTimeFromPreviousFrame lastTick midRoundState)) ->
                Browser.Events.onAnimationFrameDelta
                    (\delta ->
                        AnimationFrame
                            liveOrReplay
                            { delta = delta
                            , leftoverTimeFromPreviousFrame = leftoverTimeFromPreviousFrame
                            , lastTick = lastTick
                            }
                            midRoundState
                    )

            InGame (Active _ Paused _) ->
                Sub.none

            InGame (RoundOver _ _) ->
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
                            [ Attr.id "canvas_main"
                            , Attr.width 559
                            , Attr.height 480
                            ]
                            []
                        , canvas
                            [ Attr.id "canvas_overlay"
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
        , update = update
        , subscriptions = subscriptions
        , view = view
        }
