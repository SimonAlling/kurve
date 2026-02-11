module TestScenarios.HoleStatusPersistsBetweenRounds exposing (config, spawnedKurves)

import Colors
import Config exposing (Config)
import Holes exposing (HoleStatus(..), Holiness(..))
import Random
import TestScenarioHelpers exposing (makeZombieKurve, playerIds)
import Types.Angle exposing (Angle(..))
import Types.Kurve exposing (Kurve)


config : Config
config =
    Config.default


red : Kurve
red =
    makeZombieKurve
        { color = Colors.red
        , id = playerIds.red
        , state =
            { position = ( 100, config.world.height - 10 |> toFloat )
            , direction = Angle 0
            , holeStatus =
                RandomHoles
                    { holiness = Solid
                    , ticksLeft = 100
                    , holeSeed = Random.initialSeed 0
                    }
            }
        }


orange : Kurve
orange =
    makeZombieKurve
        { color = Colors.orange
        , id = playerIds.orange
        , state =
            { position = ( 200, config.world.height - 20 |> toFloat )
            , direction = Angle 0
            , holeStatus =
                RandomHoles
                    { holiness = Solid
                    , ticksLeft = 100
                    , holeSeed = Random.initialSeed 0
                    }
            }
        }


green : Kurve
green =
    makeZombieKurve
        { color = Colors.green
        , id = playerIds.green
        , state =
            { position = ( 300, config.world.height - 30 |> toFloat )
            , direction = Angle 0
            , holeStatus =
                RandomHoles
                    { holiness = Solid
                    , ticksLeft = 100
                    , holeSeed = Random.initialSeed 0
                    }
            }
        }


blue : Kurve
blue =
    makeZombieKurve
        { color = Colors.blue
        , id = playerIds.blue
        , state =
            { position = ( 50, 50 ) -- Plenty of space to survive the entire round
            , direction = Angle (pi / 2)
            , holeStatus =
                NoHoles
            }
        }


spawnedKurves : List Kurve
spawnedKurves =
    -- We deliberately use players with non-consecutive IDs in an attempt to prevent the test case from just _happening_ to pass.
    [ red, orange, green, blue ]
