module TestScenarios.CrashInSameTick exposing (config, spawnedKurves)

import Colors
import Config exposing (Config)
import Holes exposing (HoleStatus(..))
import TestScenarioHelpers exposing (makeZombieKurve, playerIds)
import Types.Angle exposing (Angle(..))
import Types.Kurve exposing (Kurve)


config : Config
config =
    Config.default


red : Float -> Kurve
red y =
    makeZombieKurve
        { color = Colors.red
        , id = playerIds.red
        , state =
            { position = ( 100, y )
            , direction = Angle 0
            , holeStatus = NoHoles
            }
        }


green : Float -> Kurve
green y =
    makeZombieKurve
        { color = Colors.green
        , id = playerIds.green
        , state =
            { position = ( 200, y )
            , direction = Angle 0
            , holeStatus = NoHoles
            }
        }


blue : Float -> Kurve
blue y =
    makeZombieKurve
        { color = Colors.blue
        , id = playerIds.blue
        , state =
            { position = ( 300, y )
            , direction = Angle 0
            , holeStatus = NoHoles
            }
        }


spawnedKurves : Float -> List Kurve
spawnedKurves y =
    [ red y, green y, blue y ]
