module TestHelpers exposing
    ( defaultConfigWithSpeed
    , expectRoundOutcome
    )

import Config exposing (Config, KurveConfig)
import Expect
import Game exposing (MidRoundState, MidRoundStateVariant(..), TickResult(..), prepareRoundFromKnownInitialState, reactToTick)
import Round exposing (Round, RoundInitialState)
import Types.Speed exposing (Speed)
import Types.Tick as Tick exposing (Tick)


{-| A description of when and how a round should end.
-}
type alias RoundOutcome =
    { tickThatShouldEndIt : Tick
    , howItShouldEnd : Round -> Expect.Expectation
    }


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
        , \_ -> howItShouldEnd actualRoundResult
        ]
        ()


playOutRound : Config -> RoundInitialState -> ( Tick, Round )
playOutRound config initialState =
    let
        recurse : Tick -> MidRoundState -> ( Tick, Round )
        recurse tick midRoundState =
            let
                tickResult : TickResult MidRoundState
                tickResult =
                    reactToTick config (Tick.succ tick) midRoundState |> Tuple.first
            in
            case tickResult of
                RoundKeepsGoing nextTick nextMidRoundState ->
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
    recurse Tick.genesis ( Live, round )


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
