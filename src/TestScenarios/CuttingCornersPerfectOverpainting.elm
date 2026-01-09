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
              , theDrawingPositionItNeverMadeItTo = { x = 39, y = 26 }
              }
            , { id = playerIds.yellow
              , theDrawingPositionItNeverMadeItTo = { x = 33, y = 33 }
              }
            , { id = playerIds.red
              , theDrawingPositionItNeverMadeItTo = { x = 32, y = 32 }
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
                , headDrawing = [ ( Colors.red, { x = 29, y = 29 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.red, { x = 29, y = 29 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = []
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.red, { x = 29, y = 29 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.red, { x = 29, y = 29 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.red, { x = 29, y = 29 } ), ( Colors.yellow, { x = 37, y = 37 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.red, { x = 29, y = 29 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.red, { x = 29, y = 29 } ), ( Colors.yellow, { x = 37, y = 37 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.red, { x = 29, y = 29 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.red, { x = 29, y = 29 } ), ( Colors.yellow, { x = 37, y = 37 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.red, { x = 29, y = 29 } ), ( Colors.yellow, { x = 37, y = 37 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.red, { x = 29, y = 29 } ), ( Colors.yellow, { x = 37, y = 37 } ), ( Colors.orange, { x = 20, y = 24 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.red, { x = 29, y = 29 } ), ( Colors.yellow, { x = 37, y = 37 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.red, { x = 29, y = 29 } ), ( Colors.yellow, { x = 37, y = 37 } ), ( Colors.orange, { x = 20, y = 24 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.red, { x = 29, y = 29 } ), ( Colors.yellow, { x = 37, y = 37 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.red, { x = 29, y = 29 } ), ( Colors.yellow, { x = 37, y = 37 } ), ( Colors.orange, { x = 20, y = 24 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.red, { x = 29, y = 29 } ), ( Colors.yellow, { x = 37, y = 37 } ), ( Colors.orange, { x = 20, y = 24 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.red, { x = 29, y = 29 } ), ( Colors.yellow, { x = 37, y = 37 } ), ( Colors.orange, { x = 20, y = 24 } ), ( Colors.green, { x = 18, y = 47 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.red, { x = 29, y = 29 } ), ( Colors.yellow, { x = 37, y = 37 } ), ( Colors.orange, { x = 20, y = 24 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.red, { x = 29, y = 29 } ), ( Colors.yellow, { x = 37, y = 37 } ), ( Colors.orange, { x = 20, y = 24 } ), ( Colors.green, { x = 18, y = 47 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.red, { x = 29, y = 29 } ), ( Colors.yellow, { x = 37, y = 37 } ), ( Colors.orange, { x = 20, y = 24 } ) ]
                }
            , DrawSomething
                { bodyDrawing = []
                , headDrawing = [ ( Colors.red, { x = 29, y = 29 } ), ( Colors.yellow, { x = 37, y = 37 } ), ( Colors.orange, { x = 20, y = 24 } ), ( Colors.green, { x = 18, y = 47 } ) ]
                }

            -- Spawns are drawn permanently:
            , DrawSomething
                { bodyDrawing = [ ( Colors.red, { x = 29, y = 29 } ), ( Colors.yellow, { x = 37, y = 37 } ), ( Colors.orange, { x = 20, y = 24 } ), ( Colors.green, { x = 18, y = 47 } ) ]
                , headDrawing = []
                }

            -- The Kurves start moving:
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 19, y = 46 } ), ( Colors.orange, { x = 21, y = 24 } ), ( Colors.yellow, { x = 36, y = 36 } ), ( Colors.red, { x = 30, y = 30 } ) ]
                , headDrawing = [ ( Colors.red, { x = 30, y = 30 } ), ( Colors.yellow, { x = 36, y = 36 } ), ( Colors.orange, { x = 21, y = 24 } ), ( Colors.green, { x = 19, y = 46 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.orange, { x = 22, y = 24 } ) ]
                , headDrawing = [ ( Colors.red, { x = 30, y = 30 } ), ( Colors.yellow, { x = 36, y = 36 } ), ( Colors.orange, { x = 22, y = 24 } ), ( Colors.green, { x = 19, y = 46 } ) ]
                }

            -- Red's last position is drawn:
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 20, y = 45 } ), ( Colors.orange, { x = 23, y = 24 } ), ( Colors.yellow, { x = 35, y = 35 } ), ( Colors.red, { x = 31, y = 31 } ) ]
                , headDrawing = [ ( Colors.red, { x = 31, y = 31 } ), ( Colors.yellow, { x = 35, y = 35 } ), ( Colors.orange, { x = 23, y = 24 } ), ( Colors.green, { x = 20, y = 45 } ) ]
                }

            -- Yellow's last position is drawn:
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 21, y = 44 } ), ( Colors.orange, { x = 24, y = 24 } ), ( Colors.yellow, { x = 34, y = 34 } ) ]
                , headDrawing = [ ( Colors.yellow, { x = 34, y = 34 } ), ( Colors.orange, { x = 24, y = 24 } ), ( Colors.green, { x = 21, y = 44 } ) ]
                }

            -- Only Orange and Green left:
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 22, y = 43 } ), ( Colors.orange, { x = 25, y = 24 } ) ]
                , headDrawing = [ ( Colors.orange, { x = 25, y = 24 } ), ( Colors.green, { x = 22, y = 43 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.orange, { x = 26, y = 24 } ) ]
                , headDrawing = [ ( Colors.orange, { x = 26, y = 24 } ), ( Colors.green, { x = 22, y = 43 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 23, y = 42 } ), ( Colors.orange, { x = 27, y = 24 } ) ]
                , headDrawing = [ ( Colors.orange, { x = 27, y = 24 } ), ( Colors.green, { x = 23, y = 42 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 24, y = 41 } ), ( Colors.orange, { x = 28, y = 24 } ) ]
                , headDrawing = [ ( Colors.orange, { x = 28, y = 24 } ), ( Colors.green, { x = 24, y = 41 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.orange, { x = 29, y = 24 } ) ]
                , headDrawing = [ ( Colors.orange, { x = 29, y = 24 } ), ( Colors.green, { x = 24, y = 41 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 25, y = 40 } ), ( Colors.orange, { x = 30, y = 24 } ) ]
                , headDrawing = [ ( Colors.orange, { x = 30, y = 24 } ), ( Colors.green, { x = 25, y = 40 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 26, y = 39 } ), ( Colors.orange, { x = 31, y = 24 } ) ]
                , headDrawing = [ ( Colors.orange, { x = 31, y = 24 } ), ( Colors.green, { x = 26, y = 39 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.orange, { x = 32, y = 24 } ) ]
                , headDrawing = [ ( Colors.orange, { x = 32, y = 24 } ), ( Colors.green, { x = 26, y = 39 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 27, y = 38 } ), ( Colors.orange, { x = 33, y = 24 } ) ]
                , headDrawing = [ ( Colors.orange, { x = 33, y = 24 } ), ( Colors.green, { x = 27, y = 38 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 28, y = 37 } ), ( Colors.orange, { x = 34, y = 24 } ) ]
                , headDrawing = [ ( Colors.orange, { x = 34, y = 24 } ), ( Colors.green, { x = 28, y = 37 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 29, y = 36 } ), ( Colors.orange, { x = 35, y = 24 } ) ]
                , headDrawing = [ ( Colors.orange, { x = 35, y = 24 } ), ( Colors.green, { x = 29, y = 36 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.orange, { x = 36, y = 24 } ) ]
                , headDrawing = [ ( Colors.orange, { x = 36, y = 24 } ), ( Colors.green, { x = 29, y = 36 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 30, y = 35 } ), ( Colors.orange, { x = 37, y = 24 } ) ]
                , headDrawing = [ ( Colors.orange, { x = 37, y = 24 } ), ( Colors.green, { x = 30, y = 35 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 31, y = 34 } ), ( Colors.orange, { x = 38, y = 24 } ) ]
                , headDrawing = [ ( Colors.orange, { x = 38, y = 24 } ), ( Colors.green, { x = 31, y = 34 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.orange, { x = 39, y = 24 } ) ]
                , headDrawing = [ ( Colors.orange, { x = 39, y = 24 } ), ( Colors.green, { x = 31, y = 34 } ) ]
                }

            -- Green starts painting over Red and Yellow:
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 32, y = 33 } ), ( Colors.orange, { x = 40, y = 24 } ) ]
                , headDrawing = [ ( Colors.orange, { x = 40, y = 24 } ), ( Colors.green, { x = 32, y = 33 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 33, y = 32 } ), ( Colors.orange, { x = 41, y = 24 } ) ]
                , headDrawing = [ ( Colors.orange, { x = 41, y = 24 } ), ( Colors.green, { x = 33, y = 32 } ) ]
                }

            -- Green stops painting over Red and Yellow:
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 34, y = 31 } ), ( Colors.orange, { x = 42, y = 24 } ) ]
                , headDrawing = [ ( Colors.orange, { x = 42, y = 24 } ), ( Colors.green, { x = 34, y = 31 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.orange, { x = 43, y = 24 } ) ]
                , headDrawing = [ ( Colors.orange, { x = 43, y = 24 } ), ( Colors.green, { x = 34, y = 31 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 35, y = 30 } ), ( Colors.orange, { x = 44, y = 24 } ) ]
                , headDrawing = [ ( Colors.orange, { x = 44, y = 24 } ), ( Colors.green, { x = 35, y = 30 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 36, y = 29 } ), ( Colors.orange, { x = 45, y = 24 } ) ]
                , headDrawing = [ ( Colors.orange, { x = 45, y = 24 } ), ( Colors.green, { x = 36, y = 29 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.orange, { x = 46, y = 24 } ) ]
                , headDrawing = [ ( Colors.orange, { x = 46, y = 24 } ), ( Colors.green, { x = 36, y = 29 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 37, y = 28 } ), ( Colors.orange, { x = 47, y = 24 } ) ]
                , headDrawing = [ ( Colors.orange, { x = 47, y = 24 } ), ( Colors.green, { x = 37, y = 28 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.green, { x = 38, y = 27 } ), ( Colors.orange, { x = 48, y = 24 } ) ]
                , headDrawing = [ ( Colors.orange, { x = 48, y = 24 } ), ( Colors.green, { x = 38, y = 27 } ) ]
                }
            , DrawSomething
                { bodyDrawing = [ ( Colors.orange, { x = 49, y = 24 } ) ]
                , headDrawing = [ ( Colors.orange, { x = 49, y = 24 } ) ]
                }
            ]
    }
