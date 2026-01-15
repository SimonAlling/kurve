module TestScenarios.CrashIntoKurveTiming exposing (config, expectedOutcome, spawnedKurves)

import Colors
import Config exposing (Config)
import Holes exposing (HoleInit(..), makeInitialHoleStatus)
import TestScenarioHelpers exposing (EffectsExpectation(..), RoundOutcome, makeZombieKurve, playerIds, tickNumber)
import Types.Angle exposing (Angle(..))
import Types.Kurve exposing (Kurve)


config : Config
config =
    Config.default


red : Float -> Kurve
red y_red =
    makeZombieKurve
        { color = Colors.red
        , id = playerIds.red
        , state =
            { position = ( 149.5, y_red )
            , direction = Angle (pi / 2)
            , holeStatus =
                makeInitialHoleStatus config.kurves InitNoHoles
            }
        }


green : Kurve
green =
    makeZombieKurve
        { color = Colors.green
        , id = playerIds.green
        , state =
            { position = ( 99.5, 106.5 )
            , direction = Angle (pi / 2 + 0.02)
            , holeStatus =
                makeInitialHoleStatus config.kurves InitNoHoles
            }
        }


spawnedKurves : Float -> List Kurve
spawnedKurves y_red =
    [ red y_red, green ]


expectedOutcome : RoundOutcome
expectedOutcome =
    { tickThatShouldEndIt = tickNumber 226
    , howItShouldEnd =
        { aliveAtTheEnd = [ { id = playerIds.red } ]
        , deadAtTheEnd =
            [ { id = playerIds.green
              , theDrawingPositionItNeverMadeItTo = { x = 325, y = 101 }
              }
            ]
        }
    , effectsItShouldProduce = DoNotCare
    }
