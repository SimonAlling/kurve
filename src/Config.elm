module Config exposing (Config, HoleConfig, KurveConfig, PlayerConfig, SpawnConfig, WorldConfig, config)

import Color exposing (Color)
import Input exposing (Button(..))
import Types.Angle exposing (Angle(..))
import Types.Distance exposing (Distance(..))
import Types.Radius exposing (Radius(..))
import Types.Speed exposing (Speed(..))
import Types.Thickness exposing (Thickness(..))
import Types.Tickrate exposing (Tickrate(..))


config : Config
config =
    { kurves =
        { tickrate = Tickrate 60
        , turningRadius = Radius 28.5
        , speed = Speed 60
        , thickness = Thickness 3
        , holes =
            { minInterval = Distance 90
            , maxInterval = Distance 300
            , minSize = Distance 5
            , maxSize = Distance 9
            }
        }
    , spawn =
        { margin = 100 -- The minimum distance from the wall that a player can spawn.
        , desiredMinimumDistanceTurningRadiusFactor = 1
        , protectionAudacity = 0.25 -- Closer to 1 ⇔ less risk of spawn kills but higher risk of no solution
        , flickerTicksPerSecond = 20 -- At each tick, the spawning player is toggled between visible and invisible.
        , numberOfFlickerTicks = 5
        }
    , world =
        { width = 559
        , height = 480
        }
    , players = players
    }


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


type alias Config =
    { kurves : KurveConfig
    , spawn : SpawnConfig
    , world : WorldConfig
    , players : List PlayerConfig
    }


type alias KurveConfig =
    { tickrate : Tickrate
    , speed : Speed
    , turningRadius : Radius
    , thickness : Thickness
    , holes : HoleConfig
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
