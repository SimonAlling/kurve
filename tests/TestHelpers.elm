module TestHelpers exposing
    ( defaultConfigWithSpeed
    , expectRoundOutcome
    )

import Config exposing (Config, KurveConfig)
import Expect
import Game
    exposing
        ( TickResult(..)
        , prepareRoundFromKnownInitialState
        , reactToTick
        )
import Round exposing (Round, RoundInitialState)
import TestScenarioHelpers exposing (RoundEndingInterpretation, RoundOutcome)
import Types.Speed exposing (Speed)
import Types.Tick as Tick exposing (Tick)
import World


expectRoundOutcome : Config -> RoundOutcome -> RoundInitialState -> Expect.Expectation
expectRoundOutcome config { tickThatShouldEndIt, howItShouldEnd } initialState =
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
        recurse tick midRoundState =
            let
                nextTick : Tick
                nextTick =
                    Tick.succ tick

                tickResult : TickResult Round
                tickResult =
                    reactToTick config nextTick midRoundState |> Tuple.first
            in
            case tickResult of
                RoundKeepsGoing nextMidRoundState ->
                    recurse nextTick nextMidRoundState

                RoundEnds actualRoundResult ->
                    let
                        actualEndTick : Tick
                        actualEndTick =
                            Tick.succ tick
                    in
                    ( actualEndTick, actualRoundResult )

        round : Round
        round =
            prepareRoundFromKnownInitialState initialState
    in
    recurse Tick.genesis round


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
