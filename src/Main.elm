module Main exposing (main)

import Browser
import Canvas exposing (bodyDrawingCmd, clearEverything, clearOverlay, drawSpawnIfAndOnlyIf, headDrawingCmd)
import Config exposing (config)
import Game exposing (GameState(..), MidRoundState, MidRoundStateVariant(..), SpawnState, checkIndividualPlayer, firstUpdateTick, modifyMidRoundState, modifyRound, prepareLiveRound, prepareReplayRound, recordUserInteraction)
import Html exposing (Html, canvas, div)
import Html.Attributes as Attr
import Input exposing (Button(..), ButtonDirection(..), inputSubscriptions, updatePressedButtons)
import Random
import Round exposing (Round, initialStateForReplaying, modifyAlive, modifyPlayers, roundIsOver)
import Set exposing (Set)
import Time
import Types.Tick as Tick exposing (Tick)
import Types.Tickrate as Tickrate
import Util exposing (isEven)


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
        { playersLeft = Tuple.second plannedMidRoundState |> .players |> .alive
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

        GameTick tick (( _, currentRound ) as midRoundState) ->
            let
                ( newPlayersGenerator, newOccupiedPixels, newColoredDrawingPositions ) =
                    List.foldr
                        (checkIndividualPlayer tick)
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
            , [ clearOverlay { x = 0, y = 0, width = config.world.width, height = config.world.height }
              , headDrawingCmd config.kurves.thickness newPlayers.alive
              , bodyDrawingCmd config.kurves.thickness newColoredDrawingPositions
              ]
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
                MidRound lastTick ( Live, _ ) ->
                    recordInteractionBefore (Tick.succ lastTick)

                PreRound _ ( Live, _ ) ->
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


view : Model -> Html Msg
view _ =
    div
        [ Attr.id "wrapper"
        ]
        [ div
            [ Attr.id "border4"
            , Attr.class "border"
            ]
            [ div
                [ Attr.id "border3"
                , Attr.class "border"
                ]
                [ div
                    [ Attr.id "border2"
                    , Attr.class "border"
                    ]
                    [ div
                        [ Attr.id "border1"
                        , Attr.class "border"
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
                    ]
                ]
            ]
        ]


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }
