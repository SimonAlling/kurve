module StatePersistenceTest exposing (theTest)

import App exposing (AppState(..))
import Config exposing (Config)
import Expect
import GUI.Hints as Hints
import Game exposing (ActiveGameState(..), GameState(..), LiveOrReplay(..), PausedOrNot(..), prepareRoundFromKnownInitialState)
import Holes exposing (HoleStatus(..), Holiness(..))
import Input exposing (Button(..))
import List exposing (repeat)
import Main exposing (Model, Msg(..))
import MainLoop
import Random
import Round exposing (Round, RoundInitialState)
import Set
import Test
import TestHelpers exposing (getNumberOfSpawnTicks)
import TestHelpers.EndToEnd exposing (endToEndTest)
import TestHelpers.PlayerInput exposing (pressAndRelease)
import TestScenarioHelpers exposing (kurvesToInitialAllPlayers, playerIds, roundWith)
import TestScenarios.HoleStatusPersistsBetweenRounds
import Types.FrameTime exposing (FrameTime)
import Types.Kurve exposing (Kurve)
import Types.PlayerId exposing (PlayerId)
import Types.Tick as Tick


theTest : Test.Test
theTest =
    let
        roundInitialState : RoundInitialState
        roundInitialState =
            roundWith TestScenarios.HoleStatusPersistsBetweenRounds.spawnedKurves

        theInitialModel : Model
        theInitialModel =
            initialModel roundInitialState

        numberOfSpawnTicksForAllKurves : Int
        numberOfSpawnTicksForAllKurves =
            getNumberOfSpawnTicks theInitialModel.config.spawn
                * List.length TestScenarios.HoleStatusPersistsBetweenRounds.spawnedKurves

        ( actualModel, _ ) =
            endToEndTest theInitialModel (messages numberOfSpawnTicksForAllKurves)
    in
    Test.describe "Hole-status persistence test"
        [ Test.test "Hole statuses are correctly persisted between rounds" <|
            \_ ->
                case actualModel.appState of
                    InGame (Active (Live ()) NotPaused (Moving _ _ round)) ->
                        round.kurves.alive
                            |> List.map getPlayerIdAndCheckableHoleStatus
                            |> Expect.equal
                                [ ( playerIds.red, RandomHoles { holeSeed = dummySeed, holiness = Solid, ticksLeft = 92 } )
                                , ( playerIds.orange, RandomHoles { holeSeed = dummySeed, holiness = Solid, ticksLeft = 82 } )
                                , ( playerIds.green, RandomHoles { holeSeed = dummySeed, holiness = Solid, ticksLeft = 72 } )
                                , ( playerIds.blue, NoHoles )
                                ]

                    _ ->
                        Debug.todo <| "Unexpected app state: " ++ Debug.toString actualModel.appState
        ]


config : Config
config =
    TestScenarios.HoleStatusPersistsBetweenRounds.config


initialModel : RoundInitialState -> Model
initialModel roundInitialState =
    let
        round : Round
        round =
            prepareRoundFromKnownInitialState config.world roundInitialState
    in
    { pressedButtons = Set.empty
    , appState = InGame (Active (Live ()) NotPaused (Moving MainLoop.noLeftoverFrameTime Tick.genesis round))
    , config = config
    , players = kurvesToInitialAllPlayers TestScenarios.HoleStatusPersistsBetweenRounds.spawnedKurves
    , hints = Hints.initial
    }


messages : Int -> List Msg
messages numberOfSpawnTicks =
    List.concat
        [ -- Enough time passes by for the round to end:
          repeat 28 (AnimationFrame frameDeltaInMs)

        -- User proceeds to next round:
        , pressAndRelease (Key "Space")

        -- Kurves spawn:
        , repeat numberOfSpawnTicks SpawnTick
        ]


getPlayerIdAndCheckableHoleStatus : Kurve -> ( PlayerId, HoleStatus )
getPlayerIdAndCheckableHoleStatus kurve =
    ( kurve.id, kurve.state.holeStatus |> withDummySeedIfRandom )


withDummySeedIfRandom : HoleStatus -> HoleStatus
withDummySeedIfRandom holeStatus =
    case holeStatus of
        RandomHoles stuff ->
            RandomHoles { stuff | holeSeed = dummySeed }

        NoHoles ->
            NoHoles


frameDeltaInMs : FrameTime
frameDeltaInMs =
    1000 / toFloat refreshRate


refreshRate : Int
refreshRate =
    60


dummySeed : Random.Seed
dummySeed =
    Random.initialSeed 8355608
