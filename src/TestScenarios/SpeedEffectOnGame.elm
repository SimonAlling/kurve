module TestScenarios.SpeedEffectOnGame exposing (config, expectedOutcome, spawnedKurves)

import Colors
import Config exposing (Config)
import Holes exposing (HoleInit(..), HoleStatus(..), makeInitialHoleStatus)
import TestScenarioHelpers exposing (EffectsExpectation(..), RoundOutcome, defaultConfigWithSpeed, makeZombieKurve, playerIds)
import Types.Angle exposing (Angle(..))
import Types.Kurve exposing (Kurve)
import Types.Speed exposing (Speed)
import Types.Tick exposing (Tick)


config : Speed -> Config
config =
    defaultConfigWithSpeed


green : Speed -> Kurve
green speed =
    makeZombieKurve
        { color = Colors.green
        , id = playerIds.green
        , state =
            { position = ( 107.5, 99.5 )
            , direction = Angle (pi / 2)
            , holeStatus =
                makeInitialHoleStatus (config speed).kurves InitNoHoles
            }
        }


spawnedKurves : Speed -> List Kurve
spawnedKurves speed =
    [ green speed ]


expectedOutcome : Tick -> RoundOutcome
expectedOutcome expectedEndTick =
    { tickThatShouldEndIt = expectedEndTick
    , howItShouldEnd =
        { aliveAtTheEnd = []
        , deadAtTheEnd =
            [ { id = playerIds.green
              , theDrawingPositionItNeverMadeItTo = { x = 557, y = 99 }
              }
            ]
        }
    , effectsItShouldProduce = DoNotCare
    }
