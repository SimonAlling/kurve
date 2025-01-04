port module Main exposing (Model, Msg(..), main)

import App exposing (AppState(..), modifyGameState)
import Browser
import Browser.Events
import Canvas exposing (clearEverything, drawSpawnIfAndOnlyIf)
import Config exposing (Config)
import Dialog
import GUI.ConfirmQuitDialog exposing (confirmQuitDialog)
import GUI.EndScreen exposing (endScreen)
import GUI.Lobby exposing (lobby)
import GUI.PauseOverlay exposing (pauseOverlay)
import GUI.Scoreboard exposing (scoreboard)
import GUI.SplashScreen exposing (splashScreen)
import Game exposing (ActiveGameState(..), GameState(..), MidRoundState, MidRoundStateVariant(..), Paused(..), SpawnState, firstUpdateTick, modifyMidRoundState, modifyRound, prepareLiveRound, prepareReplayRound, recordUserInteraction, tickResultToGameState)
import Html exposing (Html, canvas, div)
import Html.Attributes as Attr
import Input exposing (Button(..), ButtonDirection(..), inputSubscriptions, updatePressedButtons)
import MainLoop
import Menu exposing (MenuState(..))
import Players exposing (AllPlayers, atLeastOneIsParticipating, everyoneLeaves, handlePlayerJoiningOrLeaving, includeResultsFrom, initialPlayers, participating)
import Random
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


startRound : Model -> MidRoundState -> ( Model, Cmd msg )
startRound model midRoundState =
    let
        ( gameState, cmd ) =
            newRoundGameStateAndCmd model.config midRoundState
    in
    ( { model | appState = InGame MainLoop.noLeftoverTime gameState }, cmd )


newRoundGameStateAndCmd : Config -> MidRoundState -> ( GameState, Cmd msg )
newRoundGameStateAndCmd config plannedMidRoundState =
    ( Active NotPaused <|
        Spawning
            { kurvesLeft = Tuple.second plannedMidRoundState |> .kurves |> .alive
            , ticksLeft = config.spawn.numberOfFlickerTicks
            }
            plannedMidRoundState
    , clearEverything config.world
    )


type Msg
    = SpawnTick SpawnState MidRoundState
    | AnimationFrame
        { delta : FrameTime
        , leftoverTimeFromPreviousFrame : LeftoverFrameTime
        , lastTick : Tick
        }
        MidRoundState
    | ButtonUsed ButtonDirection Button
    | DialogChoiceMade Dialog.Option
    | FocusLost


stepSpawnState : Config -> SpawnState -> ( MidRoundState -> ActiveGameState, Cmd msg )
stepSpawnState config { kurvesLeft, ticksLeft } =
    case kurvesLeft of
        [] ->
            -- All Kurves have spawned.
            ( Moving Tick.genesis, Cmd.none )

        spawning :: waiting ->
            let
                newSpawnState : SpawnState
                newSpawnState =
                    if ticksLeft == 0 then
                        { kurvesLeft = waiting, ticksLeft = config.spawn.numberOfFlickerTicks }

                    else
                        { kurvesLeft = spawning :: waiting, ticksLeft = ticksLeft - 1 }
            in
            ( Spawning newSpawnState, drawSpawnIfAndOnlyIf (isEven ticksLeft) spawning )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ config, pressedButtons } as model) =
    case msg of
        FocusLost ->
            case model.appState of
                InGame leftoverFrameTime (Active _ s) ->
                    ( { model | appState = InGame leftoverFrameTime (Active Paused s) }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        SpawnTick spawnState plannedMidRoundState ->
            stepSpawnState config spawnState
                |> Tuple.mapFirst (\makeActiveGameState -> { model | appState = InGame MainLoop.noLeftoverTime <| Active NotPaused <| makeActiveGameState plannedMidRoundState })

        AnimationFrame { delta, leftoverTimeFromPreviousFrame, lastTick } midRoundState ->
            let
                ( leftoverTimeForNextFrame, tickResult, cmd ) =
                    MainLoop.consumeFrameTime config delta leftoverTimeFromPreviousFrame lastTick midRoundState
            in
            ( { model | appState = InGame leftoverTimeForNextFrame (tickResultToGameState tickResult) }
            , cmd
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
                            startRound model <| prepareLiveRound config seed (participating model.players) pressedButtons

                        _ ->
                            ( handleUserInteraction Down button { model | players = handlePlayerJoiningOrLeaving button model.players }, Cmd.none )

                InGame leftoverFrameTime (RoundOver finishedRound dialogState) ->
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
                                    startRound model <| prepareReplayRound (initialStateForReplaying finishedRound)

                                Key "Escape" ->
                                    -- Quitting after the final round is not allowed in the original game.
                                    if not gameIsOver then
                                        ( { model | appState = InGame leftoverFrameTime (RoundOver finishedRound (Dialog.Open Dialog.Cancel)) }, Cmd.none )

                                    else
                                        ( handleUserInteraction Down button model, Cmd.none )

                                Key "Space" ->
                                    if gameIsOver then
                                        gameOver finishedRound.seed newModel

                                    else
                                        startRound newModel <| prepareLiveRound config finishedRound.seed (participating newModel.players) pressedButtons

                                _ ->
                                    ( handleUserInteraction Down button model, Cmd.none )

                        Dialog.Open selectedOption ->
                            let
                                cancel : ( Model, Cmd msg )
                                cancel =
                                    ( { model | appState = InGame leftoverFrameTime (RoundOver finishedRound Dialog.NotOpen) }, Cmd.none )

                                confirm : ( Model, Cmd msg )
                                confirm =
                                    goToLobby finishedRound.seed model

                                select : Dialog.Option -> ( Model, Cmd msg )
                                select option =
                                    ( { model | appState = InGame leftoverFrameTime (RoundOver finishedRound (Dialog.Open option)) }, Cmd.none )
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

                InGame leftoverFrameTime (Active Paused s) ->
                    case button of
                        Key "Space" ->
                            ( { model | appState = InGame leftoverFrameTime (Active NotPaused s) }, Cmd.none )

                        _ ->
                            ( handleUserInteraction Down button model, Cmd.none )

                InMenu GameOver seed ->
                    case button of
                        Key "Space" ->
                            goToLobby seed model

                        _ ->
                            ( handleUserInteraction Down button model, Cmd.none )

                _ ->
                    ( handleUserInteraction Down button model, Cmd.none )

        ButtonUsed Up key ->
            ( handleUserInteraction Up key model, Cmd.none )

        DialogChoiceMade option ->
            case model.appState of
                InGame leftoverFrameTime (RoundOver finishedRound (Dialog.Open _)) ->
                    case option of
                        Dialog.Confirm ->
                            goToLobby finishedRound.seed model

                        Dialog.Cancel ->
                            ( { model | appState = InGame leftoverFrameTime (RoundOver finishedRound Dialog.NotOpen) }, Cmd.none )

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
                InGame _ (Active _ (Spawning _ ( Live, _ ))) ->
                    recordInteractionBefore firstUpdateTick

                InGame _ (Active _ (Moving lastTick ( Live, _ ))) ->
                    recordInteractionBefore (Tick.succ lastTick)

                _ ->
                    identity

        recordInteractionBefore : Tick -> Round -> Round
        recordInteractionBefore tick =
            modifyKurves <| modifyAlive <| List.map (recordUserInteraction newPressedButtons tick)
    in
    { model
        | pressedButtons = newPressedButtons
        , appState = modifyGameState (modifyMidRoundState (modifyRound howToModifyRound)) model.appState
    }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch <|
        (case model.appState of
            InMenu SplashScreen _ ->
                Sub.none

            InMenu Lobby _ ->
                Sub.none

            InGame _ (Active NotPaused (Spawning spawnState plannedMidRoundState)) ->
                Time.every (1000 / model.config.spawn.flickerTicksPerSecond) (always <| SpawnTick spawnState plannedMidRoundState)

            InGame leftoverTimeFromPreviousFrame (Active NotPaused (Moving lastTick midRoundState)) ->
                Browser.Events.onAnimationFrameDelta
                    (\delta ->
                        AnimationFrame
                            { delta = delta
                            , leftoverTimeFromPreviousFrame = leftoverTimeFromPreviousFrame
                            , lastTick = lastTick
                            }
                            midRoundState
                    )

            InGame _ (Active Paused _) ->
                Sub.none

            InGame _ (RoundOver _ _) ->
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

        InGame _ gameState ->
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
                        , pauseOverlay gameState
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
