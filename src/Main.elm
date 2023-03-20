module Main exposing (main)

import App exposing (AppState(..), modifyGameState)
import Browser
import Canvas exposing (bodyDrawingCmd, clearEverything, drawSpawnIfAndOnlyIf, headDrawingCmd)
import Config exposing (Config)
import GUI.EndScreen exposing (endScreen)
import GUI.Lobby exposing (lobby)
import GUI.Scoreboard exposing (scoreboard)
import GUI.SplashScreen exposing (splashScreen)
import Game exposing (GameState(..), MidRoundState, MidRoundStateVariant(..), SpawnState, checkIndividualKurve, firstUpdateTick, modifyMidRoundState, modifyRound, prepareLiveRound, prepareReplayRound, recordUserInteraction)
import Html exposing (Html, canvas, div)
import Html.Attributes as Attr
import Input exposing (Button(..), ButtonDirection(..), inputSubscriptions, updatePressedButtons)
import Menu exposing (MenuState(..))
import Players exposing (AllPlayers, atLeastOneIsParticipating, everyoneLeaves, handlePlayerJoiningOrLeaving, includeResultsFrom, initialPlayers, participating)
import Random
import Round exposing (Round, initialStateForReplaying, modifyAlive, modifyKurves, roundIsOver)
import Set exposing (Set)
import Time
import Types.Tick as Tick exposing (Tick)
import Types.Tickrate as Tickrate
import Util exposing (isEven)


type alias Model =
    { pressedButtons : Set String
    , appState : AppState
    , config : Config
    , players : AllPlayers
    }


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
    ( { model | appState = InGame gameState }, cmd )


newRoundGameStateAndCmd : Config -> MidRoundState -> ( GameState, Cmd msg )
newRoundGameStateAndCmd config plannedMidRoundState =
    ( Spawning
        { kurvesLeft = Tuple.second plannedMidRoundState |> .kurves |> .alive
        , ticksLeft = config.spawn.numberOfFlickerTicks
        }
        plannedMidRoundState
    , clearEverything
    )


type Msg
    = SpawnTick SpawnState MidRoundState
    | GameTick Tick MidRoundState
    | ButtonUsed ButtonDirection Button


stepSpawnState : Config -> SpawnState -> ( MidRoundState -> GameState, Cmd msg )
stepSpawnState config { kurvesLeft, ticksLeft } =
    case kurvesLeft of
        [] ->
            -- All Kurves have spawned.
            ( Moving <| Tick.genesis, Cmd.none )

        spawning :: waiting ->
            let
                newSpawnState : SpawnState
                newSpawnState =
                    if ticksLeft == 0 then
                        { kurvesLeft = waiting, ticksLeft = config.spawn.numberOfFlickerTicks }

                    else
                        { kurvesLeft = spawning :: waiting, ticksLeft = ticksLeft - 1 }
            in
            ( Spawning newSpawnState, drawSpawnIfAndOnlyIf (isEven ticksLeft) spawning config.kurves.thickness )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ pressedButtons } as model) =
    case msg of
        SpawnTick spawnState plannedMidRoundState ->
            stepSpawnState model.config spawnState
                |> Tuple.mapFirst (\makeGameState -> { model | appState = InGame <| makeGameState plannedMidRoundState })

        GameTick tick (( _, currentRound ) as midRoundState) ->
            let
                ( newKurvesGenerator, newOccupiedPixels, newColoredDrawingPositions ) =
                    List.foldr
                        (checkIndividualKurve model.config tick)
                        ( Random.constant
                            { alive = [] -- We start with the empty list because the new one we'll create may not include all the Kurves from the old one.
                            , dead = currentRound.kurves.dead -- Dead Kurves, however, will not spring to life again.
                            }
                        , currentRound.occupiedPixels
                        , []
                        )
                        currentRound.kurves.alive

                ( newKurves, newSeed ) =
                    Random.step newKurvesGenerator currentRound.seed

                newCurrentRound : Round
                newCurrentRound =
                    { kurves = newKurves
                    , occupiedPixels = newOccupiedPixels
                    , history = currentRound.history
                    , seed = newSeed
                    }

                newGameState : GameState
                newGameState =
                    if roundIsOver newKurves then
                        RoundOver newCurrentRound

                    else
                        Moving tick <| modifyRound (always newCurrentRound) midRoundState
            in
            ( { model | appState = InGame newGameState }
            , [ headDrawingCmd model.config.kurves.thickness newKurves.alive
              , bodyDrawingCmd model.config.kurves.thickness newColoredDrawingPositions
              ]
                |> Cmd.batch
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
                            startRound model <| prepareLiveRound model.config seed (participating model.players) pressedButtons

                        _ ->
                            ( handleUserInteraction Down button { model | players = handlePlayerJoiningOrLeaving button model.players }, Cmd.none )

                InGame (RoundOver finishedRound) ->
                    let
                        newModel : Model
                        newModel =
                            { model | players = includeResultsFrom finishedRound model.players }

                        gameIsOver : Bool
                        gameIsOver =
                            newModel.config.game.isGameOver (participating newModel.players)
                    in
                    case button of
                        Key "KeyR" ->
                            startRound model <| prepareReplayRound model.config (initialStateForReplaying finishedRound)

                        Key "Escape" ->
                            -- Quitting after the final round is not allowed in the original game.
                            if not gameIsOver then
                                goToLobby finishedRound.seed model

                            else
                                ( handleUserInteraction Down button model, Cmd.none )

                        Key "Space" ->
                            if gameIsOver then
                                gameOver finishedRound.seed newModel

                            else
                                startRound newModel <| prepareLiveRound newModel.config finishedRound.seed (participating newModel.players) pressedButtons

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
                InGame (Spawning _ ( Live, _ )) ->
                    recordInteractionBefore firstUpdateTick

                InGame (Moving lastTick ( Live, _ )) ->
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

            InGame (Spawning spawnState plannedMidRoundState) ->
                Time.every (1000 / model.config.spawn.flickerTicksPerSecond) (always <| SpawnTick spawnState plannedMidRoundState)

            InGame (Moving lastTick midRoundState) ->
                Time.every (1000 / Tickrate.toFloat model.config.kurves.tickrate) (always <| GameTick (Tick.succ lastTick) midRoundState)

            InGame (RoundOver _) ->
                Sub.none

            InMenu GameOver _ ->
                Sub.none
        )
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
