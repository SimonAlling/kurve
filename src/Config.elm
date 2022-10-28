module Config exposing (..)

import Color exposing (Color)
import Set exposing (Set)
import Types.Angle exposing (Angle(..))
import Types.Distance exposing (Distance(..))
import Types.Radius exposing (Radius(..))
import Types.Speed exposing (Speed(..))
import Types.Thickness exposing (Thickness(..))
import Types.Tickrate exposing (Tickrate(..))


type alias PlayerConfig =
    { color : Color
    , controls : ( Set String, Set String )
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
      , controls = ( Set.fromList [ "Digit1" ], Set.fromList [ "KeyQ" ] )
      }
    , { color = rgb 0 203 0
      , controls = ( Set.fromList [ "ArrowLeft" ], Set.fromList [ "ArrowDown" ] )
      }
    , { color = rgb 255 121 0
      , controls = ( Set.fromList [ "KeyM" ], Set.fromList [ "Comma" ] )
      }
    , { color = rgb 195 195 0
      , controls = ( Set.fromList [ "KeyZ" ], Set.fromList [ "KeyX" ] )
      }
    ]


holes : HoleConfig
holes =
    { minInterval = Distance 90
    , maxInterval = Distance 300
    , minSize = Distance 5
    , maxSize = Distance 9
    }
