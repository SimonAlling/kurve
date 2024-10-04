module AchtungTest exposing (tests)

import App exposing (AppState(..))
import Color
import Config
import Dict
import Expect
import Game exposing (ActiveGameState(..), GameState(..), MidRoundStateVariant(..), Paused(..))
import Main exposing (Model, Msg(..), update)
import Random
import Round exposing (Round)
import Set
import Test exposing (Test, describe, test)
import Types.Angle exposing (Angle(..))
import Types.Kurve exposing (HoleStatus(..), Kurve)
import Types.Tick as Tick


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
                        , history =
                            { initialState =
                                { seedAfterSpawn = Random.initialSeed 0
                                , spawnedKurves = []
                                , pressedButtons = Set.empty
                                }
                            }
                        , seed = Random.initialSeed 0
                        }

                    currentModel : Model
                    currentModel =
                        { pressedButtons = Set.empty
                        , appState = InGame (Active NotPaused (Moving Tick.genesis ( Live, currentRound )))
                        , config = Config.default
                        , players = Dict.empty
                        }

                    newAppState : AppState
                    newAppState =
                        currentModel |> update (GameTick (Tick.succ Tick.genesis) ( Live, currentRound )) |> Tuple.first |> .appState
                in
                case newAppState of
                    InGame gameState ->
                        case gameState of
                            Active _ (Moving _ ( _, round )) ->
                                case round.kurves.alive of
                                    kurve :: [] ->
                                        Expect.equal kurve.state.position
                                            ( 101, 100 )

                                    _ ->
                                        Expect.fail "Expected exactly one alive Kurve"

                            _ ->
                                Expect.fail "Expected active game state with Kurves moving"

                    _ ->
                        Expect.fail "Expected in-game app state"
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
                        , history =
                            { initialState =
                                { seedAfterSpawn = Random.initialSeed 0
                                , spawnedKurves = []
                                , pressedButtons = Set.empty
                                }
                            }
                        , seed = Random.initialSeed 0
                        }

                    currentModel : Model
                    currentModel =
                        { pressedButtons = Set.empty
                        , appState = InGame (Active NotPaused (Moving Tick.genesis ( Live, currentRound )))
                        , config = Config.default
                        , players = Dict.empty
                        }

                    newAppState : AppState
                    newAppState =
                        currentModel |> update (GameTick (Tick.succ Tick.genesis) ( Live, currentRound )) |> Tuple.first |> .appState
                in
                case newAppState of
                    InGame gameState ->
                        case gameState of
                            RoundOver round _ ->
                                case ( round.kurves.alive, round.kurves.dead ) of
                                    ( [], kurve :: [] ) ->
                                        Expect.equal kurve.state.position
                                            ( 0, 100 )

                                    _ ->
                                        Expect.fail "Expected exactly one dead Kurve and no alive ones"

                            _ ->
                                Expect.fail "Expected round to be over"

                    _ ->
                        Expect.fail "Expected in-game app state"
            )
        ]
