module Config exposing (Config, HoleConfig, PlayerConfig, config)

import Color exposing (Color)
import Input exposing (Button(..))
import Types.Angle exposing (Angle(..))
import Types.Distance exposing (Distance(..))
import Types.Radius exposing (Radius(..))
import Types.Speed exposing (Speed(..))
import Types.Thickness exposing (Thickness(..))
import Types.Tickrate exposing (Tickrate(..))


type alias Config =
    { kurves : KurveConfig
    , spawn : SpawnConfig
    , world : WorldConfig
    , players : List PlayerConfig
    , holes : HoleConfig
    }


config : Config
config =
    { kurves =
        { tickrate = tickrate
        , turningRadius = turningRadius
        , speed = speed
        , thickness = thickness
        }
    , spawn =
        { margin = spawnMargin
        , desiredMinimumDistanceTurningRadiusFactor = desiredMinimumSpawnDistanceTurningRadiusFactor
        , protectionAudacity = spawnProtectionAudacity
        , flickerTicksPerSecond = spawnFlickerTicksPerSecond
        , numberOfFlickerTicks = numberOfSpawnFlickerTicks
        }
    , world =
        { width = worldWidth
        , height = worldHeight
        }
    , players = players
    , holes = holes
    }


type alias KurveConfig =
    { tickrate : Tickrate
    , speed : Speed
    , turningRadius : Radius
    , thickness : Thickness
    }


type alias SpawnConfig =
    { margin : Float
    , desiredMinimumDistanceTurningRadiusFactor : Float
    , protectionAudacity : Float
    , flickerTicksPerSecond : Float
    , numberOfFlickerTicks : Int
    }


type alias WorldConfig =
    { width : Int
    , height : Int
    }


type alias PlayerConfig =
    { color : Color
    , controls : ( List Button, List Button )
    }


type alias HoleConfig =
    { minInterval : Distance
    , maxInterval : Distance
    , minSize : Distance
    , maxSize : Distance
    }


tickrate : Tickrate
tickrate =
    Tickrate 60


turningRadius : Radius
turningRadius =
    Radius 28.5


speed : Speed
speed =
    Speed 60


thickness : Thickness
thickness =
    Thickness 3


{-| The minimum distance from the wall that a player can spawn.
-}
spawnMargin : Float
spawnMargin =
    100


desiredMinimumSpawnDistanceTurningRadiusFactor : Float
desiredMinimumSpawnDistanceTurningRadiusFactor =
    1


{-| Closer to 1 ⇔ less risk of spawn kills but higher risk of no solution
-}
spawnProtectionAudacity : Float
spawnProtectionAudacity =
    0.25


{-| At each tick, the spawning player is toggled between visible and invisible.
-}
spawnFlickerTicksPerSecond : Float
spawnFlickerTicksPerSecond =
    20


numberOfSpawnFlickerTicks : Int
numberOfSpawnFlickerTicks =
    5


worldWidth : Int
worldWidth =
    559


worldHeight : Int
worldHeight =
    480


players : List PlayerConfig
players =
    let
        rgb =
            Color.rgb255
    in
    [ { color = rgb 255 40 0
      , controls = ( [ Key "Digit1" ], [ Key "KeyQ" ] )
      }
    , { color = rgb 195 195 0
      , controls = ( [ Key "ControlLeft", Key "KeyZ" ], [ Key "AltLeft", Key "KeyX" ] )
      }
    , { color = rgb 255 121 0
      , controls = ( [ Key "KeyM" ], [ Key "Comma" ] )
      }
    , { color = rgb 0 203 0
      , controls = ( [ Key "ArrowLeft" ], [ Key "ArrowDown" ] )
      }
    , { color = rgb 223 81 182
      , controls = ( [ Key "NumpadDivide", Key "End", Key "PageDown" ], [ Key "NumpadMultiply", Key "PageUp" ] )
      }
    , { color = rgb 0 162 203
      , controls = ( [ Mouse 0 ], [ Mouse 2 ] )
      }
    ]


holes : HoleConfig
holes =
    { minInterval = Distance 90
    , maxInterval = Distance 300
    , minSize = Distance 5
    , maxSize = Distance 9
    }
