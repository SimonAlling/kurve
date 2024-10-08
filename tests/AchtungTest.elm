module AchtungTest exposing (tests)

import Color
import Config
import Expect
import Game exposing (ActiveGameState(..), GameState(..), MidRoundState, MidRoundStateVariant(..), reactToTick)
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

                    newGameState : GameState
                    newGameState =
                        reactToTick Config.default (Tick.succ Tick.genesis) ( Live, currentRound ) |> Tuple.first
                in
                case newGameState of
                    Active _ (Moving _ ( _, round )) ->
                        case round.kurves.alive of
                            kurve :: [] ->
                                Expect.equal kurve.state.position
                                    ( 101, 100 )

                            _ ->
                                Expect.fail "Expected exactly one alive Kurve"

                    _ ->
                        Expect.fail "Expected active game state with Kurves moving"
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
                            { position = ( 1, 100 )
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
                        { tickThatShouldEndIt = Tick.succ Tick.genesis
                        , howItShouldEnd =
                            \round ->
                                case ( round.kurves.alive, round.kurves.dead ) of
                                    ( [], kurve :: [] ) ->
                                        Expect.equal kurve.state.position
                                            ( 0, 100 )

                                    _ ->
                                        Expect.fail "Expected exactly one dead Kurve and no alive ones"
                        }
            )
        , test
            "A Kurve dies exactly when it crashes into the wall"
            (\_ ->
                let
                    kurve : Kurve
                    kurve =
                        { color = Color.white
                        , id = 1
                        , controls = ( Set.empty, Set.empty )
                        , state =
                            { position = ( 2.5, 100 )
                            , direction = Angle pi
                            , holeStatus = Unholy 50
                            }
                        , stateAtSpawn =
                            { position = ( 0, 0 )
                            , direction = Angle 0
                            , holeStatus = Unholy 0
                            }
                        , reversedInteractions = []
                        }

                    round : Round
                    round =
                        { kurves =
                            { alive = [ kurve ]
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
                round
                    |> expectRoundOutcome
                        { tickThatShouldEndIt = Tick.succ (Tick.succ Tick.genesis)
                        , howItShouldEnd =
                            \finishedRound ->
                                Expect.equal finishedRound.kurves
                                    { alive = []
                                    , dead =
                                        [ { kurve | state = { position = ( 0.5, 100 ), direction = Angle pi, holeStatus = Unholy 48 } }
                                        ]
                                    }
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
                nextGameState : GameState
                nextGameState =
                    reactToTick Config.default (Tick.succ tick) midRoundState |> Tuple.first
            in
            case nextGameState of
                Active _ activeGameState ->
                    case activeGameState of
                        Moving nextTick nextMidRoundState ->
                            if nextTick == tickThatShouldEndIt then
                                Expect.fail <| "Expected round to end on tick " ++ showTick tickThatShouldEndIt ++ " but it did not."

                            else
                                recurse nextTick nextMidRoundState

                        Spawning _ _ ->
                            Expect.fail <| "Did not expect players to be spawning as a result of tick " ++ showTick tick ++ "."

                RoundOver actualRoundResult _ ->
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
