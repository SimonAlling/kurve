module TestHelpers exposing
    ( defaultConfigWithSpeed
    , expectRoundOutcome
    )

import App exposing (AppState(..))
import Config exposing (Config, KurveConfig)
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
import Round exposing (Round, RoundInitialState)
import Set
import TestScenarioHelpers
    exposing
        ( EffectsExpectation(..)
        , RefreshRate
        , RoundEndingInterpretation
        , RoundOutcome
        )
import Types.FrameTime exposing (FrameTime)
import Types.Speed exposing (Speed)
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
                    playOutRoundWithEffects config initialState
                        |> Expect.equalLists expectedEffects
        ]
        ()


interpretRoundEnding : Round -> RoundEndingInterpretation
interpretRoundEnding { kurves } =
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


playOutRound : Config -> RoundInitialState -> ( Tick, Round )
playOutRound config initialState =
    let
        recurse : Tick -> Round -> ( Tick, Round )
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

                RoundEnds actualRoundResult ->
                    ( incrementedTick, actualRoundResult )

        round : Round
        round =
            prepareRoundFromKnownInitialState initialState
    in
    recurse Tick.genesis round


playOutRoundWithEffects : Config -> RoundInitialState -> List Effect
playOutRoundWithEffects config initialState =
    let
        initialRound : Round
        initialRound =
            prepareRoundFromKnownInitialState initialState

        initialGameState : GameState
        initialGameState =
            Active Live NotPaused <|
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
            , config = Config.default
            , players = initialPlayers
            }

        frameDeltaInMs : FrameTime
        frameDeltaInMs =
            1000 / toFloat refreshRateInTests

        animationFrameMsg : Msg
        animationFrameMsg =
            AnimationFrame frameDeltaInMs

        spawnTickMsg : Msg
        spawnTickMsg =
            SpawnTick

        recurse : Msg -> Model -> List Effect -> ( Model, List Effect )
        recurse msg model reversedEffectsSoFar =
            let
                ( newModel, effectForThisUpdate ) =
                    update msg model
            in
            case newModel.appState of
                InGame (Active _ NotPaused (Spawning _ _)) ->
                    recurse spawnTickMsg newModel (effectForThisUpdate :: reversedEffectsSoFar)

                InGame (Active _ NotPaused (Moving _ _ _)) ->
                    recurse animationFrameMsg newModel (effectForThisUpdate :: reversedEffectsSoFar)

                InGame (RoundOver _ _) ->
                    ( newModel, effectForThisUpdate :: reversedEffectsSoFar )

                _ ->
                    Debug.todo "Unexpected app state"
    in
    recurse spawnTickMsg initialModel []
        |> Tuple.second
        |> List.reverse


showTick : Tick -> String
showTick =
    Tick.toInt >> String.fromInt


defaultConfigWithSpeed : Speed -> Config
defaultConfigWithSpeed speed =
    let
        defaultConfig : Config
        defaultConfig =
            Config.default

        defaultKurveConfig : KurveConfig
        defaultKurveConfig =
            defaultConfig.kurves
    in
    { defaultConfig
        | kurves =
            { defaultKurveConfig
                | speed = speed
            }
    }


refreshRateInTests : RefreshRate
refreshRateInTests =
    60
