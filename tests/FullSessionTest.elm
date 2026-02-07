module FullSessionTest exposing (theTest)

import App exposing (AppState(..))
import Config exposing (Config)
import Expect
import Input exposing (Button(..))
import List exposing (repeat)
import Main exposing (Model, Msg(..))
import Menu exposing (MenuState(..))
import Players exposing (initialPlayers)
import Random
import Set
import Test
import TestHelpers.Effects exposing (clearsEverything, drawsBodySquares)
import TestHelpers.EndToEnd exposing (endToEndTest)
import TestHelpers.ListLength exposing (expectAtLeast, expectExactly)
import TestHelpers.PlayerInput exposing (press, pressAndRelease, release)
import TestHelpers.Randomness exposing (withSeedIfInMenu)
import Types.FrameTime exposing (FrameTime)


theTest : Test.Test
theTest =
    let
        ( actualModel, actualEffects ) =
            endToEndTest initialModel messages
    in
    Test.describe "End-to-end test of an entire session"
        [ Test.test "Resulting model is correct" <|
            \_ ->
                actualModel
                    |> withSeedIfInMenu dummySeed
                    |> Expect.equal expectedModel
        , Test.test "Body squares were drawn a considerable number of times" <|
            \_ ->
                actualEffects
                    |> List.filter drawsBodySquares
                    |> expectAtLeast 100 "body-drawing effects"
        , Test.test "The canvas was cleared exactly twice (when starting the round and when replaying it)" <|
            \_ ->
                actualEffects
                    |> List.filter clearsEverything
                    |> expectExactly 2 "clear-everything effects"
        ]


config : Config
config =
    Config.default


initialModel : Model
initialModel =
    { pressedButtons = Set.empty
    , appState = InMenu SplashScreen (Random.initialSeed 1337)
    , config = config
    , players = initialPlayers
    }


messages : List Msg
messages =
    List.concat
        [ -- User proceeds to lobby:
          pressAndRelease (Key "Space")

        -- Green joins:
        , pressAndRelease (Key "ArrowLeft")

        -- Game is started:
        , pressAndRelease (Key "Space")

        -- Kurves spawn:
        , repeat 12 SpawnTick

        -- A short while passes by:
        , repeat 20 (AnimationFrame frameDeltaInMs)

        -- Green turns until it crashes into itself:
        , press (Key "ArrowLeft")
        , repeat 166 (AnimationFrame frameDeltaInMs)

        -- Round over; button is released:
        , release (Key "ArrowLeft")

        -- Round is replayed:
        , pressAndRelease (Key "KeyR")

        -- User waits for the replay to finish:
        , repeat 12 SpawnTick
        , repeat 20 (AnimationFrame frameDeltaInMs)
        , repeat 166 (AnimationFrame frameDeltaInMs)

        -- User quits to lobby:
        , pressAndRelease (Key "Escape")
        , pressAndRelease (Key "ArrowLeft")
        , pressAndRelease (Key "Enter")
        ]


expectedModel : Model
expectedModel =
    { pressedButtons = Set.empty
    , appState = InMenu Lobby dummySeed
    , config = config
    , players = initialPlayers
    }


frameDeltaInMs : FrameTime
frameDeltaInMs =
    1000 / toFloat refreshRate


refreshRate : Int
refreshRate =
    60


dummySeed : Random.Seed
dummySeed =
    Random.initialSeed 8355608
