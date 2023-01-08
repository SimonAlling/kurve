module Main exposing (main)

import App exposing (AppState(..), modifyGameState)
import Browser
import Canvas exposing (rect, shapes)
import Config exposing (Config)
import Dict
import Drawing exposing (bodyDrawingCmd, clearEverything, drawSpawnIfAndOnlyIf, headDrawingCmd)
import GUI.EndScreen exposing (endScreen)
import GUI.Lobby exposing (lobby)
import GUI.Scoreboard exposing (scoreboard)
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
import Types.Score exposing (Score(..))
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
      , appState = InGame <| MidRound Tick.genesis <| prepareLiveRound Config.default (Random.initialSeed 1337) (Dict.map (\_ ( p, _ ) -> ( p, Score 0 )) initialPlayers |> Dict.filter (\k _ -> k == 3)) Set.empty
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
    ( PreRound
        { kurvesLeft = Tuple.second plannedMidRoundState |> .kurves |> .alive
        , ticksLeft = config.spawn.numberOfFlickerTicks
        }
        plannedMidRoundState
    , clearEverything
    )


type Msg
    = GameTick Tick MidRoundState
    | ButtonUsed ButtonDirection Button
    | SpawnTick SpawnState MidRoundState


stepSpawnState : Config -> SpawnState -> ( MidRoundState -> GameState, Cmd msg )
stepSpawnState config { kurvesLeft, ticksLeft } =
    case kurvesLeft of
        [] ->
            -- All Kurves have spawned.
            ( MidRound <| Tick.genesis, Cmd.none )

        spawning :: waiting ->
            let
                newSpawnState : SpawnState
                newSpawnState =
                    if ticksLeft == 0 then
                        { kurvesLeft = waiting, ticksLeft = config.spawn.numberOfFlickerTicks }

                    else
                        { kurvesLeft = spawning :: waiting, ticksLeft = ticksLeft - 1 }
            in
            ( PreRound newSpawnState, drawSpawnIfAndOnlyIf (isEven ticksLeft) spawning config.kurves.thickness )


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
                        PostRound newCurrentRound

                    else
                        MidRound tick <| modifyRound (always newCurrentRound) midRoundState
            in
            ( { model | appState = InGame newGameState }
            , [ headDrawingCmd model.config.kurves.thickness newKurves.alive
              , bodyDrawingCmd model.config.kurves.thickness newColoredDrawingPositions
              ]
                |> Cmd.batch
            )

        ButtonUsed Down button ->
            case model.appState of
                InMenu Lobby seed ->
                    case ( button, atLeastOneIsParticipating model.players ) of
                        ( Key "Space", True ) ->
                            startRound model <| prepareLiveRound model.config seed (participating model.players) pressedButtons

                        _ ->
                            ( handleUserInteraction Down button { model | players = handlePlayerJoiningOrLeaving button model.players }, Cmd.none )

                InGame (PostRound finishedRound) ->
                    case button of
                        Key "KeyR" ->
                            startRound model <| prepareReplayRound model.config (initialStateForReplaying finishedRound)

                        Key "Escape" ->
                            returnToLobby finishedRound.seed model

                        Key "Space" ->
                            let
                                newModel : Model
                                newModel =
                                    { model | players = includeResultsFrom finishedRound model.players }
                            in
                            if newModel.config.game.isGameOver (participating newModel.players) then
                                gameOver finishedRound.seed newModel

                            else
                                startRound newModel <| prepareLiveRound newModel.config finishedRound.seed (participating newModel.players) pressedButtons

                        _ ->
                            ( handleUserInteraction Down button model, Cmd.none )

                InMenu GameOver seed ->
                    case button of
                        Key "Space" ->
                            returnToLobby seed model

                        _ ->
                            ( handleUserInteraction Down button model, Cmd.none )

                _ ->
                    ( handleUserInteraction Down button model, Cmd.none )

        ButtonUsed Up key ->
            ( handleUserInteraction Up key model, Cmd.none )


gameOver : Random.Seed -> Model -> ( Model, Cmd msg )
gameOver seed model =
    ( { model | appState = InMenu GameOver seed }, clearEverything )


returnToLobby : Random.Seed -> Model -> ( Model, Cmd msg )
returnToLobby seed model =
    ( { model | appState = InMenu Lobby seed, players = everyoneLeaves model.players }, clearEverything )


handleUserInteraction : ButtonDirection -> Button -> Model -> Model
handleUserInteraction direction button model =
    let
        newPressedButtons : Set String
        newPressedButtons =
            updatePressedButtons direction button model.pressedButtons

        howToModifyRound : Round -> Round
        howToModifyRound =
            case model.appState of
                InGame (MidRound lastTick ( Live, _ )) ->
                    recordInteractionBefore (Tick.succ lastTick)

                InGame (PreRound _ ( Live, _ )) ->
                    recordInteractionBefore firstUpdateTick

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
            InMenu Lobby _ ->
                Sub.none

            InGame (PostRound _) ->
                Sub.none

            InGame (PreRound spawnState plannedMidRoundState) ->
                Time.every (1000 / model.config.spawn.flickerTicksPerSecond) (always <| SpawnTick spawnState plannedMidRoundState)

            InGame (MidRound lastTick midRoundState) ->
                Time.every (1000 / Tickrate.toFloat model.config.kurves.tickrate) (always <| GameTick (Tick.succ lastTick) midRoundState)

            InMenu GameOver _ ->
                Sub.none
        )
            :: inputSubscriptions ButtonUsed


view : Model -> Html Msg
view model =
    let
        pixelToRenderable ( x, y ) =
            rect ( toFloat x, toFloat y ) 1 1

        renderable =
            case model.appState of
                InGame gameState ->
                    case gameState of
                        MidRound _ ( _, { occupiedPixels } ) ->
                            shapes [] (occupiedPixels |> Set.toList |> List.map pixelToRenderable)

                        _ ->
                            shapes [] []

                InMenu _ _ ->
                    shapes [] []
    in
    div
        [ Attr.id "wrapper"
        ]
        [ div
            [ Attr.id "border"
            ]
            [ Canvas.toHtml ( 559, 480 ) [] [ renderable ]
            , canvas
                [ Attr.id "canvas_overlay"
                , Attr.width 559
                , Attr.height 480
                , Attr.class "overlay"
                ]
                []
            , case model.appState of
                InMenu Lobby _ ->
                    lobby model.players

                InMenu GameOver _ ->
                    endScreen model.players

                _ ->
                    Html.text ""
            ]
        , scoreboard model.appState model.players
        ]


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }
