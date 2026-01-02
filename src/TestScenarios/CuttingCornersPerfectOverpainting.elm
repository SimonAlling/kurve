module TestScenarios.CuttingCornersPerfectOverpainting exposing (config, expectedOutcome, spawnedKurves)

import Colors
import Config exposing (Config)
import Effect exposing (Effect(..))
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
            { position = ( 29.5, 29.5 )
            , direction = Angle (pi / 4)
            , holeStatus = Unholy 60000
            }
        }


yellow : Kurve
yellow =
    makeZombieKurve
        { color = Colors.yellow
        , id = playerIds.yellow
        , state =
            { position = ( 37.5, 37.5 )
            , direction = Angle (5 * pi / 4)
            , holeStatus = Unholy 60000
            }
        }


orange : Kurve
orange =
    makeZombieKurve
        { color = Colors.orange
        , id = playerIds.orange
        , state =
            { position = ( 20.5, 24.5 )
            , direction = Angle (pi / 2)
            , holeStatus = Unholy 60000
            }
        }


green : Kurve
green =
    makeZombieKurve
        { color = Colors.green
        , id = playerIds.green
        , state =
            { position = ( 18.5, 47.5 )
            , direction = Angle (3 * pi / 4)
            , holeStatus = Unholy 60000
            }
        }


spawnedKurves : List Kurve
spawnedKurves =
    [ red, yellow, orange, green ]


expectedOutcome : RoundOutcome
expectedOutcome =
    { tickThatShouldEndIt = tickNumber 29
    , howItShouldEnd =
        { aliveAtTheEnd = [ { id = playerIds.orange } ]
        , deadAtTheEnd =
            [ { id = playerIds.green
              , theDrawingPositionItNeverMadeItTo = { leftEdge = 39, topEdge = 26 }
              }
            , { id = playerIds.yellow
              , theDrawingPositionItNeverMadeItTo = { leftEdge = 33, topEdge = 33 }
              }
            , { id = playerIds.red
              , theDrawingPositionItNeverMadeItTo = { leftEdge = 32, topEdge = 32 }
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
                , headDrawing = [ ( Colors.red, { leftEdge = 29, topEdge = 29 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.red, { leftEdge = 29, topEdge = 29 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.red, { leftEdge = 29, topEdge = 29 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.red, { leftEdge = 29, topEdge = 29 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.yellow, { leftEdge = 37, topEdge = 37 } ), ( Colors.red, { leftEdge = 29, topEdge = 29 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.red, { leftEdge = 29, topEdge = 29 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.yellow, { leftEdge = 37, topEdge = 37 } ), ( Colors.red, { leftEdge = 29, topEdge = 29 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.red, { leftEdge = 29, topEdge = 29 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.yellow, { leftEdge = 37, topEdge = 37 } ), ( Colors.red, { leftEdge = 29, topEdge = 29 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.yellow, { leftEdge = 37, topEdge = 37 } ), ( Colors.red, { leftEdge = 29, topEdge = 29 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.orange, { leftEdge = 20, topEdge = 24 } ), ( Colors.yellow, { leftEdge = 37, topEdge = 37 } ), ( Colors.red, { leftEdge = 29, topEdge = 29 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.yellow, { leftEdge = 37, topEdge = 37 } ), ( Colors.red, { leftEdge = 29, topEdge = 29 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.orange, { leftEdge = 20, topEdge = 24 } ), ( Colors.yellow, { leftEdge = 37, topEdge = 37 } ), ( Colors.red, { leftEdge = 29, topEdge = 29 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.yellow, { leftEdge = 37, topEdge = 37 } ), ( Colors.red, { leftEdge = 29, topEdge = 29 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.orange, { leftEdge = 20, topEdge = 24 } ), ( Colors.yellow, { leftEdge = 37, topEdge = 37 } ), ( Colors.red, { leftEdge = 29, topEdge = 29 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.orange, { leftEdge = 20, topEdge = 24 } ), ( Colors.yellow, { leftEdge = 37, topEdge = 37 } ), ( Colors.red, { leftEdge = 29, topEdge = 29 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { leftEdge = 18, topEdge = 47 } ), ( Colors.orange, { leftEdge = 20, topEdge = 24 } ), ( Colors.yellow, { leftEdge = 37, topEdge = 37 } ), ( Colors.red, { leftEdge = 29, topEdge = 29 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.orange, { leftEdge = 20, topEdge = 24 } ), ( Colors.yellow, { leftEdge = 37, topEdge = 37 } ), ( Colors.red, { leftEdge = 29, topEdge = 29 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { leftEdge = 18, topEdge = 47 } ), ( Colors.orange, { leftEdge = 20, topEdge = 24 } ), ( Colors.yellow, { leftEdge = 37, topEdge = 37 } ), ( Colors.red, { leftEdge = 29, topEdge = 29 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.orange, { leftEdge = 20, topEdge = 24 } ), ( Colors.yellow, { leftEdge = 37, topEdge = 37 } ), ( Colors.red, { leftEdge = 29, topEdge = 29 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.green, { leftEdge = 18, topEdge = 47 } ), ( Colors.orange, { leftEdge = 20, topEdge = 24 } ), ( Colors.yellow, { leftEdge = 37, topEdge = 37 } ), ( Colors.red, { leftEdge = 29, topEdge = 29 } ) ]
                }

            -- Spawns are drawn permanently:
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { leftEdge = 18, topEdge = 47 } ), ( Colors.orange, { leftEdge = 20, topEdge = 24 } ), ( Colors.yellow, { leftEdge = 37, topEdge = 37 } ), ( Colors.red, { leftEdge = 29, topEdge = 29 } ) ]
                , headDrawing = []
                }

            -- The Kurves start moving:
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { leftEdge = 19, topEdge = 46 } ), ( Colors.orange, { leftEdge = 21, topEdge = 24 } ), ( Colors.yellow, { leftEdge = 36, topEdge = 36 } ), ( Colors.red, { leftEdge = 30, topEdge = 30 } ) ]
                , headDrawing = [ ( Colors.red, { leftEdge = 30, topEdge = 30 } ), ( Colors.yellow, { leftEdge = 36, topEdge = 36 } ), ( Colors.orange, { leftEdge = 21, topEdge = 24 } ), ( Colors.green, { leftEdge = 19, topEdge = 46 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.orange, { leftEdge = 22, topEdge = 24 } ) ]
                , headDrawing = [ ( Colors.red, { leftEdge = 30, topEdge = 30 } ), ( Colors.yellow, { leftEdge = 36, topEdge = 36 } ), ( Colors.orange, { leftEdge = 22, topEdge = 24 } ), ( Colors.green, { leftEdge = 19, topEdge = 46 } ) ]
                }

            -- Red's last position is drawn:
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { leftEdge = 20, topEdge = 45 } ), ( Colors.orange, { leftEdge = 23, topEdge = 24 } ), ( Colors.yellow, { leftEdge = 35, topEdge = 35 } ), ( Colors.red, { leftEdge = 31, topEdge = 31 } ) ]
                , headDrawing = [ ( Colors.red, { leftEdge = 31, topEdge = 31 } ), ( Colors.yellow, { leftEdge = 35, topEdge = 35 } ), ( Colors.orange, { leftEdge = 23, topEdge = 24 } ), ( Colors.green, { leftEdge = 20, topEdge = 45 } ) ]
                }

            -- Yellow's last position is drawn:
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { leftEdge = 21, topEdge = 44 } ), ( Colors.orange, { leftEdge = 24, topEdge = 24 } ), ( Colors.yellow, { leftEdge = 34, topEdge = 34 } ) ]
                , headDrawing = [ ( Colors.yellow, { leftEdge = 34, topEdge = 34 } ), ( Colors.orange, { leftEdge = 24, topEdge = 24 } ), ( Colors.green, { leftEdge = 21, topEdge = 44 } ) ]
                }

            -- Only Orange and Green left:
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { leftEdge = 22, topEdge = 43 } ), ( Colors.orange, { leftEdge = 25, topEdge = 24 } ) ]
                , headDrawing = [ ( Colors.orange, { leftEdge = 25, topEdge = 24 } ), ( Colors.green, { leftEdge = 22, topEdge = 43 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.orange, { leftEdge = 26, topEdge = 24 } ) ]
                , headDrawing = [ ( Colors.orange, { leftEdge = 26, topEdge = 24 } ), ( Colors.green, { leftEdge = 22, topEdge = 43 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { leftEdge = 23, topEdge = 42 } ), ( Colors.orange, { leftEdge = 27, topEdge = 24 } ) ]
                , headDrawing = [ ( Colors.orange, { leftEdge = 27, topEdge = 24 } ), ( Colors.green, { leftEdge = 23, topEdge = 42 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { leftEdge = 24, topEdge = 41 } ), ( Colors.orange, { leftEdge = 28, topEdge = 24 } ) ]
                , headDrawing = [ ( Colors.orange, { leftEdge = 28, topEdge = 24 } ), ( Colors.green, { leftEdge = 24, topEdge = 41 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.orange, { leftEdge = 29, topEdge = 24 } ) ]
                , headDrawing = [ ( Colors.orange, { leftEdge = 29, topEdge = 24 } ), ( Colors.green, { leftEdge = 24, topEdge = 41 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { leftEdge = 25, topEdge = 40 } ), ( Colors.orange, { leftEdge = 30, topEdge = 24 } ) ]
                , headDrawing = [ ( Colors.orange, { leftEdge = 30, topEdge = 24 } ), ( Colors.green, { leftEdge = 25, topEdge = 40 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { leftEdge = 26, topEdge = 39 } ), ( Colors.orange, { leftEdge = 31, topEdge = 24 } ) ]
                , headDrawing = [ ( Colors.orange, { leftEdge = 31, topEdge = 24 } ), ( Colors.green, { leftEdge = 26, topEdge = 39 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.orange, { leftEdge = 32, topEdge = 24 } ) ]
                , headDrawing = [ ( Colors.orange, { leftEdge = 32, topEdge = 24 } ), ( Colors.green, { leftEdge = 26, topEdge = 39 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { leftEdge = 27, topEdge = 38 } ), ( Colors.orange, { leftEdge = 33, topEdge = 24 } ) ]
                , headDrawing = [ ( Colors.orange, { leftEdge = 33, topEdge = 24 } ), ( Colors.green, { leftEdge = 27, topEdge = 38 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { leftEdge = 28, topEdge = 37 } ), ( Colors.orange, { leftEdge = 34, topEdge = 24 } ) ]
                , headDrawing = [ ( Colors.orange, { leftEdge = 34, topEdge = 24 } ), ( Colors.green, { leftEdge = 28, topEdge = 37 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { leftEdge = 29, topEdge = 36 } ), ( Colors.orange, { leftEdge = 35, topEdge = 24 } ) ]
                , headDrawing = [ ( Colors.orange, { leftEdge = 35, topEdge = 24 } ), ( Colors.green, { leftEdge = 29, topEdge = 36 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.orange, { leftEdge = 36, topEdge = 24 } ) ]
                , headDrawing = [ ( Colors.orange, { leftEdge = 36, topEdge = 24 } ), ( Colors.green, { leftEdge = 29, topEdge = 36 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { leftEdge = 30, topEdge = 35 } ), ( Colors.orange, { leftEdge = 37, topEdge = 24 } ) ]
                , headDrawing = [ ( Colors.orange, { leftEdge = 37, topEdge = 24 } ), ( Colors.green, { leftEdge = 30, topEdge = 35 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { leftEdge = 31, topEdge = 34 } ), ( Colors.orange, { leftEdge = 38, topEdge = 24 } ) ]
                , headDrawing = [ ( Colors.orange, { leftEdge = 38, topEdge = 24 } ), ( Colors.green, { leftEdge = 31, topEdge = 34 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.orange, { leftEdge = 39, topEdge = 24 } ) ]
                , headDrawing = [ ( Colors.orange, { leftEdge = 39, topEdge = 24 } ), ( Colors.green, { leftEdge = 31, topEdge = 34 } ) ]
                }

            -- Green starts painting over Red and Yellow:
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { leftEdge = 32, topEdge = 33 } ), ( Colors.orange, { leftEdge = 40, topEdge = 24 } ) ]
                , headDrawing = [ ( Colors.orange, { leftEdge = 40, topEdge = 24 } ), ( Colors.green, { leftEdge = 32, topEdge = 33 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { leftEdge = 33, topEdge = 32 } ), ( Colors.orange, { leftEdge = 41, topEdge = 24 } ) ]
                , headDrawing = [ ( Colors.orange, { leftEdge = 41, topEdge = 24 } ), ( Colors.green, { leftEdge = 33, topEdge = 32 } ) ]
                }

            -- Green stops painting over Red and Yellow:
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { leftEdge = 34, topEdge = 31 } ), ( Colors.orange, { leftEdge = 42, topEdge = 24 } ) ]
                , headDrawing = [ ( Colors.orange, { leftEdge = 42, topEdge = 24 } ), ( Colors.green, { leftEdge = 34, topEdge = 31 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.orange, { leftEdge = 43, topEdge = 24 } ) ]
                , headDrawing = [ ( Colors.orange, { leftEdge = 43, topEdge = 24 } ), ( Colors.green, { leftEdge = 34, topEdge = 31 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { leftEdge = 35, topEdge = 30 } ), ( Colors.orange, { leftEdge = 44, topEdge = 24 } ) ]
                , headDrawing = [ ( Colors.orange, { leftEdge = 44, topEdge = 24 } ), ( Colors.green, { leftEdge = 35, topEdge = 30 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { leftEdge = 36, topEdge = 29 } ), ( Colors.orange, { leftEdge = 45, topEdge = 24 } ) ]
                , headDrawing = [ ( Colors.orange, { leftEdge = 45, topEdge = 24 } ), ( Colors.green, { leftEdge = 36, topEdge = 29 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.orange, { leftEdge = 46, topEdge = 24 } ) ]
                , headDrawing = [ ( Colors.orange, { leftEdge = 46, topEdge = 24 } ), ( Colors.green, { leftEdge = 36, topEdge = 29 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { leftEdge = 37, topEdge = 28 } ), ( Colors.orange, { leftEdge = 47, topEdge = 24 } ) ]
                , headDrawing = [ ( Colors.orange, { leftEdge = 47, topEdge = 24 } ), ( Colors.green, { leftEdge = 37, topEdge = 28 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { leftEdge = 38, topEdge = 27 } ), ( Colors.orange, { leftEdge = 48, topEdge = 24 } ) ]
                , headDrawing = [ ( Colors.orange, { leftEdge = 48, topEdge = 24 } ), ( Colors.green, { leftEdge = 38, topEdge = 27 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.orange, { leftEdge = 49, topEdge = 24 } ) ]
                , headDrawing = [ ( Colors.orange, { leftEdge = 49, topEdge = 24 } ) ]
                }
            ]
    }
