module TestScenarios.CrashingWhileBecomingUnholy exposing (config, expectedOutcome, spawnedKurves)

import Color
import Config exposing (Config)
import Effect exposing (Effect(..))
import TestScenarioHelpers exposing (EffectsExpectation(..), RoundOutcome, defaultConfigWithHardcodedHoles, makeZombieKurve, playerIds, tickNumber)
import Types.Angle exposing (Angle(..))
import Types.Distance exposing (Distance(..))
import Types.Kurve exposing (HoleStatus(..), Kurve)


config : Config
config =
    defaultConfigWithHardcodedHoles (Distance 100) (Distance 3)


green : Kurve
green =
    makeZombieKurve
        { color = Color.green
        , id = playerIds.green
        , state =
            { position = ( 546, 100 )
            , direction = Angle (pi / 2)
            , holeStatus = Unholy 2
            }
        }


spawnedKurves : List Kurve
spawnedKurves =
    [ green ]


expectedOutcome : RoundOutcome
expectedOutcome =
    { tickThatShouldEndIt = tickNumber 11
    , howItShouldEnd =
        { aliveAtTheEnd = []
        , deadAtTheEnd =
            [ { id = playerIds.green
              , theDrawingPositionItNeverMadeItTo = { leftEdge = 557, topEdge = 100 }
              }
            ]
        }
    , effectsItShouldProduce =
        ExpectEffects
            [ -- Spawning:
              DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Color.green, { leftEdge = 546, topEdge = 100 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Color.green, { leftEdge = 546, topEdge = 100 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Color.green, { leftEdge = 546, topEdge = 100 } ) ]
                }

            -- Draw spawn position permanently:
            , DrawSomething
                { bodyDrawing = [ ( Color.green, { leftEdge = 546, topEdge = 100 } ) ]
                , headDrawing = []
                }

            -- Start moving:
            , DrawSomething
                { bodyDrawing = [ ( Color.green, { leftEdge = 547, topEdge = 100 } ) ]
                , headDrawing = [ ( Color.green, { leftEdge = 547, topEdge = 100 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Color.green, { leftEdge = 548, topEdge = 100 } ) ]
                , headDrawing = [ ( Color.green, { leftEdge = 548, topEdge = 100 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Color.green, { leftEdge = 549, topEdge = 100 } ) ]
                , headDrawing = [ ( Color.green, { leftEdge = 549, topEdge = 100 } ) ]
                }

            -- Start of hole:
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Color.green, { leftEdge = 550, topEdge = 100 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Color.green, { leftEdge = 551, topEdge = 100 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Color.green, { leftEdge = 552, topEdge = 100 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Color.green, { leftEdge = 553, topEdge = 100 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Color.green, { leftEdge = 554, topEdge = 100 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Color.green, { leftEdge = 555, topEdge = 100 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Color.green, { leftEdge = 556, topEdge = 100 } ) ]
                }

            -- Draw death position permanently:
            , DrawSomething
                { bodyDrawing = [ ( Color.green, { leftEdge = 556, topEdge = 100 } ) ]
                , headDrawing = []
                }
            ]
    }
