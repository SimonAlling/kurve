module TestScenarios.ReplayStraightVerticalLine exposing (config, spawnedKurves)

import Colors
import Config exposing (Config, ReplayConfig)
import Holes exposing (HoleStatus(..))
import TestScenarioHelpers exposing (makeZombieKurve, playerIds)
import Types.Angle exposing (Angle(..))
import Types.Kurve exposing (Kurve)


config : Config
config =
    let
        defaultConfig : Config
        defaultConfig =
            Config.default

        defaultReplayConfig : ReplayConfig
        defaultReplayConfig =
            defaultConfig.replay
    in
    { defaultConfig
        | replay =
            { defaultReplayConfig
                | skipStepInMs = 1000
            }
    }


green : Kurve
green =
    makeZombieKurve
        { color = Colors.green
        , id = playerIds.green
        , state =
            { position = ( 100, 100 )
            , direction = Angle 0
            , holeStatus =
                NoHoles
            }
        }


spawnedKurves : List Kurve
spawnedKurves =
    [ green ]
