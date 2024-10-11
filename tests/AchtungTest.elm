module AchtungTest exposing (tests)

import Color
import Config
import Expect
import Game exposing (MidRoundState, MidRoundStateVariant(..), TickResult(..), reactToTick)
import Random
import Round exposing (Round)
import Set
import String
import Test exposing (Test, describe, test)
import Types.Angle exposing (Angle(..))
import Types.Kurve exposing (HoleStatus(..), Kurve)
import Types.Tick as Tick exposing (Tick)


tests : Test
tests =
    describe "Achtung, die Kurve!"
        [ test
            "Kurves move forward by default when game is active"
            (\_ ->
                let
                    currentKurve : Kurve
                    currentKurve =
                        { color = Color.white
                        , id = 5
                        , controls = ( Set.empty, Set.empty )
                        , state =
                            { position = ( 100, 100 )
                            , direction = Angle 0
                            , holeStatus = Unholy 60
                            }
                        , stateAtSpawn =
                            { position = ( 100, 100 )
                            , direction = Angle 0
                            , holeStatus = Unholy 60
                            }
                        , reversedInteractions = []
                        }

                    currentRound : Round
                    currentRound =
                        { kurves =
                            { alive = [ currentKurve ]
                            , dead = []
                            }
                        , occupiedPixels = Set.empty
                        , initialState =
                            { seedAfterSpawn = Random.initialSeed 0
                            , spawnedKurves = []
                            }
                        , seed = Random.initialSeed 0
                        }

                    tickResult : TickResult
                    tickResult =
                        reactToTick Config.default (Tick.succ Tick.genesis) ( Live, currentRound ) |> Tuple.first
                in
                case tickResult of
                    RoundKeepsGoing _ ( _, round ) ->
                        case round.kurves.alive of
                            kurve :: [] ->
                                Expect.equal kurve.state.position
                                    ( 101, 100 )

                            _ ->
                                Expect.fail "Expected exactly one alive Kurve"

                    RoundEnds _ ->
                        Expect.fail "Expected round not to end"
            )
        , test
            "A Kurve that crashes into the wall dies"
            (\_ ->
                let
                    currentKurve : Kurve
                    currentKurve =
                        { color = Color.white
                        , id = 5
                        , controls = ( Set.empty, Set.empty )
                        , state =
                            { position = ( 2.5, 100 )
                            , direction = Angle pi
                            , holeStatus = Unholy 60
                            }
                        , stateAtSpawn =
                            { position = ( 100, 100 )
                            , direction = Angle 0
                            , holeStatus = Unholy 60
                            }
                        , reversedInteractions = []
                        }

                    currentRound : Round
                    currentRound =
                        { kurves =
                            { alive = [ currentKurve ]
                            , dead = []
                            }
                        , occupiedPixels = Set.empty
                        , initialState =
                            { seedAfterSpawn = Random.initialSeed 0
                            , spawnedKurves = []
                            }
                        , seed = Random.initialSeed 0
                        }
                in
                currentRound
                    |> expectRoundOutcome
                        { tickThatShouldEndIt = tickNumber 2
                        , howItShouldEnd =
                            \round ->
                                case ( round.kurves.alive, round.kurves.dead ) of
                                    ( [], kurve :: [] ) ->
                                        Expect.equal kurve.state.position
                                            ( 0.5, 100 )

                                    _ ->
                                        Expect.fail "Expected exactly one dead Kurve and no alive ones"
                        }
            )
        ]


{-| A description of when and how a round should end.
-}
type alias RoundOutcome =
    { tickThatShouldEndIt : Tick
    , howItShouldEnd : Round -> Expect.Expectation
    }


expectRoundOutcome : RoundOutcome -> Round -> Expect.Expectation
expectRoundOutcome { tickThatShouldEndIt, howItShouldEnd } round =
    let
        recurse : Tick -> MidRoundState -> Expect.Expectation
        recurse tick midRoundState =
            let
                tickResult : TickResult
                tickResult =
                    reactToTick Config.default (Tick.succ tick) midRoundState |> Tuple.first
            in
            case tickResult of
                RoundKeepsGoing nextTick nextMidRoundState ->
                    if nextTick == tickThatShouldEndIt then
                        Expect.fail <| "Expected round to end on tick " ++ showTick tickThatShouldEndIt ++ " but it did not."

                    else
                        recurse nextTick nextMidRoundState

                RoundEnds actualRoundResult ->
                    let
                        actualEndTick : Tick
                        actualEndTick =
                            Tick.succ tick
                    in
                    if actualEndTick == tickThatShouldEndIt then
                        howItShouldEnd actualRoundResult

                    else
                        Expect.fail <| "Expected round to end on tick " ++ showTick tickThatShouldEndIt ++ " but it ended on tick " ++ showTick actualEndTick ++ "."
    in
    recurse Tick.genesis ( Live, round )


showTick : Tick -> String
showTick =
    Tick.toInt >> String.fromInt


tickNumber : Int -> Tick
tickNumber n =
    case Tick.fromInt n of
        Nothing ->
            Debug.todo <| "Tick cannot be negative (was " ++ String.fromInt n ++ ")."

        Just tick ->
            tick
