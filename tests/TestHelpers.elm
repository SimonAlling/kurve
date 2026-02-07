module TestHelpers exposing (expectRoundOutcome, playOutRound)

import App exposing (AppState(..))
import Config exposing (Config)
import Effect exposing (Effect)
import Expect
import Game
    exposing
        ( ActiveGameState(..)
        , GameState(..)
        , LiveOrReplay(..)
        , PausedOrNot(..)
        , TickResult(..)
        , prepareRoundFromKnownInitialState
        , reactToTick
        )
import Main exposing (Model, Msg(..), update)
import Players exposing (initialPlayers)
import Round exposing (FinishedRound(..), Round, RoundInitialState)
import Set
import TestScenarioHelpers
    exposing
        ( EffectsExpectation(..)
        , RefreshRate
        , RoundEndingInterpretation
        , RoundOutcome
        )
import Types.FrameTime exposing (FrameTime)
import Types.Tick as Tick exposing (Tick)
import World


expectRoundOutcome : Config -> RoundOutcome -> RoundInitialState -> Expect.Expectation
expectRoundOutcome config { tickThatShouldEndIt, howItShouldEnd, effectsItShouldProduce } initialState =
    let
        ( actualEndTick, actualRoundResult ) =
            playOutRound config initialState
    in
    Expect.all
        [ \_ ->
            if actualEndTick == tickThatShouldEndIt then
                Expect.pass

            else
                Expect.fail <| "Expected round to end on tick " ++ showTick tickThatShouldEndIt ++ " but it ended on tick " ++ showTick actualEndTick ++ "."
        , \_ ->
            interpretRoundEnding actualRoundResult
                |> Expect.equal howItShouldEnd
        , \_ ->
            case effectsItShouldProduce of
                DoNotCare ->
                    Expect.pass

                ExpectEffects expectedEffects ->
                    -- It takes a non-negligible amount of time to play out a non-trivial round, so we only do it if the effects are of interest.
                    playOutRoundWithEffects config initialState
                        |> Expect.equalLists expectedEffects
        ]
        ()


interpretRoundEnding : FinishedRound -> RoundEndingInterpretation
interpretRoundEnding (Finished { kurves }) =
    { aliveAtTheEnd =
        kurves.alive
            |> List.map
                (\kurve ->
                    { id = kurve.id
                    }
                )
    , deadAtTheEnd =
        kurves.dead
            |> List.map
                (\kurve ->
                    { id = kurve.id
                    , theDrawingPositionItNeverMadeItTo = World.drawingPosition kurve.state.position
                    }
                )
    }


playOutRound : Config -> RoundInitialState -> ( Tick, FinishedRound )
playOutRound config initialState =
    let
        recurse : Tick -> Round -> ( Tick, FinishedRound )
        recurse lastTick midRoundState =
            let
                incrementedTick : Tick
                incrementedTick =
                    Tick.succ lastTick

                tickResult : TickResult Round
                tickResult =
                    reactToTick config incrementedTick midRoundState |> Tuple.first
            in
            case tickResult of
                RoundKeepsGoing nextMidRoundState ->
                    recurse incrementedTick nextMidRoundState

                RoundEnds tickThatEndedIt actualRoundResult ->
                    ( tickThatEndedIt, Finished actualRoundResult )

        round : Round
        round =
            prepareRoundFromKnownInitialState config.world initialState
    in
    recurse Tick.genesis round


playOutRoundWithEffects : Config -> RoundInitialState -> List Effect
playOutRoundWithEffects config initialState =
    let
        initialRound : Round
        initialRound =
            prepareRoundFromKnownInitialState config.world initialState

        initialGameState : GameState
        initialGameState =
            Active (Live ()) NotPaused <|
                Spawning
                    { kurvesLeft = initialRound |> .kurves |> .alive
                    , alreadySpawnedKurves = []
                    , ticksLeft = config.spawn.numberOfFlickerTicks
                    }
                    initialRound

        initialModel : Model
        initialModel =
            { pressedButtons = Set.empty
            , appState = InGame initialGameState
            , config = config
            , players = initialPlayers
            }

        frameDeltaInMs : FrameTime
        frameDeltaInMs =
            1000 / toFloat refreshRateInTests

        recurse : Msg -> Model -> List Effect -> ( Model, List Effect )
        recurse msg model reversedEffectsSoFar =
            let
                ( newModel, effectForThisUpdate ) =
                    update msg model

                newReversedEffects : List Effect
                newReversedEffects =
                    effectForThisUpdate :: reversedEffectsSoFar
            in
            -- Here we essentially emulate the subscriptions that the complete application hopefully/probably has:
            case newModel.appState of
                InGame (Active _ NotPaused (Spawning _ _)) ->
                    recurse SpawnTick newModel newReversedEffects

                InGame (Active _ NotPaused (Moving _ _ _)) ->
                    recurse (AnimationFrame frameDeltaInMs) newModel newReversedEffects

                InGame (RoundOver _ _ _ _) ->
                    ( newModel, newReversedEffects )

                _ ->
                    Debug.todo <| "Unexpected app state: " ++ Debug.toString newModel.appState
    in
    recurse SpawnTick initialModel []
        |> Tuple.second
        |> List.reverse


showTick : Tick -> String
showTick =
    Tick.toInt >> String.fromInt


refreshRateInTests : RefreshRate
refreshRateInTests =
    60
