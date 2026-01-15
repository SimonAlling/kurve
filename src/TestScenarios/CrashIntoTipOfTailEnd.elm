module TestScenarios.CrashIntoTipOfTailEnd exposing (config, expectedOutcome, spawnedKurves)

import Colors
import Config exposing (Config)
import Holes exposing (HoleInit(..), HoleStatus(..), makeInitialHoleStatus)
import TestScenarioHelpers exposing (EffectsExpectation(..), RoundOutcome, makeZombieKurve, playerIds, tickNumber)
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
            { position = ( 59.5, 59.5 )
            , direction = Angle (pi / 4)
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
            { position = ( 29.5, 29.5 )
            , direction = Angle (pi / 4)
            , holeStatus =
                makeInitialHoleStatus config.kurves InitNoHoles
            }
        }


spawnedKurves : List Kurve
spawnedKurves =
    [ red, green ]


expectedOutcome : RoundOutcome
expectedOutcome =
    { tickThatShouldEndIt = tickNumber 39
    , howItShouldEnd =
        { aliveAtTheEnd = [ { id = playerIds.red } ]
        , deadAtTheEnd =
            [ { id = playerIds.green
              , theDrawingPositionItNeverMadeItTo = { x = 57, y = 57 }
              }
            ]
        }
    , effectsItShouldProduce = DoNotCare
    }
