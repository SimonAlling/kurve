module TestScenarios.CuttingCornersBasic exposing (config, expectedOutcome, spawnedKurves)

import Colors
import Config exposing (Config)
import TestScenarioHelpers exposing (EffectsExpectation(..), RoundOutcome, makeZombieKurve, playerIds, tickNumber)
import Types.Angle exposing (Angle(..))
import Types.Kurve exposing (HoleStatus(..), Kurve)


config : Config
config =
    Config.default


red : Kurve
red =
    makeZombieKurve
        { color = Colors.red
        , id = playerIds.red
        , state =
            { position = ( 199.5, 99.5 )
            , direction = Angle (pi / 2)
            , holeStatus =
                NoHoles
            }
        }


green : Kurve
green =
    makeZombieKurve
        { color = Colors.green
        , id = playerIds.green
        , state =
            { position = ( 99.5, 195.5 )
            , direction = Angle (3 * pi / 4)
            , holeStatus =
                NoHoles
            }
        }


spawnedKurves : List Kurve
spawnedKurves =
    [ red, green ]


expectedOutcome : RoundOutcome
expectedOutcome =
    { tickThatShouldEndIt = tickNumber 278
    , howItShouldEnd =
        { aliveAtTheEnd = [ { id = playerIds.red } ]
        , deadAtTheEnd =
            [ { id = playerIds.green
              , theDrawingPositionItNeverMadeItTo = { x = 296, y = -1 }
              }
            ]
        }
    , effectsItShouldProduce = DoNotCare
    }
